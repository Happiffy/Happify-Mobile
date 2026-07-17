import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../core/app_services.dart';
import '../../core/happify_repository.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/happify_button.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _loading = true;
  bool _saving = false;
  AuthorizationStatus? _status;
  Map<String, bool> _choices = {
    'careChat': false,
    'referral': false,
    'moodReminders': false,
    'wellbeingUpdates': false,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait([
        FirebaseMessaging.instance.getNotificationSettings(),
        HappifyRepository(AppServices.of(context).auth.api).preference(),
      ]);
      final preference = values[1] as Map<String, dynamic>?;
      final saved = objectMap(preference?['notifications']);
      if (mounted) {
        setState(() {
          _status = (values[0] as NotificationSettings).authorizationStatus;
          _choices = {
            'careChat': saved['careChat'] == true,
            'referral': saved['referral'] == true,
            'moodReminders': saved['moodReminders'] == true,
            'wellbeingUpdates': saved['wellbeingUpdates'] == true,
          };
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _loading = false);
        showMessage(context, failureMessage(error));
      }
    }
  }

  Future<void> _enableDeviceNotifications() async {
    setState(() => _loading = true);
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (mounted) setState(() => _status = settings.authorizationStatus);
    } catch (error) {
      if (mounted) showMessage(context, failureMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateChoice(String key, bool value) async {
    final next = {..._choices, key: value};
    setState(() {
      _choices = next;
      _saving = true;
    });
    try {
      await HappifyRepository(
        AppServices.of(context).auth.api,
      ).updateNotificationPreferences({key: value});
    } catch (error) {
      if (mounted) {
        setState(() => _choices = {..._choices, key: !value});
        showMessage(context, failureMessage(error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled =
        _status == AuthorizationStatus.authorized ||
        _status == AuthorizationStatus.provisional;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      bottomNavigationBar: !enabled && !_loading
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              child: HappifyButton(
                label: 'Enable device notifications',
                onPressed: _enableDeviceNotifications,
              ),
            )
          : null,
      body: HappifyPage(
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _NotificationChoice(
              title: 'Care chat messages',
              subtitle:
                  'Replies and status changes from your care professional.',
              value: _choices['careChat'] ?? false,
              onChanged: _saving
                  ? null
                  : (value) => _updateChoice('careChat', value),
            ),
            _NotificationChoice(
              title: 'Referral updates',
              subtitle: 'Updates when a professional-care request is reviewed.',
              value: _choices['referral'] ?? false,
              onChanged: _saving
                  ? null
                  : (value) => _updateChoice('referral', value),
            ),
            _NotificationChoice(
              title: 'Mood reminders',
              subtitle: 'A gentle reminder to check in with your mood.',
              value: _choices['moodReminders'] ?? false,
              onChanged: _saving
                  ? null
                  : (value) => _updateChoice('moodReminders', value),
            ),
            _NotificationChoice(
              title: 'Wellbeing updates',
              subtitle: 'Mindfulness and wellbeing content updates.',
              value: _choices['wellbeingUpdates'] ?? false,
              onChanged: _saving
                  ? null
                  : (value) => _updateChoice('wellbeingUpdates', value),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationChoice extends StatelessWidget {
  const _NotificationChoice({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FeatureCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
