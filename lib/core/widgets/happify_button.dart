import 'package:flutter/material.dart';

import '../theme/happify_colors.dart';

class HappifyButton extends StatelessWidget {
  const HappifyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.background = HappifyColors.green,
    this.foreground = Colors.white,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 20),
          label: Text(label),
          style: FilledButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            disabledBackgroundColor: HappifyColors.inkSoft,
            elevation: 4,
            shadowColor: background == HappifyColors.green
                ? HappifyColors.greenDark
                : background,

            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}
