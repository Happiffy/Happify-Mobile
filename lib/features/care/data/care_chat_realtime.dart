import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/app_services.dart';

enum CareChatRealtimeStatus {
  disconnected,
  connecting,
  authenticating,
  subscribing,
  connected,
  reconnecting,
  closed,
}

class CareChatRealtimeEvent {
  const CareChatRealtimeEvent({required this.type, required this.data});

  factory CareChatRealtimeEvent.fromJson(Object? value) {
    final decoded = switch (value) {
      String text => jsonDecode(text),
      List<int> bytes => jsonDecode(utf8.decode(bytes)),
      _ => value,
    };
    if (decoded is! Map) {
      throw const FormatException('Realtime event must be an object.');
    }
    final data = decoded.map((key, item) => MapEntry('$key', item));
    final type = data['type']?.toString();
    if (type == null || type.isEmpty) {
      throw const FormatException('Realtime event type is required.');
    }
    return CareChatRealtimeEvent(type: type, data: data);
  }

  final String type;
  final Map<String, dynamic> data;
}

abstract interface class CareChatRealtime {
  Stream<CareChatRealtimeEvent> get events;
  Stream<CareChatRealtimeStatus> get statuses;
  String? get authenticatedUserId;

  Future<void> connect();
  Future<void> sendTyping(bool isTyping);
  Future<void> markRead(String messageId);
  Future<void> close();
}

class CareChatRealtimeFactory {
  const CareChatRealtimeFactory({
    required this.tokenProvider,
    this.baseUrl = backendUrl,
  });

  final String baseUrl;
  final Future<String?> Function() tokenProvider;

  CareChatRealtime create(String sessionId) => IoCareChatRealtime(
    baseUrl: baseUrl,
    sessionId: sessionId,
    tokenProvider: tokenProvider,
  );
}

class IoCareChatRealtime implements CareChatRealtime {
  IoCareChatRealtime({
    required String baseUrl,
    required this.sessionId,
    required Future<String?> Function() tokenProvider,
    Duration connectionTimeout = const Duration(seconds: 10),
  }) : _uri = _webSocketUri(baseUrl),
       _tokenProvider = tokenProvider,
       _connectionTimeout = connectionTimeout;

  final Uri _uri;
  final String sessionId;
  final Future<String?> Function() _tokenProvider;
  final Duration _connectionTimeout;
  final _events = StreamController<CareChatRealtimeEvent>.broadcast();
  final _statuses = StreamController<CareChatRealtimeStatus>.broadcast();

  WebSocket? _socket;
  StreamSubscription<dynamic>? _socketSubscription;
  Timer? _reconnectTimer;
  Future<void>? _connecting;
  Completer<void>? _authentication;
  Completer<void>? _channelSubscription;
  CareChatRealtimeStatus _status = CareChatRealtimeStatus.disconnected;
  int _reconnectAttempt = 0;
  bool _closed = false;

  @override
  Stream<CareChatRealtimeEvent> get events => _events.stream;

  @override
  Stream<CareChatRealtimeStatus> get statuses => _statuses.stream;

  @override
  String? authenticatedUserId;

  String get _channel => 'care-chat:$sessionId';

  @override
  Future<void> connect() async {
    if (_closed) throw StateError('Realtime client is closed.');
    if (_status == CareChatRealtimeStatus.connected) return;
    final activeConnection = _connecting;
    if (activeConnection != null) return activeConnection;
    final connection = _open();
    _connecting = connection;
    try {
      await connection;
    } finally {
      if (identical(_connecting, connection)) _connecting = null;
    }
  }

  Future<void> _open() async {
    _emitStatus(
      _reconnectAttempt == 0
          ? CareChatRealtimeStatus.connecting
          : CareChatRealtimeStatus.reconnecting,
    );
    WebSocket? socket;
    try {
      final token = await _tokenProvider();
      if (token == null || token.isEmpty) {
        throw StateError('Authentication token is unavailable.');
      }
      socket = await WebSocket.connect(
        _uri.toString(),
      ).timeout(_connectionTimeout);
      if (_closed) {
        await socket.close();
        return;
      }
      _socket = socket;
      _socketSubscription = socket.listen(
        (data) => _handleData(socket!, data),
        onError: (Object error, StackTrace stackTrace) {
          _handleDisconnect(socket!, error);
        },
        onDone: () {
          _handleDisconnect(socket!, StateError('WebSocket closed.'));
        },
        cancelOnError: true,
      );

      _emitStatus(CareChatRealtimeStatus.authenticating);
      final authentication = Completer<void>();
      _authentication = authentication;
      socket.add(jsonEncode({'type': 'auth', 'token': token}));
      try {
        await authentication.future.timeout(_connectionTimeout);
      } finally {
        if (identical(_authentication, authentication)) {
          _authentication = null;
        }
      }

      _emitStatus(CareChatRealtimeStatus.subscribing);
      final channelSubscription = Completer<void>();
      _channelSubscription = channelSubscription;
      socket.add(jsonEncode({'type': 'subscribe', 'channel': _channel}));
      try {
        await channelSubscription.future.timeout(_connectionTimeout);
      } finally {
        if (identical(_channelSubscription, channelSubscription)) {
          _channelSubscription = null;
        }
      }

      _reconnectAttempt = 0;
      _emitStatus(CareChatRealtimeStatus.connected);
    } catch (error) {
      if (socket != null) await _discardSocket(socket);
      if (!_closed) {
        _emitStatus(CareChatRealtimeStatus.disconnected);
        _scheduleReconnect();
      }
      rethrow;
    }
  }

