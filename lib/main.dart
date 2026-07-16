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
import 'features/onboarding/account_onboarding_page.dart';

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
        final setup = state.matchedLocation.startsWith('/setup');
        final accountOnly =
            setup ||
            state.matchedLocation.startsWith('/consent') ||
            state.matchedLocation.startsWith('/companion') ||
            state.matchedLocation.startsWith('/care') ||
            state.matchedLocation.startsWith('/contacts') ||
            state.matchedLocation.startsWith('/voice');
        if (inApp && !widget.auth.canUseProtectedFeatures) {
          return '/welcome';
        }
        if (accountOnly && !widget.auth.canUseProtectedFeatures) {
          return '/welcome';
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
        GoRoute(
          path: '/setup',
          builder: (_, _) => const AccountOnboardingPage(),
        ),
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
            scaffoldMessengerKey: scaffoldMessengerKey,
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
            const HappifyMascot(size: 148, semanticLabel: 'Happify mascot'),
            const SizedBox(height: 24),
            Text('Happify', style: Theme.of(context).textTheme.displayLarge),
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

class _IntroSlide {
  const _IntroSlide(this.title, this.description, this.asset);

  final String title;
  final String description;
  final String asset;
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;
  static const slides = <_IntroSlide>[
    _IntroSlide(
      'Understand your emotions',
      'Check in gently and see mood patterns without judgment.',
      'assets/illustrations/onboarding-companion.png',
    ),
    _IntroSlide(
      'Reflect in your own space',
      'Journal privately and connect with a moderated anonymous community.',
      'assets/illustrations/onboarding-reflect.png',
    ),
    _IntroSlide(
      'Support when you need it',
      'Talk with AI Companion, use grounding tools, or reach professional care.',
      'assets/illustrations/onboarding-support.png',
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
                        Expanded(
                          flex: 6,
                          child: Semantics(
                            image: true,
                            label: '${slide.title} illustration',
                            child: Image.asset(
                              slide.asset,
                              fit: BoxFit.contain,
                              excludeFromSemantics: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.description,
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
      backgroundColor: Colors.white,
      body: ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Image.asset(
                'assets/illustrations/auth-welcome.png',
                height: 250,
                fit: BoxFit.contain,
                semanticLabel: 'Happify mascot with a journal and phone',
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'A friend who is here to listen.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Sign in to securely save your moods, journal entries, and insights.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 28),
            GoogleAuthButton(
              label: 'Continue with Google',
              loading: services?.auth.busy == true,
              onPressed: () async {
                final success = await services?.auth.signInWithGoogle(
                  registerMode: false,
                );
                if (success == true && context.mounted) context.go('/app');
                if (success == false && context.mounted) {
                  showErrorToast(
                    context,
                    'Google sign-in failed',
                    message: services?.auth.error,
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            HappifyButton(
              label: 'Continue with email',
              icon: PhosphorIcons.envelopeSimple(PhosphorIconsStyle.bold),
              background: Colors.white,
              foreground: HappifyColors.blueDark,
              onPressed: () => context.go('/login'),
            ),
            if (firebaseError != null) const SizedBox(height: 12),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('Create an account'),
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
  bool _showPassword = false;

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
    if (!success) {
      showErrorToast(
        context,
        widget.mode == AuthMode.login
            ? 'Sign in failed'
            : 'Account not created',
        message: auth.error,
      );
      return;
    }
    showSuccessToast(
      context,
      widget.mode == AuthMode.login ? 'Welcome back' : 'Account created',
    );
    context.go(widget.mode == AuthMode.register ? '/setup' : '/app');
  }

  Future<void> _submitGoogle() async {
    final auth = AppServices.of(context).auth;
    final registering = widget.mode == AuthMode.register;
    final success = await auth.signInWithGoogle(registerMode: registering);
    if (!mounted) return;
    if (!success) {
      showErrorToast(context, 'Google sign-in failed', message: auth.error);
      return;
    }
    showSuccessToast(context, registering ? 'Account created' : 'Welcome back');
    context.go(registering ? '/setup' : '/app');
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppServices.of(context).auth;
    final registering = widget.mode == AuthMode.register;
    return Scaffold(
      backgroundColor: Colors.white,
      body: ResponsivePage(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => context.go('/welcome'),
                icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold)),
                tooltip: 'Back',
              ),
              Center(
                child: Image.asset(
                  'assets/illustrations/auth-welcome.png',
                  height: 185,
                  fit: BoxFit.contain,
                  semanticLabel: 'Happify mascot with a journal and phone',
                ),
              ),
              const SizedBox(height: 18),
              Text(
                registering ? 'Create account' : 'Sign in',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                registering
                    ? 'Set up your safe space, then personalize how Happify supports you.'
                    : 'Welcome back. Sign in to continue your private wellbeing journey.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 22),
              GoogleAuthButton(
                label: registering
                    ? 'Sign up with Google'
                    : 'Sign in with Google',
                loading: auth.busy,
                onPressed: _submitGoogle,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or continue with email',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: HappifyColors.inkSoft,
                        ),
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
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
                obscureText: !_showPassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => auth.busy ? null : _submit(),
                autofillHints: registering
                    ? const [AutofillHints.newPassword]
                    : const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    tooltip: _showPassword ? 'Hide password' : 'Show password',
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword
                          ? PhosphorIcons.eyeSlash(PhosphorIconsStyle.bold)
                          : PhosphorIcons.eye(PhosphorIconsStyle.bold),
                    ),
                  ),
                ),
                validator: (value) => value != null && value.length >= 6
                    ? null
                    : 'Use at least 6 characters.',
              ),
              const SizedBox(height: 22),
              HappifyButton(
                label: auth.busy
                    ? 'Loading...'
                    : registering
                    ? 'Create account'
                    : 'Sign in',
                icon: PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                onPressed: auth.busy ? null : _submit,
              ),
              if (!registering)
                TextButton(
                  onPressed: () => context.go('/forgot'),
                  child: const Text('Forgot password?'),
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
              icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold)),
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
            const SizedBox(height: 24),
            HappifyButton(
              label: auth.busy ? 'Sending...' : 'Send reset link',
              icon: PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.bold),
              onPressed: auth.busy
                  ? null
                  : () async {
                      final success = await auth.resetPassword(_email.text);
                      if (!context.mounted) return;
                      if (!success) {
                        showErrorToast(
                          context,
                          'Reset link not sent',
                          message: auth.error,
                        );
                        return;
                      }
                      showSuccessToast(
                        context,
                        'Reset link sent',
                        message: 'Check your email to reset your password.',
                      );
                      context.go('/login');
                    },
            ),
          ],
        ),
      ),
    );
  }
}
