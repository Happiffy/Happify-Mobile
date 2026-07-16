import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/app_services.dart';
import '../../core/happify_repository.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/happify_emoji.dart';
import '../../core/widgets/quokka_badge.dart';
import 'bloc/profile_cubit.dart';
import 'bloc/profile_state.dart';
import 'data/profile_repository.dart';

enum BlocProfileDestination {
  wellbeingPreferences,
  accessibility,
  consent,
  emergencyContacts,
  professionalCare,
  voiceCompanion,
  companion,
}

typedef ProfileNavigationCallback =
    FutureOr<void> Function(
      BlocProfileDestination destination,
      PreferenceData? preference,
    );
typedef ProfileActionCallback = FutureOr<void> Function();

class BlocProfilePage extends StatelessWidget {
  const BlocProfilePage({
    required this.settings,
    required this.onNavigate,
    required this.onNotifications,
    required this.onSignOut,
    this.repository,
    super.key,
  });

  final AppSettings settings;
  final ProfileNavigationCallback onNavigate;
  final ProfileActionCallback onNotifications;
  final ProfileActionCallback onSignOut;
  final ProfileRepository? repository;

  @override
  Widget build(BuildContext context) {
    final profileRepository =
        repository ??
        HappifyProfileRepository(context.read<HappifyRepository>());
    return BlocProvider(
      create: (_) => ProfileCubit(repository: profileRepository)..load(),
      child: BlocProfileView(
        settings: settings,
        onNavigate: onNavigate,
        onNotifications: onNotifications,
        onSignOut: onSignOut,
      ),
    );
  }
}

class BlocProfileView extends StatefulWidget {
  const BlocProfileView({
    required this.settings,
    required this.onNavigate,
    required this.onNotifications,
    required this.onSignOut,
    super.key,
  });

  final AppSettings settings;
  final ProfileNavigationCallback onNavigate;
  final ProfileActionCallback onNotifications;
  final ProfileActionCallback onSignOut;

  @override
  State<BlocProfileView> createState() => _BlocProfileViewState();
}

class _BlocProfileViewState extends State<BlocProfileView> {
  bool _runningAction = false;

  Future<void> _runAction(ProfileActionCallback action) async {
    if (_runningAction) return;
    setState(() => _runningAction = true);
    try {
      await Future<void>.sync(action);
    } catch (error) {
      if (mounted) showMessage(context, failureMessage(error));
    } finally {
      if (mounted) setState(() => _runningAction = false);
    }
  }

  Future<void> _navigate(BlocProfileDestination destination) async {
    final preference = context.read<ProfileCubit>().state.preference;
    await _runAction(() => widget.onNavigate(destination, preference));
    if (mounted && destination == BlocProfileDestination.wellbeingPreferences) {
      unawaited(context.read<ProfileCubit>().loadPreference());
    }
  }

