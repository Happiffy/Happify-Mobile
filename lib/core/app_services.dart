import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

const backendUrl = String.fromEnvironment(
  'BE_API_URL',
  defaultValue: 'https://happify-be-production.up.railway.app',
);

const googleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue:
      '402141330645-p76mroh1dil5rv759kme7obupescq8id.apps.googleusercontent.com',
);

class AppFailure implements Exception {
  const AppFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

Map<String, dynamic> objectMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, item) => MapEntry('$key', item));
  return <String, dynamic>{};
}

List<Map<String, dynamic>> objectList(Object? value) {
  if (value is! List) return <Map<String, dynamic>>[];
  return value.map(objectMap).toList();
}

class ApiClient {
  ApiClient(this._tokenProvider)
    : dio = Dio(
        BaseOptions(
          baseUrl: backendUrl.replaceAll(RegExp(r'/$'), ''),
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 45),
          headers: const {'Accept': 'application/json'},
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenProvider();
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (error, handler) {
          final body = objectMap(error.response?.data);
          final backendMessage = body['message']?.toString();
          final message = switch (backendMessage) {
            'UNAUTHENTICATED' => 'Your session expired. Please sign in again.',
            'FORBIDDEN' => 'You do not have permission for this action.',
            'NOT_FOUND' => 'The requested item could not be found.',
            'AI_CONSENT_REQUIRED' => 'Voice processing consent is required.',
            'HEATMAP_CONSENT_REQUIRED' =>
              'Heatmap contribution consent is required.',
            'VOICE_AUDIO_NOT_FOUND' =>
              'This protected audio response has expired.',
            'PAIRING_INVALID' =>
              'The serial number or claim code is invalid or expired.',
            'FIRMWARE_INCOMPATIBLE' =>
              'This firmware is not compatible with your Companion.',
            'OTA_ALREADY_ACTIVE' =>
              'A firmware update is already in progress for this Companion.',
            'ACCOUNT_NOT_REGISTERED' =>
              'This Firebase account is not registered with Happify.',
            null || '' =>
              error.type == DioExceptionType.connectionError
                  ? 'Happify is offline. Check your connection and try again.'
                  : 'Something went wrong. Please try again.',
            _ => 'Something went wrong. Please try again.',
          };
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: AppFailure(message),
            ),
          );
        },
      ),
    );
  }

  final Future<String?> Function() _tokenProvider;
  final Dio dio;

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
  }) async {
    try {
      final response = await dio.request<Object?>(
        path,
        data: data,
        queryParameters: query,
        options: Options(
          method: method,
          headers: headers,
          responseType: responseType,
        ),
      );
      if (responseType == ResponseType.bytes) {
        return {'bytes': response.data};
      }
      final envelope = objectMap(response.data);
      if (envelope['status'] == 'error') {
        throw AppFailure(
          envelope['message']?.toString() ?? 'The request failed.',
        );
      }
      return objectMap(envelope['data']);
    } on DioException catch (error) {
      if (error.error is AppFailure) throw error.error! as AppFailure;
      throw AppFailure('The request could not be completed.');
    }
  }
}

class AuthController extends ChangeNotifier {
  AuthController({required this.firebaseReady, required this.firebaseError}) {
    api = ApiClient(freshToken);
  }

  final bool firebaseReady;
  final String? firebaseError;
  late final ApiClient api;
  StreamSubscription<User?>? _subscription;
  Map<String, dynamic>? backendUser;
  bool restoring = true;
  bool busy = false;
  String? error;
  bool consentReviewed = false;
  bool googleReady = false;

  bool get signedIn =>
      firebaseReady && FirebaseAuth.instance.currentUser != null;
  bool get canUseProtectedFeatures => signedIn && backendUser != null;
  User? get firebaseUser =>
      firebaseReady ? FirebaseAuth.instance.currentUser : null;

