import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_services.dart';
import '../../core/happify_repository.dart';
import '../../core/theme/happify_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/happify_button.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _name = TextEditingController();
  final _bio = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) _load();
  }

  Future<void> _load() async {
    try {
      final profile = await HappifyRepository(
        AppServices.of(context).auth.api,
      ).profile();
      if (mounted) {
        _name.text = profile['displayName']?.toString() ?? '';
        _bio.text = profile['bio']?.toString() ?? '';
        setState(() => _loading = false);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _loading = false);
        showMessage(context, failureMessage(error));
      }
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      showMessage(context, 'Enter a display name.');
      return;
    }
    setState(() => _saving = true);
    try {
      await HappifyRepository(
        AppServices.of(context).auth.api,
      ).updateProfile(displayName: _name.text.trim(), bio: _bio.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showMessage(context, failureMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: HappifyPage(
        children: [
          Text(
            'Make your profile feel like you.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Your email address is private and cannot be changed here.',
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            _FormField(
              label: 'Display name',
              controller: _name,
              maxLength: 120,
            ),
            const SizedBox(height: 16),
            _FormField(
              label: 'About you',
              controller: _bio,
              maxLines: 5,
              maxLength: 500,
            ),
            const SizedBox(height: 24),
            HappifyButton(
              label: _saving ? 'Saving...' : 'Save profile',
              onPressed: _saving ? null : _save,
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () => context.push('/profile/password'),
              child: const Text('Change password'),
            ),
          ],
        ],
      ),
    );
  }
}

class PsychologistApplicationPage extends StatefulWidget {
  const PsychologistApplicationPage({super.key});

  @override
  State<PsychologistApplicationPage> createState() =>
      _PsychologistApplicationPageState();
}

class _PsychologistApplicationPageState
    extends State<PsychologistApplicationPage> {
  final _fullName = TextEditingController();
  final _license = TextEditingController();
  final _certificate = TextEditingController();
  final _institution = TextEditingController();
  final _reason = TextEditingController();
  bool _saving = false;

  Future<void> _submit() async {
    if (_fullName.text.trim().isEmpty ||
        _license.text.trim().length < 3 ||
        Uri.tryParse(_certificate.text.trim())?.hasAbsolutePath != true) {
      showMessage(
        context,
        'Enter your name, a valid license number, and certificate URL.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await HappifyRepository(
        AppServices.of(context).auth.api,
      ).applyPsychologist(
        fullName: _fullName.text.trim(),
        licenseNumber: _license.text.trim(),
        certificateUrl: _certificate.text.trim(),
        institution: _institution.text.trim(),
        reason: _reason.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showMessage(context, failureMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _license.dispose();
    _certificate.dispose();
    _institution.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply as psychologist')),
      body: HappifyPage(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: HappifyColors.purpleSurface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              'Applications are reviewed before a psychologist role is granted. Do not submit sensitive client information.',
            ),
          ),
          const SizedBox(height: 22),
          _FormField(label: 'Full name', controller: _fullName, maxLength: 120),
          const SizedBox(height: 14),
          _FormField(
            label: 'License number',
            controller: _license,
            maxLength: 120,
          ),
          const SizedBox(height: 14),
          _FormField(
            label: 'Certificate URL',
            controller: _certificate,
            keyboardType: TextInputType.url,
            maxLength: 2000,
          ),
          const SizedBox(height: 14),
          _FormField(
            label: 'Institution (optional)',
            controller: _institution,
            maxLength: 160,
          ),
          const SizedBox(height: 14),
          _FormField(
            label: 'Why do you want to join? (optional)',
            controller: _reason,
            maxLines: 5,
            maxLength: 800,
          ),
          const SizedBox(height: 24),
          HappifyButton(
            label: _saving ? 'Submitting...' : 'Submit application',
            onPressed: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
  });
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: label),
        ),
      ],
    );
  }
}
