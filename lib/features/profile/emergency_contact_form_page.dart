import 'package:flutter/material.dart';

import '../../core/app_services.dart';
import '../../core/happify_repository.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/happify_button.dart';

class EmergencyContactFormPage extends StatefulWidget {
  const EmergencyContactFormPage({super.key, this.contact});
  final Map<String, dynamic>? contact;

  @override
  State<EmergencyContactFormPage> createState() =>
      _EmergencyContactFormPageState();
}

class _EmergencyContactFormPageState extends State<EmergencyContactFormPage> {
  late final TextEditingController _name;
  late final TextEditingController _relationship;
  late final TextEditingController _phone;
  bool _primary = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: widget.contact?['name']?.toString() ?? '',
    );
    _relationship = TextEditingController(
      text: widget.contact?['relationship']?.toString() ?? '',
    );
    _phone = TextEditingController(
      text: widget.contact?['phone']?.toString() ?? '',
    );
    _primary = widget.contact?['isPrimary'] == true;
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty ||
        _relationship.text.trim().isEmpty ||
        _phone.text.trim().isEmpty) {
      showMessage(context, 'Complete every contact field.');
      return;
    }
    setState(() => _saving = true);
    try {
      await HappifyRepository(
        AppServices.of(context).auth.api,
      ).saveEmergencyContact(
        id: widget.contact?['id']?.toString(),
        name: _name.text.trim(),
        relationship: _relationship.text.trim(),
        phone: _phone.text.trim(),
        isPrimary: _primary,
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
    _name.dispose();
    _relationship.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.contact == null
            ? 'Add emergency contact'
            : 'Edit emergency contact',
      ),
    ),
    body: HappifyPage(
      children: [
        const Text(
          'Choose someone you trust. Happify only opens your device dialer when you choose to call.',
        ),
        const SizedBox(height: 22),
        _ContactField(label: 'Name', controller: _name),
        const SizedBox(height: 16),
        _ContactField(label: 'Relationship', controller: _relationship),
        const SizedBox(height: 16),
        _ContactField(
          label: 'Phone number',
          controller: _phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 14),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Primary contact'),
          subtitle: const Text('Show this person first in your contacts.'),
          value: _primary,
          onChanged: (value) => setState(() => _primary = value),
        ),
        const SizedBox(height: 24),
        HappifyButton(
          label: _saving ? 'Saving...' : 'Save contact',
          onPressed: _saving ? null : _save,
        ),
      ],
    ),
  );
}

class _ContactField extends StatelessWidget {
  const _ContactField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    decoration: InputDecoration(labelText: label),
  );
}