  Future<void> initialize() async {
    if (!firebaseReady) {
      restoring = false;
      notifyListeners();
      return;
    }
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: googleServerClientId,
      );
      googleReady = true;
    } on GoogleSignInException catch (exception) {
      googleReady = false;
      error = _googleMessage(exception);
    } catch (_) {
      googleReady = false;
      error = 'Google sign-in is not available on this device.';
    }
    _subscription = FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) async {
      if (user == null) {
        backendUser = null;
        consentReviewed = false;

        restoring = false;
        notifyListeners();
        return;
      }
      if (busy) return;
      await restoreSession();
    });
    if (FirebaseAuth.instance.currentUser == null) {
      restoring = false;
      notifyListeners();
    }
  }

  Future<String?> freshToken() async {
    if (!firebaseReady) return null;
    return FirebaseAuth.instance.currentUser?.getIdToken(true);
  }

  Future<void> restoreSession() async {
    if (!signedIn) {
      restoring = false;
      notifyListeners();
      return;
    }
    try {
      final token = await freshToken();
      final data = await api.request(
        'POST',
        '/auth/verify',
        data: {'idToken': token, 'mode': 'login'},
      );
      backendUser = objectMap(data['user']);
      consentReviewed = false;
      error = null;
    } catch (exception) {
      backendUser = null;
      error = _message(exception);
    } finally {
      restoring = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    if (!firebaseReady) {
      error = firebaseError ?? 'Firebase is not configured for this build.';
      notifyListeners();
      return false;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final token = await freshToken();
      final data = await api.request(
        'POST',
        '/auth/verify',
        data: {'idToken': token, 'mode': 'login'},
      );
      backendUser = objectMap(data['user']);
      consentReviewed = false;
      return true;
    } catch (exception) {
      backendUser = null;

      error = _authMessage(exception);
      if (FirebaseAuth.instance.currentUser != null) {
        try {
          await FirebaseAuth.instance.signOut();
        } catch (_) {}
      }
      return false;
    } finally {
      busy = false;
      restoring = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle({required bool registerMode}) async {
    if (!firebaseReady || !googleReady) {
      error =
          firebaseError ?? 'Google sign-in is not configured for this build.';
      notifyListeners();
      return false;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final googleAuth = account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AppFailure('Google did not return an identity token.');
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final firebaseCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final token = await firebaseCredential.user?.getIdToken(true);
      final data = await api.request(
        'POST',
        '/auth/verify',
        data: {
          'idToken': token,
          'displayName': account.displayName,
          'mode': registerMode ? 'register' : 'login',
        },
      );
      backendUser = objectMap(data['user']);
      consentReviewed = false;
      return true;
    } catch (exception) {
      backendUser = null;
      error = _authMessage(exception);
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      return false;
    } finally {
      busy = false;
      restoring = false;
      notifyListeners();
    }
  }

  Future<bool> register(
    String displayName,
    String email,
    String password,
  ) async {
    if (!firebaseReady) {
      error = firebaseError ?? 'Firebase is not configured for this build.';
      notifyListeners();
      return false;
    }
    busy = true;
    error = null;
    notifyListeners();
    UserCredential? credential;
    try {
      credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final name = displayName.trim();
      if (name.isNotEmpty) await credential.user?.updateDisplayName(name);
      final token = await credential.user?.getIdToken(true);
      final data = await api.request(
        'POST',
        '/auth/verify',
        data: {'idToken': token, 'displayName': name, 'mode': 'register'},
      );
      backendUser = objectMap(data['user']);
      consentReviewed = false;
      return true;
    } catch (exception) {
      if (credential?.user != null && backendUser == null) {
        try {
          await credential!.user!.delete();
        } catch (_) {}
      }
      error = _authMessage(exception);
      return false;
    } finally {
      busy = false;
      restoring = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    if (!firebaseReady) {
      error = firebaseError ?? 'Firebase is not configured for this build.';
      notifyListeners();
      return false;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      return true;
    } catch (exception) {
      error = _authMessage(exception);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void markConsentReviewed() {
    consentReviewed = true;
    notifyListeners();
  }

  Future<void> logout({Future<void> Function()? unregisterPush}) async {
    if (unregisterPush != null) {
      try {
        await unregisterPush();
      } catch (_) {}
    }
    if (firebaseReady) await FirebaseAuth.instance.signOut();
    backendUser = null;
    consentReviewed = false;
    notifyListeners();
  }

  String _authMessage(Object exception) {
    if (exception is GoogleSignInException) {
      return _googleMessage(exception);
    }
    if (exception is FirebaseAuthException) {
      return switch (exception.code) {
        'invalid-email' => 'Enter a valid email address.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' => 'The email or password is incorrect.',
        'email-already-in-use' => 'An account already uses this email.',
        'weak-password' =>
          'Use a stronger password with at least 6 characters.',
        'network-request-failed' =>
          'Check your internet connection and try again.',
        'too-many-requests' => 'Please wait a moment before trying again.',
        _ => 'Authentication could not be completed. Please try again.',
      };
    }
    if (exception is AppFailure) {
      return switch (exception.message) {
        'This Firebase account is not registered with Happify.' =>
          'No Happify account was found. Create an account first.',
        _ when exception.message.contains('Cannot reach') =>
          'Happify is temporarily unavailable. Please try again shortly.',
        _ => 'Authentication could not be completed. Please try again.',
      };
    }
    return 'Authentication could not be completed. Please try again.';
  }

  String _googleMessage(
    GoogleSignInException exception,
  ) => switch (exception.code) {
    GoogleSignInExceptionCode.canceled => 'Google sign-in was cancelled.',
    GoogleSignInExceptionCode.interrupted =>
      'Google sign-in was interrupted. Please try again.',
    GoogleSignInExceptionCode.clientConfigurationError ||
    GoogleSignInExceptionCode.providerConfigurationError =>
      'Google sign-in is not configured for this app build. Add the Android debug SHA-1 to Firebase.',
    GoogleSignInExceptionCode.uiUnavailable =>
      'Google sign-in cannot open on this device right now.',
    _ => 'Google sign-in could not be completed. Please try again.',
  };

  String _message(Object exception) =>
      exception is AppFailure ? exception.message : 'The operation failed.';

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class AppSettings extends ChangeNotifier {
  final SharedPreferencesAsync _storage = SharedPreferencesAsync();
  bool onboardingCompleted = false;
  bool highContrast = false;
  bool reducedMotion = false;
  bool audioMode = false;
  bool screenReaderOptimized = false;
  String textScale = 'STANDARD';
  bool loaded = false;

  double get scaleFactor => switch (textScale) {
    'SMALL' => .9,
    'LARGE' => 1.3,
    'EXTRA_LARGE' => 2,
    _ => 1,
  };

  Future<void> load() async {
    onboardingCompleted =
        await _storage.getBool('onboardingCompleted') ?? false;
    highContrast = await _storage.getBool('highContrast') ?? false;
    reducedMotion = await _storage.getBool('reducedMotion') ?? false;
    audioMode = await _storage.getBool('audioMode') ?? false;
    screenReaderOptimized =
        await _storage.getBool('screenReaderOptimized') ?? false;
    textScale = await _storage.getString('textScale') ?? 'STANDARD';
    loaded = true;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    onboardingCompleted = true;
    await _storage.setBool('onboardingCompleted', true);
    notifyListeners();
  }

  Future<void> mergeBackend(Map<String, dynamic>? preference) async {
    if (preference == null || preference.isEmpty) return;
    final accessibility = objectMap(preference['accessibility']);
    highContrast =
        accessibility['highContrast'] == true ||
        preference['highContrast'] == true;
    reducedMotion =
        accessibility['reducedMotion'] == true ||
        preference['reducedMotion'] == true;
    screenReaderOptimized =
        accessibility['screenReaderOptimized'] == true ||
        preference['screenReaderOptimized'] == true;
    textScale =
        accessibility['textScale']?.toString() ??
        preference['textScale']?.toString() ??
        'STANDARD';
    final modes = (preference['accessibilityMode'] as List? ?? const [])
        .map((item) => '$item')
        .toList();
    audioMode = modes.contains('AUDIO_MODE');
    await _persist();
    notifyListeners();
  }

  Future<void> update({
    bool? highContrast,
    bool? reducedMotion,
    bool? audioMode,
    bool? screenReaderOptimized,
    String? textScale,
  }) async {
    this.highContrast = highContrast ?? this.highContrast;
    this.reducedMotion = reducedMotion ?? this.reducedMotion;
    this.audioMode = audioMode ?? this.audioMode;
    this.screenReaderOptimized =
        screenReaderOptimized ?? this.screenReaderOptimized;
    this.textScale = textScale ?? this.textScale;
    await _persist();
    notifyListeners();
  }

  Future<void> sync(ApiClient api, Map<String, dynamic>? existing) async {
    final current = existing ?? <String, dynamic>{};
    final modes = (current['accessibilityMode'] as List? ?? const [])
        .map((item) => '$item')
        .where((item) => item != 'AUDIO_MODE')
        .toList();
    if (audioMode) modes.add('AUDIO_MODE');
    await api.request(
      'PUT',
      '/preferences',
      data: {
        'primaryGoal':
            current['primaryGoal']?.toString() ?? 'General wellbeing',
        'triggers': current['triggers'] as List? ?? const [],
        'supportTone': current['supportTone']?.toString() ?? 'Gentle',
        'highRiskAction':
            current['highRiskAction']?.toString() ?? 'Show emergency support',
        'accessibilityMode': modes,
        'accessibility': {
          'textScale': textScale,
          'highContrast': highContrast,
          'reducedMotion': reducedMotion,
          'screenReaderOptimized': screenReaderOptimized,
        },
        'consentToAi': current['consentToAi'] == true,
      },
    );
  }

  Future<void> _persist() async {
    await Future.wait([
      _storage.setBool('highContrast', highContrast),
      _storage.setBool('reducedMotion', reducedMotion),
      _storage.setBool('audioMode', audioMode),
      _storage.setBool('screenReaderOptimized', screenReaderOptimized),
      _storage.setString('textScale', textScale),
    ]);
  }
}

class SpeechService extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer player = AudioPlayer();
  bool speaking = false;
  bool playing = false;

  Future<void> speak(String text) async {
    if (speaking) {
      await stop();
      return;
    }
    speaking = true;
    notifyListeners();
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(.45);
      await _tts.awaitSpeakCompletion(true);
      await _tts.speak(text);
    } finally {
      speaking = false;
      notifyListeners();
    }
  }

  Future<void> playProtected(ApiClient api, String path) async {
    await player.stop();
    final result = await api.request(
      'GET',
      path,
      responseType: ResponseType.bytes,
    );
    final bytes = result['bytes'];
    if (bytes is! List<int>) throw const AppFailure('Audio was unavailable.');
    playing = true;
    notifyListeners();
    try {
      await player.play(BytesSource(Uint8List.fromList(bytes)));
      await player.onPlayerComplete.first;
    } finally {
      playing = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    await player.stop();
    speaking = false;
    playing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _tts.stop();
    player.dispose();
    super.dispose();
  }
}

class PushService {
  PushService(this.auth, this.onTarget);
  final AuthController auth;
  final void Function(String target, Map<String, dynamic> data) onTarget;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Future<void> initialize() async {
    if (!auth.firebaseReady) {
      throw const AppFailure('Firebase push is not configured for this build.');
    }
    _subscriptions.add(
      FirebaseMessaging.onMessage.listen(
        (message) => onTarget(
          message.data['target']?.toString() ?? 'home',
          message.data,
        ),
      ),
    );
    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => onTarget(
          message.data['target']?.toString() ?? 'home',
          message.data,
        ),
      ),
    );
    _subscriptions.add(
      FirebaseMessaging.instance.onTokenRefresh.listen(registerToken),
    );
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      onTarget(initial.data['target']?.toString() ?? 'home', initial.data);
    }
    await syncIfAuthorized();
  }

  Future<AuthorizationStatus> requestPermission() async {
    if (!auth.firebaseReady) {
      throw const AppFailure('Firebase push is not configured for this build.');
    }
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await syncIfAuthorized();
    return settings.authorizationStatus;
  }

  Future<void> syncIfAuthorized() async {
    if (!auth.canUseProtectedFeatures) return;
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return;
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await registerToken(token);
  }

  Future<void> registerToken(String token) async {
    if (!auth.canUseProtectedFeatures) return;
    final platform = kIsWeb
        ? 'WEB'
        : defaultTargetPlatform == TargetPlatform.iOS
        ? 'IOS'
        : 'ANDROID';
    await auth.api.request(
      'PUT',
      '/notifications/tokens',
      data: {'token': token, 'platform': platform},
    );
  }

  Future<void> unregister() async {
    if (!auth.firebaseReady) return;
    final token = await FirebaseMessaging.instance.getToken();
    try {
      if (token != null && auth.canUseProtectedFeatures) {
        await auth.api.request(
          'DELETE',
          '/notifications/tokens',
          data: {'token': token},
        );
      }
    } finally {
      await FirebaseMessaging.instance.deleteToken();
    }
  }

  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
  }
}

class AppServices extends InheritedNotifier<AuthController> {
  const AppServices({
    required this.auth,
    required this.settings,
    required this.speech,
    required super.child,
    super.key,
  }) : super(notifier: auth);

  final AuthController auth;
  final AppSettings settings;
  final SpeechService speech;

  static AppServices of(BuildContext context) {
    final value = maybeOf(context);
    assert(value != null, 'AppServices is missing');
    return value!;
  }

  static AppServices? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppServices>();
}

Future<(bool, String?)> initializeFirebase() async {
  try {
    await Firebase.initializeApp();
    return (true, null);
  } catch (error) {
    return (
      false,
      'Firebase is not configured. Add the official Android/iOS Firebase files to enable authentication and push notifications.',
    );
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

String failureMessage(Object error) =>
    error is AppFailure ? error.message : 'Something went wrong. Please retry.';