  Future<void> _editProfile(ProfileData profile) async {
    final cubit = context.read<ProfileCubit>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _EditProfileDialog(profile: profile),
      ),
    );
    if (saved == true && mounted) {
      showMessage(context, 'Profile updated.');
    }
  }

  Future<void> _applyPsychologist(ProfileData profile) async {
    final cubit = context.read<ProfileCubit>();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _PsychologistApplicationDialog(profile: profile),
      ),
    );
    if (submitted == true && mounted) {
      showMessage(context, 'Psychologist application submitted for review.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return HappifyPage(
          title: 'Profile',
          refresh: context.read<ProfileCubit>().load,
          bottomPadding: 110,
          actions: [
            IconButton(
              onPressed:
                  state.profile == null || state.isSaving || _runningAction
                  ? null
                  : () => _editProfile(state.profile!),
              icon: HappifyEmoji.edit(size: 24),
              tooltip: 'Edit profile',
            ),
          ],
          children: [
            _ProfileSummary(
              state: state,
              onRetry: context.read<ProfileCubit>().loadProfile,
              onEdit: state.profile == null || _runningAction
                  ? null
                  : () => _editProfile(state.profile!),
            ),
            const SizedBox(height: 18),
            Text(
              'Wellbeing preferences',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            _PreferenceSummary(
              state: state,
              onRetry: context.read<ProfileCubit>().loadPreference,
              onOpen: _runningAction
                  ? null
                  : () =>
                        _navigate(BlocProfileDestination.wellbeingPreferences),
            ),
            if (state.profile != null &&
                state.profile!.role != 'PSYCHOLOGIST') ...[
              const SizedBox(height: 18),
              _PsychologistApplicationCard(
                state: state,
                onApply: _runningAction
                    ? null
                    : () => _applyPsychologist(state.profile!),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              'Current app settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            ListenableBuilder(
              listenable: widget.settings,
              builder: (context, _) => FeatureCard(
                onTap: _runningAction
                    ? null
                    : () => _navigate(BlocProfileDestination.accessibility),
                child: Column(
                  children: [
                    _ValueRow(
                      label: 'Text scale',
                      value: prettyEnum(widget.settings.textScale),
                    ),
                    _ValueRow(
                      label: 'High contrast',
                      value: _enabled(widget.settings.highContrast),
                    ),
                    _ValueRow(
                      label: 'Reduced motion',
                      value: _enabled(widget.settings.reducedMotion),
                    ),
                    _ValueRow(
                      label: 'Screen reader optimized',
                      value: _enabled(widget.settings.screenReaderOptimized),
                    ),
                    _ValueRow(
                      label: 'Audio mode',
                      value: _enabled(widget.settings.audioMode),
                      last: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Settings and actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            _ProfileActionTile(
              icon: HappifyEmoji.notifications(size: 38),

              title: 'Notifications',
              subtitle: 'Enable care updates and important messages',
              onTap: _runningAction
                  ? null
                  : () => _runAction(widget.onNotifications),
            ),
            _ProfileActionTile(
              icon: HappifyEmoji.shield(size: 38),

              title: 'Consent and privacy',
              subtitle: 'Review AI, voice, device, and heatmap choices',
              onTap: _runningAction
                  ? null
                  : () => _navigate(BlocProfileDestination.consent),
            ),
            _ProfileActionTile(
              icon: HappifyEmoji.phone(size: 38),

              title: 'Emergency contacts',
              subtitle: 'Manage trusted contacts',
              onTap: _runningAction
                  ? null
                  : () => _navigate(BlocProfileDestination.emergencyContacts),
            ),
            _ProfileActionTile(
              icon: HappifyEmoji.care(size: 38),

              title: 'Professional care',
              subtitle: 'Providers, referrals, status, and care chat',
              onTap: _runningAction
                  ? null
                  : () => _navigate(BlocProfileDestination.professionalCare),
            ),
            _ProfileActionTile(
              icon: HappifyEmoji.microphone(size: 38),

              title: 'Voice companion',
              subtitle: 'Record and play protected responses',
              onTap: _runningAction
                  ? null
                  : () => _navigate(BlocProfileDestination.voiceCompanion),
            ),
            _ProfileActionTile(
              icon: HappifyEmoji.companion(size: 38),

              title: 'Happify Companion',
              subtitle: 'Pairing, telemetry, commands, and updates',
              onTap: _runningAction
                  ? null
                  : () => _navigate(BlocProfileDestination.companion),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _runningAction
                    ? null
                    : () => _runAction(widget.onSignOut),
                icon: HappifyEmoji.signOut(size: 24),
                label: Text(_runningAction ? 'Please wait...' : 'Sign out'),
              ),
            ),
          ],
        );
      },
    );
  }

  String _enabled(bool value) => value ? 'Enabled' : 'Off';
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({
    required this.state,
    required this.onRetry,
    required this.onEdit,
  });

  final ProfileState state;
  final VoidCallback onRetry;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final profile = state.profile;
    if (state.profileStatus == ProfileLoadStatus.loading && profile == null) {
      return const FeatureCard(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (profile == null) {
      return _ProfileLoadCard(
        message: state.profileError ?? 'Profile details are unavailable.',
        onRetry: onRetry,
      );
    }
    return Column(
      children: [
        if (state.profileError != null) ...[
          _ProfileLoadCard(message: state.profileError!, onRetry: onRetry),
          const SizedBox(height: 10),
        ],
        FeatureCard(
          child: Column(
            children: [
              HappifyAvatar(
                size: 104,
                imageUrl: profile.avatarUrl,
                fallbackName: profile.displayName,
              ),
              const SizedBox(height: 12),
              Text(
                profile.displayName.isEmpty
                    ? 'Happify member'
                    : profile.displayName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (profile.email.isNotEmpty) Text(profile.email),
              if (profile.bio.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(profile.bio, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                onPressed: onEdit,
                icon: HappifyEmoji.edit(size: 24),
                label: const Text('Edit display name and bio'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreferenceSummary extends StatelessWidget {
  const _PreferenceSummary({
    required this.state,
    required this.onRetry,
    required this.onOpen,
  });

  final ProfileState state;
  final VoidCallback onRetry;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final preference = state.preference;
    if (state.preferenceStatus == ProfileLoadStatus.loading &&
        preference == null) {
      return const FeatureCard(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (state.preferenceStatus == ProfileLoadStatus.failure &&
        preference == null) {
      return _ProfileLoadCard(
        message:
            state.preferenceError ?? 'Wellbeing preferences are unavailable.',
        onRetry: onRetry,
      );
    }
    if (preference == null) {
      return FeatureCard(
        onTap: onOpen,
        child: const Text(
          'No wellbeing preferences have been saved. Open settings to add them.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return Column(
      children: [
        if (state.preferenceError != null) ...[
          _ProfileLoadCard(message: state.preferenceError!, onRetry: onRetry),
          const SizedBox(height: 10),
        ],
        FeatureCard(
          onTap: onOpen,
          child: Column(
            children: [
              _ValueRow(
                label: 'Primary goal',
                value: _fallback(preference.primaryGoal),
              ),
              _ValueRow(
                label: 'Support tone',
                value: _fallback(preference.supportTone),
              ),
              _ValueRow(
                label: 'Triggers',
                value: preference.triggers.isEmpty
                    ? 'None saved'
                    : preference.triggers.join(', '),
              ),
              _ValueRow(
                label: 'High-risk support',
                value: _fallback(preference.highRiskAction),
              ),
              _ValueRow(
                label: 'Privacy consent',
                value: 'Manage in Consent and privacy',
                last: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fallback(String value) => value.isEmpty ? 'Not set' : value;
}

class _PsychologistApplicationCard extends StatelessWidget {
  const _PsychologistApplicationCard({
    required this.state,
    required this.onApply,
  });

  final ProfileState state;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    final application = state.profile?.psychologistApplication;
    final status = application?.status;
    final statusText = switch (status) {
      PsychologistApplicationStatus.pending => 'Pending review',
      PsychologistApplicationStatus.approved => 'Approved',
      PsychologistApplicationStatus.rejected => 'Needs revision',
      null => 'Not submitted',
    };
    return FeatureCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Psychologist role',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text(
            'Submit verified license and certificate details. An admin must review the application before your role changes.',
          ),
          const SizedBox(height: 12),
          Text(
            'Status: $statusText',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (application?.reviewComment?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text('Review note: ${application!.reviewComment}'),
          ],
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: status == PsychologistApplicationStatus.pending
                ? null
                : onApply,
            icon: HappifyEmoji.psychologist(size: 24),
            label: Text(
              status == PsychologistApplicationStatus.rejected
                  ? 'Update application'
                  : 'Apply as psychologist',
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileLoadCard extends StatelessWidget {
  const _ProfileLoadCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FeatureCard(
      child: Column(
        children: [
          HappifyEmoji.warning(size: 34),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Widget icon;

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      onTap: onTap,
      leading: ExcludeSemantics(child: icon),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(subtitle),
      trailing: HappifyEmoji.next(size: 22),
    );
  }
}

class _PsychologistApplicationDialog extends StatefulWidget {
  const _PsychologistApplicationDialog({required this.profile});

  final ProfileData profile;

  @override
  State<_PsychologistApplicationDialog> createState() =>
      _PsychologistApplicationDialogState();
}

class _PsychologistApplicationDialogState
    extends State<_PsychologistApplicationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullName;
  late final TextEditingController _licenseNumber;
  late final TextEditingController _certificateUrl;
  late final TextEditingController _institution;
  late final TextEditingController _reason;

  @override
  void initState() {
    super.initState();
    final application = widget.profile.psychologistApplication;
    _fullName = TextEditingController(text: application?.fullName ?? '');
    _licenseNumber = TextEditingController(
      text: application?.licenseNumber ?? '',
    );
    _certificateUrl = TextEditingController(
      text: application?.certificateUrl ?? '',
    );
    _institution = TextEditingController(text: application?.institution ?? '');
    _reason = TextEditingController(text: application?.reason ?? '');
  }

  @override
  void dispose() {
    _fullName.dispose();
    _licenseNumber.dispose();
    _certificateUrl.dispose();
    _institution.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    final submitted = await context.read<ProfileCubit>().applyPsychologist(
      fullName: _fullName.text,
      licenseNumber: _licenseNumber.text,
      certificateUrl: _certificateUrl.text,
      institution: _institution.text,
      reason: _reason.text,
    );
    if (submitted && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) => AlertDialog(
        title: const Text('Apply as psychologist'),
        content: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _fullName,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (value) =>
                      ProfileCubit.validateFullName(value ?? ''),
                ),
                TextFormField(
                  controller: _licenseNumber,
                  decoration: const InputDecoration(
                    labelText: 'License number',
                  ),
                  validator: (value) =>
                      ProfileCubit.validateLicenseNumber(value ?? ''),
                ),
                TextFormField(
                  controller: _certificateUrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Certificate URL',
                  ),
                  validator: (value) =>
                      ProfileCubit.validateCertificateUrl(value ?? ''),
                ),
                TextFormField(
                  controller: _institution,
                  decoration: const InputDecoration(
                    labelText: 'Institution (optional)',
                  ),
                  validator: (value) =>
                      ProfileCubit.validateInstitution(value ?? ''),
                ),
                TextFormField(
                  controller: _reason,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Why do you want to help? (optional)',
                  ),
                  validator: (value) =>
                      ProfileCubit.validateReason(value ?? ''),
                ),
                if (state.applicationError != null) ...[
                  const SizedBox(height: 8),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      state.applicationError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: state.isApplying
                ? null
                : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: state.isApplying ? null : _submit,
            child: Text(state.isApplying ? 'Submitting...' : 'Submit'),
          ),
        ],
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.profile});

  final ProfileData profile;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayName;
  late final TextEditingController _bio;

  @override
  void initState() {
    super.initState();
    _displayName = TextEditingController(text: widget.profile.displayName);
    _bio = TextEditingController(text: widget.profile.bio);
  }

  @override
  void dispose() {
    _displayName.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    final saved = await context.read<ProfileCubit>().saveProfile(
      displayName: _displayName.text,
      bio: _bio.text,
    );
    if (saved && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return AlertDialog(
          title: const Text('Edit profile'),
          content: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _displayName,
                    autofocus: true,
                    maxLength: 120,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                    ),
                    validator: (value) =>
                        ProfileCubit.validateDisplayName(value ?? ''),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _bio,
                    maxLength: 500,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Bio'),
                    validator: (value) => ProfileCubit.validateBio(value ?? ''),
                  ),
                  if (state.saveError != null) ...[
                    const SizedBox(height: 8),
                    Semantics(
                      liveRegion: true,
                      child: const Text(
                        'We could not save your profile. Please try again.',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: state.isSaving
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: state.isSaving ? null : _save,
              child: Text(state.isSaving ? 'Saving...' : 'Save'),
            ),
          ],
        );
      },
    );
  }
}
