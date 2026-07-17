import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/happify_button.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      showMessage(
        context,
        'Password changes are unavailable for this account.',
      );
      return;
    }
    if (_next.text.length < 8 || _next.text != _confirm.text) {
      showMessage(
        context,
        'Use a matching password with at least 8 characters.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(
          email: user.email!,
          password: _current.text,
        ),
      );
      await user.updatePassword(_next.text);
      if (mounted) {
        showMessage(context, 'Password updated.');
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        showMessage(
          context,
          error.code == 'wrong-password' || error.code == 'invalid-credential'
              ? 'Your current password is incorrect.'
              : 'Password could not be updated. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Change password')),
    body: HappifyPage(
      children: [
        Text(
          'Keep your account secure.',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text('Enter your current password before choosing a new one.'),
        const SizedBox(height: 24),
        _PasswordField(label: 'Current password', controller: _current),
        const SizedBox(height: 16),
        _PasswordField(label: 'New password', controller: _next),
        const SizedBox(height: 16),
        _PasswordField(label: 'Confirm new password', controller: _confirm),
        const SizedBox(height: 24),
        HappifyButton(
          label: _saving ? 'Updating...' : 'Update password',
          onPressed: _saving ? null : _save,
        ),
      ],
    ),
  );
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: true,
    autofillHints: const [AutofillHints.password],
    decoration: InputDecoration(labelText: label),
  );
}