  void _handleData(WebSocket source, Object? raw) {
    if (_closed || !identical(_socket, source)) return;
    try {
      final event = CareChatRealtimeEvent.fromJson(raw);
      if (event.type == 'authenticated') {
        authenticatedUserId = event.data['userId']?.toString();
        final authentication = _authentication;
        if (authentication != null && !authentication.isCompleted) {
          authentication.complete();
        }
        return;
      }
      if (event.type == 'subscribed' &&
          event.data['channel']?.toString() == _channel) {
        final channelSubscription = _channelSubscription;
        if (channelSubscription != null && !channelSubscription.isCompleted) {
          channelSubscription.complete();
        }
        return;
      }
      if (event.type == 'error') {
        final error = StateError(
          event.data['message']?.toString() ?? 'Realtime request failed.',
        );
        final authentication = _authentication;
        final channelSubscription = _channelSubscription;
        if (authentication != null && !authentication.isCompleted) {
          authentication.completeError(error);
          return;
        }
        if (channelSubscription != null && !channelSubscription.isCompleted) {
          channelSubscription.completeError(error);
          return;
        }
      }
      if (!_events.isClosed) _events.add(event);
    } on FormatException {
      return;
    }
  }

  void _handleDisconnect(WebSocket source, Object error) {
    if (_closed || !identical(_socket, source)) return;
    _socket = null;
    _socketSubscription = null;
    final authentication = _authentication;
    final channelSubscription = _channelSubscription;
    if (authentication != null && !authentication.isCompleted) {
      authentication.completeError(error);
    }
    if (channelSubscription != null && !channelSubscription.isCompleted) {
      channelSubscription.completeError(error);
    }
    _emitStatus(CareChatRealtimeStatus.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_closed || _reconnectTimer?.isActive == true) return;
    final seconds = switch (_reconnectAttempt) {
      0 => 1,
      1 => 2,
      2 => 4,
      3 => 8,
      4 => 16,
      _ => 30,
    };
    _reconnectAttempt += 1;
    _emitStatus(CareChatRealtimeStatus.reconnecting);
    _reconnectTimer = Timer(Duration(seconds: seconds), () {
      _reconnectTimer = null;
      unawaited(connect().catchError((_) {}));
    });
  }

  @override
  Future<void> sendTyping(bool isTyping) => _send({
    'type': 'care-chat:typing',
    'sessionId': sessionId,
    'isTyping': isTyping,
  });

  @override
  Future<void> markRead(String messageId) => _send({
    'type': 'care-chat:read',
    'sessionId': sessionId,
    'messageId': messageId,
  }, requireConnection: true);

  Future<void> _send(
    Map<String, dynamic> payload, {
    bool requireConnection = false,
  }) async {
    final socket = _socket;
    if (_closed ||
        socket == null ||
        _status != CareChatRealtimeStatus.connected) {
      if (requireConnection) {
        throw StateError('Realtime client is not connected.');
      }
      return;
    }
    socket.add(jsonEncode(payload));
  }

  Future<void> _discardSocket(WebSocket socket) async {
    if (identical(_socket, socket)) _socket = null;
    final subscription = _socketSubscription;
    _socketSubscription = null;
    await subscription?.cancel();
    try {
      await socket.close();
    } catch (_) {}
  }

  void _emitStatus(CareChatRealtimeStatus status) {
    if (_status == status || _statuses.isClosed) return;
    _status = status;
    _statuses.add(status);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    final wasConnected = _status == CareChatRealtimeStatus.connected;
    _emitStatus(CareChatRealtimeStatus.closed);
    final closeError = StateError('Realtime client is closed.');
    final authentication = _authentication;
    final channelSubscription = _channelSubscription;
    if (authentication != null && !authentication.isCompleted) {
      authentication.completeError(closeError);
    }
    if (channelSubscription != null && !channelSubscription.isCompleted) {
      channelSubscription.completeError(closeError);
    }
    final socket = _socket;
    if (socket != null && wasConnected) {
      socket.add(jsonEncode({'type': 'unsubscribe', 'channel': _channel}));
    }
    if (socket != null) await _discardSocket(socket);
    await _events.close();
    await _statuses.close();
  }

  static Uri _webSocketUri(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    final scheme = switch (uri.scheme) {
      'http' => 'ws',
      'https' => 'wss',
      'ws' || 'wss' => uri.scheme,
      _ => throw ArgumentError.value(baseUrl, 'baseUrl'),
    };
    final basePath = uri.path.replaceFirst(RegExp(r'/$'), '');
    return uri.replace(scheme: scheme, path: '$basePath/ws');
  }
}
