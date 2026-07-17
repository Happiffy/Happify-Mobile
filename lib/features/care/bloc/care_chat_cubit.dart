import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_services.dart';
import '../data/care_chat_realtime.dart';
import '../data/care_repository.dart';
import 'care_chat_state.dart';

class CareChatCubit extends Cubit<CareChatState> {
  CareChatCubit({
    required this.repository,
    required this.sessionId,
    required CareChatRealtime realtime,
  }) : _realtime = realtime,
       super(const CareChatState()) {
    _eventSubscription = _realtime.events.listen(_handleRealtimeEvent);
    _statusSubscription = _realtime.statuses.listen(_handleRealtimeStatus);
  }

  final CareRepository repository;
  final String sessionId;
  final CareChatRealtime _realtime;
  final Set<String> _readMessageIds = {};
  StreamSubscription<CareChatRealtimeEvent>? _eventSubscription;
  StreamSubscription<CareChatRealtimeStatus>? _statusSubscription;
  bool _realtimeInitialized = false;

  Future<void> load() async {
    if (state.loading) return;
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final session = await repository.chat(sessionId);
      if (isClosed) return;
      emit(
        state.copyWith(
          loading: false,
          session: _mergeSession(state.session, session),
        ),
      );
      unawaited(_initializeRealtime());
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(loading: false, errorMessage: failureMessage(error)),
        );
      }
    }
  }

  Future<void> _initializeRealtime() async {
    if (_realtimeInitialized || isClosed) return;
    _realtimeInitialized = true;
    try {
      await _realtime.connect();
      await _markUnreadMessages();
    } catch (_) {}
  }

  Future<bool> sendMessage(String content, {String? imageUrl}) async {
    if (state.sending || (content.trim().isEmpty && imageUrl == null)) {
      return false;
    }
    emit(state.copyWith(sending: true, clearError: true));
    try {
      await repository.sendChat(sessionId, content.trim(), imageUrl: imageUrl);
      await load();
      if (!isClosed) emit(state.copyWith(sending: false));
      return true;
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(sending: false, errorMessage: failureMessage(error)),
        );
      }
      return false;
    }
  }

  Future<void> toggleStatus() async {
    if (state.updatingStatus) return;
    final nextStatus = state.session['status'] == 'OPEN' ? 'CLOSED' : 'OPEN';
    emit(state.copyWith(updatingStatus: true, clearError: true));
    try {
      await repository.updateChatStatus(sessionId, nextStatus);
      await load();
      if (!isClosed) emit(state.copyWith(updatingStatus: false));
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            updatingStatus: false,
            errorMessage: failureMessage(error),
          ),
        );
      }
    }
  }

  Future<void> setTyping(bool isTyping) => _realtime.sendTyping(isTyping);

  void _handleRealtimeStatus(CareChatRealtimeStatus status) {
    if (isClosed) return;
    emit(
      state.copyWith(
        realtimeStatus: status,
        clearTyping:
            status == CareChatRealtimeStatus.disconnected ||
            status == CareChatRealtimeStatus.reconnecting ||
            status == CareChatRealtimeStatus.closed,
      ),
    );
    if (status == CareChatRealtimeStatus.connected) {
      unawaited(_markUnreadMessages());
    }
  }

  void _handleRealtimeEvent(CareChatRealtimeEvent event) {
    if (isClosed) return;
    switch (event.type) {
      case 'care-chat:message':
        final message = objectMap(event.data['message']);
        if (message.isEmpty) return;
        final messages = _mergeMessages(objectList(state.session['messages']), [
          message,
        ]);
        emit(
          state.copyWith(
            session: {...state.session, 'messages': messages},
            clearTyping: true,
          ),
        );
        unawaited(_markMessageRead(message));
      case 'care-chat:session':
        final session = objectMap(event.data['session']);
        if (session.isEmpty) return;
        emit(state.copyWith(session: _mergeSession(state.session, session)));
      case 'care-chat:typing':
        _mergeTyping(event.data);
      case 'care-chat:read':
        _mergeRead(event.data);
    }
  }

  Map<String, dynamic> _mergeSession(
    Map<String, dynamic> current,
    Map<String, dynamic> incoming,
  ) {
    final incomingMessages = objectList(incoming['messages']);
    final currentMessages = objectList(current['messages']);
    return {
      ...current,
      ...incoming,
      'messages': _mergeMessages(currentMessages, incomingMessages),
    };
  }

  List<Map<String, dynamic>> _mergeMessages(
    List<Map<String, dynamic>> current,
    List<Map<String, dynamic>> incoming,
  ) {
    final merged = <Map<String, dynamic>>[];
    final indices = <String, int>{};
    for (final message in [...current, ...incoming]) {
      final id = message['id']?.toString();
      if (id == null || id.isEmpty) {
        merged.add(message);
        continue;
      }
      final index = indices[id];
      if (index == null) {
        indices[id] = merged.length;
        merged.add(message);
      } else {
        merged[index] = {...merged[index], ...message};
      }
    }
    return merged;
  }

  void _mergeTyping(Map<String, dynamic> event) {
    final userId = event['userId']?.toString();
    if (userId == null || userId == _realtime.authenticatedUserId) return;
    if (event['isTyping'] != true) {
      if (state.typingUserId == userId) emit(state.copyWith(clearTyping: true));
      return;
    }
    emit(
      state.copyWith(
        typingUserId: userId,
        typingDisplayName: _displayName(userId),
      ),
    );
  }

  void _mergeRead(Map<String, dynamic> event) {
    final messageId = event['messageId']?.toString();
    final readAt = event['readAt']?.toString();
    if (messageId == null || readAt == null) return;
    final messages = objectList(state.session['messages'])
        .map(
          (message) => message['id']?.toString() == messageId
              ? {...message, 'readAt': readAt}
              : message,
        )
        .toList();
    emit(state.copyWith(session: {...state.session, 'messages': messages}));
  }

  String _displayName(String userId) {
    for (final key in ['user', 'psychologist']) {
      final user = objectMap(state.session[key]);
      if (user['id']?.toString() == userId) {
        return user['displayName']?.toString() ?? 'Care chat participant';
      }
    }
    for (final message in objectList(state.session['messages'])) {
      final sender = objectMap(message['sender']);
      if (sender['id']?.toString() == userId) {
        return sender['displayName']?.toString() ?? 'Care chat participant';
      }
    }
    return 'Care chat participant';
  }

  Future<void> _markUnreadMessages() async {
    for (final message in objectList(state.session['messages'])) {
      await _markMessageRead(message);
    }
  }

  Future<void> _markMessageRead(Map<String, dynamic> message) async {
    final messageId = message['id']?.toString();
    final sender = objectMap(message['sender']);
    final senderId =
        message['senderId']?.toString() ?? sender['id']?.toString();
    if (messageId == null ||
        message['readAt'] != null ||
        senderId == null ||
        senderId == _realtime.authenticatedUserId ||
        !_readMessageIds.add(messageId)) {
      return;
    }
    try {
      await _realtime.markRead(messageId);
    } catch (_) {
      _readMessageIds.remove(messageId);
    }
  }

  @override
  Future<void> close() async {
    await _eventSubscription?.cancel();
    await _statusSubscription?.cancel();
    await _realtime.close();
    return super.close();
  }
}
