import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/app_services.dart';
import '../core/happify_repository.dart';
import '../core/widgets/common_widgets.dart';
import '../core/widgets/happify_emoji.dart';
import '../core/widgets/quokka_badge.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _profile = {};
  Map<String, dynamic>? _preference;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) unawaited(_load());
  }

  Future<void> _load() async {
    final auth = AppServices.of(context).auth;
    if (!auth.canUseProtectedFeatures) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final repo = HappifyRepository(auth.api);
      final results = await Future.wait<Object?>([
        repo.profile(),
        repo.preference(),
      ]);
      if (!mounted) return;
      _profile = results[0]! as Map<String, dynamic>;
      _preference = results[1] as Map<String, dynamic>?;
      await AppServices.of(context).settings.mergeBackend(_preference);
      if (mounted) {
        setState(() {
          _loading = false;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = failureMessage(error);
        });
      }
    }
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(
      text: _profile['displayName']?.toString() ?? '',
    );
    final bioController = TextEditingController(
      text: _profile['bio']?.toString() ?? '',
    );
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            TextField(
              controller: bioController,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Bio'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (save != true || !mounted) {
      nameController.dispose();
      bioController.dispose();
      return;
    }
    try {
      await HappifyRepository(AppServices.of(context).auth.api).updateProfile(
        displayName: nameController.text.trim(),
        bio: bioController.text.trim(),
      );
      await _load();
    } catch (error) {
      if (mounted) showMessage(context, failureMessage(error));
    } finally {
      nameController.dispose();
      bioController.dispose();
    }
  }

  Future<void> _notifications() async {
    final auth = AppServices.of(context).auth;
    final service = PushService(auth, (_, _) {});
    try {
      final status = await service.requestPermission();
      if (mounted) {
        showMessage(
          context,
          status == AuthorizationStatus.authorized ||
                  status == AuthorizationStatus.provisional
              ? 'Notifications are enabled.'
              : 'Notifications were not enabled.',
        );
      }
    } catch (error) {
      if (mounted) showMessage(context, failureMessage(error));
    } finally {
      service.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = AppServices.of(context);
    if (!services.auth.canUseProtectedFeatures) {
      return SignInGuard(
        child: FilledButton(
          onPressed: () => context.go('/welcome'),
          child: const Text('Return to Welcome'),
        ),
      );
    }
    return HappifyPage(
      title: 'Profile',
      refresh: _load,
      actions: [
        IconButton(
          onPressed: _editProfile,
          icon: const Icon(Icons.edit),
          tooltip: 'Edit profile',
        ),
      ],
      children: [
        AsyncStateView(
          loading: _loading,
          error: _error,
          isEmpty: false,
          onRetry: () {
            setState(() => _loading = true);
            unawaited(_load());
          },
          child: Column(
            children: [
              HappifyAvatar(
                size: 104,
                imageUrl: _profile['avatarUrl']?.toString(),
                fallbackName: _profile['displayName']?.toString(),
              ),
              const SizedBox(height: 12),
              Text(
                _profile['displayName']?.toString() ?? 'Happify member',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(_profile['email']?.toString() ?? ''),
              if (_profile['bio'] != null)
                Text(_profile['bio'].toString(), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              SettingsAction(
                icon: Icons.notifications,
                title: 'Notifications',
                subtitle: 'Enable care updates and important messages',
                onTap: _notifications,
              ),
              SettingsAction(
                icon: Icons.tune,
                title: 'Wellbeing preferences',
                subtitle: 'Goal, triggers, support tone, and high-risk support',
                onTap: () async {
                  await showDialog<void>(
                    context: context,
                    builder: (_) =>
                        WellbeingPreferencesDialog(preference: _preference),
                  );
                  await _load();
                },
              ),
              SettingsAction(
                icon: Icons.accessibility_new,
                title: 'Accessibility and audio',
                subtitle:
                    'Text scale, contrast, motion, screen reader, and audio mode',
                onTap: () async {
                  await showDialog<void>(
                    context: context,
                    builder: (_) =>
                        AccessibilityDialog(preference: _preference),
                  );
                  await _load();
                },
              ),
              SettingsAction(
                icon: Icons.privacy_tip,
                title: 'Consent and privacy',
                subtitle: 'Review AI, voice, and heatmap choices',
                onTap: () => context.push('/consent'),
              ),
              SettingsAction(
                icon: Icons.contact_phone,
                title: 'Emergency contacts',
                subtitle: 'Manage trusted contacts and explicitly place calls',
                onTap: () => context.push('/contacts'),
              ),
              SettingsAction(
                icon: Icons.health_and_safety,
                title: 'Professional care',
                subtitle: 'Providers, referrals, status, and care chat',
                onTap: () => context.push('/care'),
              ),
              SettingsAction(
                icon: Icons.mic,
                title: 'Voice companion',
                subtitle: 'Record, process, and play protected responses',
                onTap: () => context.push('/voice'),
              ),
              SettingsAction(
                icon: Icons.watch,
                title: 'Happify Companion',
                subtitle: 'Pairing, telemetry, commands, and OTA status',
                onTap: () => context.push('/companion'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final push = PushService(services.auth, (_, _) {});
                  await services.auth.logout(unregisterPush: push.unregister);
                  push.dispose();
                  if (context.mounted) context.go('/welcome');
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsAction extends StatelessWidget {
  const SettingsAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FeatureCard(
        onTap: onTap,
        child: Row(
          children: [
            CircleAvatar(child: Icon(icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class WellbeingPreferencesDialog extends StatefulWidget {
  const WellbeingPreferencesDialog({required this.preference, super.key});
  final Map<String, dynamic>? preference;

  @override
  State<WellbeingPreferencesDialog> createState() =>
      _WellbeingPreferencesDialogState();
}

class _WellbeingPreferencesDialogState
    extends State<WellbeingPreferencesDialog> {
  late final TextEditingController _goal;
  late final TextEditingController _triggers;
  late final TextEditingController _tone;
  late final TextEditingController _riskAction;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final preference = widget.preference ?? <String, dynamic>{};
    _goal = TextEditingController(
      text: preference['primaryGoal']?.toString() ?? 'General wellbeing',
    );
    _triggers = TextEditingController(
      text: (preference['triggers'] as List? ?? const []).join(', '),
    );
    _tone = TextEditingController(
      text: preference['supportTone']?.toString() ?? 'Gentle',
    );
    _riskAction = TextEditingController(
      text:
          preference['highRiskAction']?.toString() ?? 'Show emergency support',
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final services = AppServices.of(context);
    final current = widget.preference ?? <String, dynamic>{};
    final modes = (current['accessibilityMode'] as List? ?? const [])
        .map((item) => '$item')
        .toList();
    if (services.settings.audioMode && !modes.contains('AUDIO_MODE')) {
      modes.add('AUDIO_MODE');
    }
    try {
      await HappifyRepository(services.auth.api).savePreference({
        'primaryGoal': _goal.text.trim(),
        'triggers': _triggers.text
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(),
        'supportTone': _tone.text.trim(),
        'highRiskAction': _riskAction.text.trim(),
        'accessibilityMode': modes,
        'accessibility': {
          'textScale': services.settings.textScale,
          'highContrast': services.settings.highContrast,
          'reducedMotion': services.settings.reducedMotion,
          'screenReaderOptimized': services.settings.screenReaderOptimized,
        },
        'consentToAi': current['consentToAi'] == true,
      });
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) showMessage(context, failureMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _goal.dispose();
    _triggers.dispose();
    _tone.dispose();
    _riskAction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Wellbeing preferences'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _goal,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Primary goal'),
            ),
            TextField(
              controller: _triggers,
              decoration: const InputDecoration(
                labelText: 'Known triggers, separated by commas',
              ),
            ),
            TextField(
              controller: _tone,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Support tone'),
            ),
            TextField(
              controller: _riskAction,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Preferred high-risk action',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }
}

class AccessibilityDialog extends StatefulWidget {
  const AccessibilityDialog({required this.preference, super.key});
  final Map<String, dynamic>? preference;

  @override
  State<AccessibilityDialog> createState() => _AccessibilityDialogState();
}

class _AccessibilityDialogState extends State<AccessibilityDialog> {
  bool _saving = false;
  late String _textScale;
  late bool _highContrast;
  late bool _reducedMotion;
  late bool _screenReaderOptimized;
  late bool _audioMode;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final settings = AppServices.of(context).settings;
    _textScale = settings.textScale;
    _highContrast = settings.highContrast;
    _reducedMotion = settings.reducedMotion;
    _screenReaderOptimized = settings.screenReaderOptimized;
    _audioMode = settings.audioMode;
    _initialized = true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final services = AppServices.of(context);
    final settings = services.settings;
    final previous = (
      settings.textScale,
      settings.highContrast,
      settings.reducedMotion,
      settings.screenReaderOptimized,
      settings.audioMode,
    );
    try {
      await settings.update(
        textScale: _textScale,
        highContrast: _highContrast,
        reducedMotion: _reducedMotion,
        screenReaderOptimized: _screenReaderOptimized,
        audioMode: _audioMode,
      );
      await settings.sync(services.auth.api, widget.preference);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      await settings.update(
        textScale: previous.$1,
        highContrast: previous.$2,
        reducedMotion: previous.$3,
        screenReaderOptimized: previous.$4,
        audioMode: previous.$5,
      );
      if (mounted) showMessage(context, failureMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Accessibility and audio'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _textScale,
              decoration: const InputDecoration(labelText: 'Text scale'),
              items: ['SMALL', 'STANDARD', 'LARGE', 'EXTRA_LARGE']
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(prettyEnum(value)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _textScale = value);
              },
            ),
            SwitchListTile(
              title: const Text('High contrast'),
              value: _highContrast,
              onChanged: (value) => setState(() => _highContrast = value),
            ),
            SwitchListTile(
              title: const Text('Reduced motion'),
              value: _reducedMotion,
              onChanged: (value) => setState(() => _reducedMotion = value),
            ),
            SwitchListTile(
              title: const Text('Screen reader optimized'),
              value: _screenReaderOptimized,
              onChanged: (value) =>
                  setState(() => _screenReaderOptimized = value),
            ),
            SwitchListTile(
              title: const Text('Audio mode'),
              subtitle: const Text('Enables optional read-aloud controls'),
              value: _audioMode,
              onChanged: (value) => setState(() => _audioMode = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }
}

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _providers = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final repo = HappifyRepository(AppServices.of(context).auth.api);
      final results = await Future.wait<Object?>([
        repo.emergencyContacts(),
        repo.providers(emergency: true),
      ]);
      if (mounted) {
        setState(() {
          _contacts = results[0]! as List<Map<String, dynamic>>;
          _providers = results[1]! as List<Map<String, dynamic>>;
          _loading = false;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = failureMessage(error);
        });
      }
    }
  }

  Future<void> _edit([Map<String, dynamic>? existing]) async {
    final name = TextEditingController(
      text: existing?['name']?.toString() ?? '',
    );
    final relationship = TextEditingController(
      text: existing?['relationship']?.toString() ?? '',
    );
    final phone = TextEditingController(
      text: existing?['phone']?.toString() ?? '',
    );
    var primary = existing?['isPrimary'] == true;
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existing == null
                ? 'Add emergency contact'
                : 'Edit emergency contact',
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: relationship,
                  decoration: const InputDecoration(labelText: 'Relationship'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                SwitchListTile(
                  title: const Text('Primary contact'),
                  value: primary,
                  onChanged: (value) => setDialogState(() => primary = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (save == true && mounted) {
      try {
        await HappifyRepository(
          AppServices.of(context).auth.api,
        ).saveEmergencyContact(
          id: existing?['id']?.toString(),
          name: name.text.trim(),
          relationship: relationship.text.trim(),
          phone: phone.text.trim(),
          isPrimary: primary,
        );
        await _load();
      } catch (error) {
        if (mounted) showMessage(context, failureMessage(error));
      }
    }
    name.dispose();
    relationship.dispose();
    phone.dispose();
  }

  Future<void> _dial(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      showMessage(context, 'No dialer is available on this device.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency contacts')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        tooltip: 'Add emergency contact',
        child: const Icon(Icons.add),
      ),
      body: HappifyPage(
        refresh: _load,
        children: [
          const FeatureCard(
            color: Color(0xFFFBE4DE),
            child: Text(
              'Happify never places a call automatically. Tapping Call explicitly opens your device dialer.',
            ),
          ),
          const SizedBox(height: 14),
          AsyncStateView(
            loading: _loading,
            error: _error,
            isEmpty: _contacts.isEmpty && _providers.isEmpty,
            emptyMessage:
                'No trusted contacts or emergency providers are available.',
            onRetry: () {
              setState(() => _loading = true);
              unawaited(_load());
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trusted contacts',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (_contacts.isEmpty)
                  const Text('No trusted contacts added yet.'),
                ..._contacts.map(
                  (contact) => ListTile(
                    title: Text(contact['name'].toString()),
                    subtitle: Text(
                      '${contact['relationship']} · ${contact['phone']}${contact['isPrimary'] == true ? ' · Primary' : ''}',
                    ),
                    leading: HappifyEmoji.profile(size: 34),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Contact actions',
                      onSelected: (action) async {
                        switch (action) {
                          case 'call':
                            _dial(contact['phone'].toString());
                          case 'edit':
                            _edit(contact);
                          case 'delete':
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete contact?'),
                                content: Text(
                                  '${contact['name']} will no longer appear in your emergency contacts.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true || !context.mounted) break;
                            await HappifyRepository(
                              AppServices.of(context).auth.api,
                            ).deleteEmergencyContact(contact['id'].toString());
                            await _load();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'call',
                          child: Text('Open dialer'),
                        ),
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Emergency providers',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ..._providers.map(
                  (provider) => ListTile(
                    title: Text(provider['name'].toString()),
                    subtitle: Text(
                      '${provider['description']}\n${provider['region']}',
                    ),
                    isThreeLine: true,
                    trailing: provider['phone'] == null
                        ? null
                        : IconButton(
                            onPressed: () =>
                                _dial(provider['phone'].toString()),
                            icon: Icon(
                              PhosphorIcons.phoneCall(PhosphorIconsStyle.bold),
                            ),
                            tooltip: 'Open dialer',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
