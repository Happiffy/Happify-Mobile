import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_services.dart';
import '../core/happify_repository.dart';
import '../core/theme/happify_colors.dart';
import '../core/widgets/common_widgets.dart';
import '../core/widgets/happify_button.dart';
import '../core/widgets/happify_emoji.dart';
import 'community/bloc_community_page.dart';
import 'home/bloc_home_page.dart';
import 'journal/bloc_journal_page.dart';
import 'mood/bloc_mood_page.dart';
import 'mood_mindfulness_pages.dart';
import 'profile/bloc_profile_page.dart';
import 'profile/data/profile_repository.dart';
import 'profile_settings_pages.dart';

class ConsentPage extends StatefulWidget {
  const ConsentPage({super.key});

  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _documents = [];
  final Map<String, bool> _accepted = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final repo = HappifyRepository(AppServices.of(context).auth.api);
      final documents = await repo.consents();
      if (!mounted) return;
      final latest = <String, Map<String, dynamic>>{};
      for (final item in documents) {
        final scope = item['scope']?.toString() ?? '';
        final current = latest[scope];
        final version = (item['version'] as num?)?.toInt() ?? 0;
        final currentVersion = (current?['version'] as num?)?.toInt() ?? -1;
        if (scope.isNotEmpty && version > currentVersion) latest[scope] = item;
      }
      setState(() {
        _documents = latest.values.toList();
        for (final document in _documents) {
          final consents = objectList(document['consents']);
          _accepted[document['scope'].toString()] = consents.any(
            (item) => item['status'] == 'ACCEPTED',
          );
        }
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = failureMessage(error);
          _loading = false;
        });
      }
    }
  }

  Future<void> _save(bool limited) async {
    setState(() => _saving = true);
    try {
      final repo = HappifyRepository(AppServices.of(context).auth.api);
      for (final document in _documents) {
        final scope = document['scope'].toString();
        await repo.updateConsent(
          scope,
          (document['version'] as num).toInt(),
          limited ? false : _accepted[scope] == true,
        );
      }
      if (mounted) context.go('/app');
    } catch (error) {
      if (mounted) showMessage(context, failureMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HappifyPage(
        title: 'Your data stays yours.',
        children: [
          Center(child: HappifyEmoji.shield(size: 72)),
          const SizedBox(height: 16),
          Text(
            'Choose which optional Happify features may process your data. You can change these choices later.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          AsyncStateView(
            loading: _loading,
            error: _error,
            isEmpty: !_loading && _documents.isEmpty,
            emptyMessage:
                'No active consent documents are available from the backend.',
            onRetry: () {
              setState(() {
                _loading = true;
                _error = null;
              });
              unawaited(_load());
            },
            child: Column(
              children: _documents.map((document) {
                final scope = document['scope'].toString();
                return FeatureCard(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      document['title']?.toString() ?? prettyEnum(scope),
                    ),
                    subtitle: Text(document['content']?.toString() ?? ''),
                    value: _accepted[scope] == true,
                    onChanged: (value) =>
                        setState(() => _accepted[scope] = value),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          HappifyButton(
            label: _saving ? 'Saving...' : 'Save and continue',
            leading: HappifyEmoji.check(size: 22),
            onPressed: _saving || _documents.isEmpty
                ? null
                : () => _save(false),
          ),
          TextButton(
            onPressed: _saving
                ? null
                : _documents.isEmpty
                ? () => context.go('/app')
                : () => _save(true),
            child: const Text('Continue with limited features'),
          ),
          TextButton(
            onPressed: _saving
                ? null
                : () async {
                    final services = AppServices.of(context);
                    await services.auth.logout();
                    if (context.mounted) context.go('/welcome');
                  },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class HappifyShell extends StatefulWidget {
  const HappifyShell({this.target, super.key});
  final String? target;

  @override
  State<HappifyShell> createState() => _HappifyShellState();
}

class _HappifyShellState extends State<HappifyShell>
    with WidgetsBindingObserver {
  int _tab = 0;
  PushService? _push;
  String? _pushError;

  final List<Widget?> _pages = List<Widget?>.filled(5, null);

  Widget _page(int index) {
    return _pages[index] ??= switch (index) {
      0 => const BlocHomePage(),
      1 => const BlocMoodPage(),
      2 => const BlocJournalPage(),
      3 => BlocCommunityPage(requestCoarseRegionKey: _requestCoarseRegionKey),
      4 => BlocProfilePage(
        settings: AppServices.of(context).settings,
        onNavigate: _handleProfileNavigation,
        onNotifications: _requestNotifications,
        onSignOut: _signOut,
      ),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tab = _targetTab(widget.target);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializePush());
  }

  int _targetTab(String? target) => switch (target) {
    'mood' => 1,
    'journal' => 2,
    'community' => 3,
    'profile' || 'care' || 'chat' => 4,
    _ => 0,
  };

  @override
  void didUpdateWidget(covariant HappifyShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      setState(() => _tab = _targetTab(widget.target));
    }
  }

  Future<void> _handleProfileNavigation(
    BlocProfileDestination destination,
    PreferenceData? preference,
  ) async {
    final preferenceMap = preference?.toMap();
    switch (destination) {
      case BlocProfileDestination.wellbeingPreferences:
        await showDialog<void>(
          context: context,
          builder: (_) => WellbeingPreferencesDialog(preference: preferenceMap),
        );
      case BlocProfileDestination.accessibility:
        await showDialog<void>(
          context: context,
          builder: (_) => AccessibilityDialog(preference: preferenceMap),
        );
      case BlocProfileDestination.consent:
        await context.push('/consent');
      case BlocProfileDestination.emergencyContacts:
        await context.push('/contacts');
      case BlocProfileDestination.professionalCare:
        await context.push('/care');
      case BlocProfileDestination.voiceCompanion:
        await context.push('/voice');
      case BlocProfileDestination.companion:
        await context.push('/companion');
    }
  }

  Future<void> _requestNotifications() async {
    final push = PushService(AppServices.of(context).auth, (_, _) {});
    try {
      final status = await push.requestPermission();
      if (!mounted) return;
      showMessage(
        context,
        status == AuthorizationStatus.authorized ||
                status == AuthorizationStatus.provisional
            ? 'Notifications are enabled.'
            : 'Notifications were not enabled. You can enable them in system settings.',
      );
    } finally {
      push.dispose();
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will be signed out on this device. You can sign in again anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final services = AppServices.of(context);
    final push = PushService(services.auth, (_, _) {});
    try {
      await services.auth.logout(unregisterPush: push.unregister);
    } finally {
      push.dispose();
    }
    if (mounted) context.go('/welcome');
  }

  Future<String?> _requestCoarseRegionKey() async {
    final repo = HappifyRepository(AppServices.of(context).auth.api);
    final documents = await repo.consents();
    final heatmapAccepted = documents
        .where((item) => item['scope'] == 'HEATMAP_CONTRIBUTION')
        .expand((item) => objectList(item['consents']))
        .any((item) => item['status'] == 'ACCEPTED');
    if (!heatmapAccepted) {
      if (mounted) {
        showMessage(context, 'Enable heatmap contribution consent first.');
        await context.push('/consent');
      }
      return null;
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) {
        final open = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Location is off'),
            content: const Text(
              'Turn on location services to contribute only a coarse regional mood.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open settings'),
              ),
            ],
          ),
        );
        if (open == true) await Geolocator.openLocationSettings();
      }
      return null;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        showMessage(
          context,
          'Location permission is disabled in system settings.',
        );
        await Geolocator.openAppSettings();
      }
      return null;
    }
    if (permission == LocationPermission.denied) return null;
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );
    final latBucket = (position.latitude * 10).floor();
    final lonBucket = (position.longitude * 10).floor();
    return 'G${latBucket < 0 ? 'S' : 'N'}${latBucket.abs()}_${lonBucket < 0 ? 'W' : 'E'}${lonBucket.abs()}';
  }

  Future<void> _initializePush() async {
    final auth = AppServices.of(context).auth;
    if (!auth.canUseProtectedFeatures) return;
    _push = PushService(auth, (target, data) {
      if (!mounted) return;
      if (target == 'care' || target == 'chat') {
        final sessionId = data['sessionId']?.toString();
        context.push(
          '/care${sessionId == null ? '' : '?sessionId=$sessionId'}',
        );
        return;
      }
      setState(() => _tab = _targetTab(target));
      showMessage(context, 'Opened ${prettyEnum(target)} from a notification.');
    });
    try {
      await _push!.initialize();
    } catch (error) {
      if (mounted) setState(() => _pushError = failureMessage(error));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_push?.syncIfAuthorized());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _push?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigationDestinations = [
      NavigationDestination(
        icon: HappifyEmoji.overview(size: 28),
        selectedIcon: HappifyEmoji.overview(size: 30),
        label: 'Home',
      ),
      NavigationDestination(
        icon: HappifyEmoji.mood(size: 28),
        selectedIcon: HappifyEmoji.mood(size: 30),
        label: 'Mood',
      ),
      NavigationDestination(
        icon: HappifyEmoji.records(size: 28),
        selectedIcon: HappifyEmoji.records(size: 30),
        label: 'Journal',
      ),
      NavigationDestination(
        icon: HappifyEmoji.community(size: 28),
        selectedIcon: HappifyEmoji.community(size: 30),
        label: 'Community',
      ),
      NavigationDestination(
        icon: HappifyEmoji.profile(size: 28),
        selectedIcon: HappifyEmoji.profile(size: 30),
        label: 'Profile',
      ),
    ];
    final railDestinations = [
      NavigationRailDestination(
        icon: HappifyEmoji.overview(size: 28),
        selectedIcon: HappifyEmoji.overview(size: 30),
        label: const Text('Home'),
      ),
      NavigationRailDestination(
        icon: HappifyEmoji.mood(size: 28),
        selectedIcon: HappifyEmoji.mood(size: 30),
        label: const Text('Mood'),
      ),
      NavigationRailDestination(
        icon: HappifyEmoji.records(size: 28),
        selectedIcon: HappifyEmoji.records(size: 30),
        label: const Text('Journal'),
      ),
      NavigationRailDestination(
        icon: HappifyEmoji.community(size: 28),
        selectedIcon: HappifyEmoji.community(size: 30),
        label: const Text('Community'),
      ),
      NavigationRailDestination(
        icon: HappifyEmoji.profile(size: 28),
        selectedIcon: HappifyEmoji.profile(size: 30),
        label: const Text('Profile'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final expanded = constraints.maxWidth >= 900;
        final content = Column(
          children: [
            if (_pushError != null)
              MaterialBanner(
                content: Text(_pushError!),
                actions: [
                  TextButton(
                    onPressed: () => setState(() => _pushError = null),
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: List.generate(
                  _pages.length,
                  (index) => _pages[index] != null || index == _tab
                      ? _page(index)
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        );
        return Scaffold(
          body: expanded
              ? Row(
                  children: [
                    SafeArea(
                      child: NavigationRail(
                        extended: true,
                        minExtendedWidth: 216,
                        selectedIndex: _tab,
                        useIndicator: true,
                        indicatorColor: HappifyColors.greenSurface,
                        backgroundColor: Colors.white,
                        leading: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                          child: HappifyEmoji.sparkle(size: 42),
                        ),
                        onDestinationSelected: (value) =>
                            setState(() => _tab = value),
                        destinations: railDestinations,
                      ),
                    ),
                    const VerticalDivider(width: 2, thickness: 2),
                    Expanded(child: content),
                  ],
                )
              : content,
          floatingActionButton: FloatingActionButton(
            heroTag: 'sos',
            tooltip: 'Open support options',
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const SosSheet(),
            ),
            child: HappifyEmoji.escalation(size: 28),
          ),
          bottomNavigationBar: expanded
              ? null
              : NavigationBar(
                  selectedIndex: _tab,
                  onDestinationSelected: (value) =>
                      setState(() => _tab = value),
                  destinations: navigationDestinations,
                ),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _dashboard = {};
  Map<String, dynamic>? _motivation;
  List<Map<String, dynamic>> _activities = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) unawaited(_load());
  }

  Future<void> _load() async {
    final auth = AppServices.of(context).auth;
    if (!auth.canUseProtectedFeatures) {
      setState(() => _loading = false);
      return;
    }
    try {
      final repo = HappifyRepository(auth.api);
      final results = await Future.wait<Object?>([
        repo.dashboard(),
        repo.motivation(),
        repo.mindfulness(),
      ]);
      if (!mounted) return;
      setState(() {
        _dashboard = results[0]! as Map<String, dynamic>;
        _motivation = results[1] as Map<String, dynamic>?;
        _activities = results[2]! as List<Map<String, dynamic>>;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = failureMessage(error);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppServices.of(context).auth;
    if (!auth.canUseProtectedFeatures) {
      return HappifyPage(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Welcome to Happify',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Icon(
                PhosphorIcons.signIn(PhosphorIconsStyle.duotone),
                size: 54,
                color: HappifyColors.greenDark,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const FeatureCard(
            child: Text(
              'Sign in to securely use mood tracking, journaling, community, voice, care, and Companion features.',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/login'),
            child: const Text('Sign in'),
          ),
        ],
      );
    }
    final profile = objectMap(_dashboard['profile']);
    final name =
        profile['displayName']?.toString() ??
        auth.firebaseUser?.displayName ??
        'Friend';
    final motivation = _motivation?['message']?.toString();
    return HappifyPage(
      refresh: _load,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome'),
                  Text(
                    'Hi, $name',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIcons.userCircle(PhosphorIconsStyle.duotone),
              size: 58,
              color: HappifyColors.greenDark,
            ),
          ],
        ),
        const SizedBox(height: 22),
        AsyncStateView(
          loading: _loading,
          error: _error,
          isEmpty: false,
          onRetry: () {
            setState(() => _loading = true);
            unawaited(_load());
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FeatureCard(
                color: const Color(0xFFF3E3D0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today’s motivation',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      motivation ??
                          'No English motivation has been published for today.',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (_motivation?['author'] != null)
                      Text('— ${_motivation!['author']}'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ActionChip(
                    avatar: HappifyEmoji.microphone(size: 24),
                    label: const Text('Voice companion'),
                    onPressed: () => context.push('/voice'),
                  ),
                  ActionChip(
                    avatar: HappifyEmoji.care(size: 24),
                    label: const Text('Professional care'),
                    onPressed: () => context.push('/care'),
                  ),
                  ActionChip(
                    avatar: HappifyEmoji.companion(size: 24),
                    label: const Text('Companion device'),
                    onPressed: () => context.push('/companion'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Mindfulness',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              if (_activities.isEmpty)
                const FeatureCard(
                  child: Text(
                    'No English mindfulness activities are published.',
                  ),
                )
              else
                ..._activities
                    .take(3)
                    .map(
                      (activity) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FeatureCard(
                          onTap: () =>
                              showMindfulnessActivity(context, activity),
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIcons.playCircle(
                                  PhosphorIconsStyle.fill,
                                ),
                                color: HappifyColors.sageDeep,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activity['title'].toString(),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    Text(
                                      '${prettyEnum(activity['type'])} · ${(activity['durationSeconds'] as num? ?? 0).toInt()} seconds',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

class SosSheet extends StatefulWidget {
  const SosSheet({super.key});

  @override
  State<SosSheet> createState() => _SosSheetState();
}

class _SosSheetState extends State<SosSheet> {
  bool _speaking = false;
  static const grounding =
      'Breathe slowly. Name five things you can see, four things you can touch, three sounds you can hear, two scents, and one thing you appreciate.';

  @override
  Widget build(BuildContext context) {
    final services = AppServices.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  HappifyEmoji.grounding(size: 64),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Let us get calm first.',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold)),
                    tooltip: 'Close SOS',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const FeatureCard(
                color: Color(0xFFDCE7D6),
                child: Text(
                  'Breathe in for four counts, hold for four, and breathe out for six. You are not alone in this moment.',
                ),
              ),
              const SizedBox(height: 14),
              const Text(grounding),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () async {
                  setState(() => _speaking = !_speaking);
                  await services.speech.speak(grounding);
                  if (mounted) setState(() => _speaking = false);
                },
                icon: Icon(
                  _speaking
                      ? PhosphorIcons.stop(PhosphorIconsStyle.fill)
                      : PhosphorIcons.speakerHigh(PhosphorIconsStyle.bold),
                ),
                label: Text(
                  _speaking ? 'Stop guidance' : 'Read guidance aloud',
                ),
              ),
              const SizedBox(height: 10),
              HappifyButton(
                label: services.auth.canUseProtectedFeatures
                    ? 'Choose someone to call'
                    : 'Open phone dialer',
                leading: HappifyEmoji.phone(size: 22),
                background: HappifyColors.coral,
                onPressed: services.auth.canUseProtectedFeatures
                    ? () => context.push('/contacts')
                    : () async {
                        final opened = await launchUrl(
                          Uri(scheme: 'tel'),
                          mode: LaunchMode.externalApplication,
                        );
                        if (!opened && context.mounted) {
                          showMessage(
                            context,
                            'No phone dialer is available on this device.',
                          );
                        }
                      },
              ),
              TextButton(
                onPressed: services.auth.canUseProtectedFeatures
                    ? () => context.push('/care')
                    : () => context.go('/login'),
                child: Text(
                  services.auth.canUseProtectedFeatures
                      ? 'Open professional care options'
                      : 'Sign in for professional care options',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
