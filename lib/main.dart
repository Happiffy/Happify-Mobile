import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'core/app_services.dart';
import 'core/di/app_scope.dart';
import 'core/theme/happify_colors.dart';
import 'core/theme/happify_theme.dart';
import 'core/widgets/common_widgets.dart';
import 'core/widgets/happify_button.dart';
import 'core/widgets/quokka_badge.dart';
import 'core/widgets/responsive_page.dart';
import 'features/pages.dart';
import 'features/care/bloc_care_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebase = await initializeFirebase();
  if (firebase.$1) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  final settings = AppSettings();
  await settings.load();
  final auth = AuthController(
    firebaseReady: firebase.$1,
    firebaseError: firebase.$2,
  );
  await auth.initialize();
  runApp(HappifyApp(auth: auth, settings: settings));
}

class HappifyApp extends StatefulWidget {
  const HappifyApp({required this.auth, required this.settings, super.key});
  final AuthController auth;
  final AppSettings settings;

  @override
  State<HappifyApp> createState() => _HappifyAppState();
}

class _HappifyAppState extends State<HappifyApp> {
  late final SpeechService _speech;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _speech = SpeechService();
    _router = GoRouter(
      initialLocation: '/',
      refreshListenable: widget.auth,
      redirect: (context, state) {
        if (widget.auth.restoring) {
          return state.matchedLocation == '/' ? null : '/';
        }
        final inApp = state.matchedLocation.startsWith('/app');
        if (inApp &&
            widget.auth.canUseProtectedFeatures &&
            !widget.auth.consentReviewed) {
          return '/consent';
        }
        final accountOnly =
            state.matchedLocation.startsWith('/consent') ||
            state.matchedLocation.startsWith('/companion') ||
            state.matchedLocation.startsWith('/care') ||
            state.matchedLocation.startsWith('/contacts') ||
            state.matchedLocation.startsWith('/voice');
        if (inApp &&
            !widget.auth.canUseProtectedFeatures &&
            !widget.auth.guest) {
          return '/welcome';
        }
        if (accountOnly && !widget.auth.canUseProtectedFeatures) {
          return widget.auth.guest ? '/app' : '/welcome';
        }
        if (widget.auth.canUseProtectedFeatures &&
            (state.matchedLocation == '/login' ||
                state.matchedLocation == '/register' ||
                state.matchedLocation == '/welcome')) {
          return '/app';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SplashPage()),
        GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingPage()),
        GoRoute(path: '/welcome', builder: (_, _) => const WelcomePage()),
        GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
        GoRoute(path: '/register', builder: (_, _) => const RegisterPage()),
        GoRoute(path: '/forgot', builder: (_, _) => const ForgotPasswordPage()),
        GoRoute(
          path: '/consent',
          builder: (context, _) => BlocConsentPage(
            onContinue: () {
              AppServices.of(context).auth.markConsentReviewed();
              context.go('/app');
            },

            onSignOut: () async {
              await AppServices.of(context).auth.logout();
              if (context.mounted) context.go('/welcome');
            },
          ),
        ),
        GoRoute(
          path: '/app',
          builder: (_, state) =>
              HappifyShell(target: state.uri.queryParameters['target']),
        ),
        GoRoute(
          path: '/companion',
          builder: (_, _) => const BlocCompanionPage(),
        ),
        GoRoute(
          path: '/care',
          builder: (_, state) =>
              BlocCarePage(sessionId: state.uri.queryParameters['sessionId']),
        ),
        GoRoute(
          path: '/contacts',
          builder: (_, _) => const EmergencyContactsPage(),
        ),
        GoRoute(path: '/voice', builder: (_, _) => const VoicePage()),
      ],
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _speech.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (context, _) => AppServices(
        auth: widget.auth,
        settings: widget.settings,
        speech: _speech,
        child: AppScope(
          auth: widget.auth,
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Happify',
            theme: buildHappifyTheme(
              highContrast: widget.settings.highContrast,
            ),
            builder: (context, child) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  textScaler: TextScaler.linear(
                    (media.textScaler.scale(1) * widget.settings.scaleFactor)
                        .clamp(.8, 2),
                  ),
                  disableAnimations: widget.settings.reducedMotion,
                  accessibleNavigation: widget.settings.screenReaderOptimized,
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  Future<void> _route() async {
    final auth = AppServices.of(context).auth;
    while (auth.restoring && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted) return;
    if (auth.canUseProtectedFeatures) {
      context.go('/app');
    } else if (AppServices.of(context).settings.onboardingCompleted) {
      context.go('/welcome');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const QuokkaBadge(size: 148),
            const SizedBox(height: 24),
            Text('Happify', style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 10),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;
  static const slides = [
    (
      'Understand your emotions without judgment',
      'Track moods and notice patterns gently.',
      Color(0xFFF7E0C7),
    ),
    (
      'You are not alone',
      'Journal privately and find anonymous community support.',
      Color(0xFFE6DCF0),
    ),
    (
      'Grow at your own pace',
      'Use guided mindfulness and personalized insights.',
      Color(0xFFDCE7D6),
    ),
    (
      'Choose what matters today',
      'Start with calm, connection, sleep, or understanding your emotions. You can change this anytime.',
      Color(0xFFFBE4DE),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    await AppServices.of(context).settings.completeOnboarding();
                    if (context.mounted) context.go('/welcome');
                  },
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: slides.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) {
                    final slide = slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 210,
                          height: 210,
                          decoration: BoxDecoration(
                            color: slide.$3,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(child: QuokkaBadge(size: 170)),
                        ),
                        const SizedBox(height: 42),
                        Text(
                          slide.$1,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.$2,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  slides.length,
                  (index) => Container(
                    width: _index == index ? 26 : 8,
                    height: 8,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _index == index
                          ? HappifyColors.peachDeep
                          : HappifyColors.line,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              HappifyButton(
                label: _index == slides.length - 1 ? 'Start' : 'Next',
                icon: PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                onPressed: () async {
                  if (_index == slides.length - 1) {
                    await AppServices.of(context).settings.completeOnboarding();
                    if (context.mounted) context.go('/welcome');
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppServices.maybeOf(context);
    final firebaseError = services?.auth.firebaseReady == false
        ? services?.auth.firebaseError
        : null;
    return Scaffold(
      body: ResponsivePage(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const QuokkaBadge(size: 160),
            const SizedBox(height: 28),
            Text(
              'A friend who is here\nto listen.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 14),
            Text(
              'Sign in to securely save your moods, journal entries, and insights.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (firebaseError != null) ...[
              const SizedBox(height: 18),
              FeatureCard(
                color: const Color(0xFFFBE4DE),
                child: Text(firebaseError, textAlign: TextAlign.center),
              ),
            ],
            const SizedBox(height: 34),
            HappifyButton(
              label: 'Sign in',
              icon: PhosphorIcons.signIn(PhosphorIconsStyle.bold),
              onPressed: () => context.go('/login'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: () => context.go('/register'),
                child: const Text('Create account'),
              ),
            ),
            TextButton(
              onPressed: () {
                services?.auth.continueAsGuest();
                context.go('/app');
              },
              child: const Text('Continue as guest'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) => const AuthPage(mode: AuthMode.login);
}

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) => const AuthPage(mode: AuthMode.register);
}

enum AuthMode { login, register }

class AuthPage extends StatefulWidget {
  const AuthPage({required this.mode, super.key});
  final AuthMode mode;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = AppServices.of(context).auth;
    final success = widget.mode == AuthMode.login
        ? await auth.login(_email.text, _password.text)
        : await auth.register(_name.text, _email.text, _password.text);
    if (!mounted) return;
    if (success) {
      context.go('/app');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppServices.of(context).auth;
    final registering = widget.mode == AuthMode.register;
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.go('/welcome'),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                ),
              ),
              const Center(child: QuokkaBadge(size: 104)),
              const SizedBox(height: 22),
              Text(
                registering
                    ? 'Create your safe space.'
                    : 'It is good to have you back.',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 22),
              if (registering) ...[
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Preferred name',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your preferred name.'
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value != null && value.contains('@')
                    ? null
                    : 'Enter a valid email.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                autofillHints: registering
                    ? const [AutofillHints.newPassword]
                    : const [AutofillHints.password],
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) => value != null && value.length >= 6
                    ? null
                    : 'Use at least 6 characters.',
              ),
              if (auth.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  auth.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              HappifyButton(
                label: auth.busy
                    ? 'Please wait...'
                    : registering
                    ? 'Sign up'
                    : 'Sign in',
                icon: PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                onPressed: auth.busy ? null : _submit,
              ),
              if (!registering)
                TextButton(
                  onPressed: () => context.go('/forgot'),
                  child: const Text('Forgot your password?'),
                ),
              TextButton(
                onPressed: () =>
                    context.go(registering ? '/login' : '/register'),
                child: Text(
                  registering
                      ? 'Already have an account? Sign in'
                      : 'Create an account',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppServices.of(context).auth;
    return Scaffold(
      body: ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
            ),
            const SizedBox(height: 28),
            Text(
              'Reset password',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text('Enter your email and Firebase will send a reset link.'),
            const SizedBox(height: 24),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 12),
              Text(
                auth.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            HappifyButton(
              label: auth.busy ? 'Sending...' : 'Send reset link',
              icon: PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.bold),
              onPressed: auth.busy
                  ? null
                  : () async {
                      final success = await auth.resetPassword(_email.text);
                      if (!context.mounted) return;
                      if (success) {
                        showMessage(context, 'Password reset email sent.');
                        context.go('/login');
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
