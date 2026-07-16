import 'package:flutter/material.dart';
import 'package:sign_in_button/sign_in_button.dart';

import '../theme/happify_colors.dart';
import '../theme/happify_theme.dart';

class GoogleAuthButton extends StatelessWidget {
  const GoogleAuthButton({
    required this.label,
    required this.loading,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool loading;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _PressableShadow(
        enabled: !loading,
        shadowColor: const Color(0xFFD9D9D9),
        child: IgnorePointer(
          ignoring: loading,
          child: Semantics(
            button: true,
            enabled: !loading,
            label: loading ? 'Google sign-in loading' : label,
            child: SignInButtonBuilder(
              text: loading ? 'Loading...' : label,
              onPressed: onPressed,
              width: constraints.maxWidth,
              height: 56,
              elevation: 0,
              backgroundColor: Colors.white,
              textColor: HappifyColors.ink,
              textStyle: const TextStyle(
                color: HappifyColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HappifyRadii.button),
                side: const BorderSide(color: HappifyColors.line, width: 2),
              ),
              image: const Image(
                image: AssetImage(
                  'assets/logos/google_light.png',
                  package: 'sign_in_button',
                ),
                height: 36,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HappifyButton extends StatelessWidget {
  const HappifyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.leading,
    this.background = HappifyColors.green,
    this.foreground = Colors.white,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? leading;
  final Color background;
  final Color foreground;

  Color get _shadowColor {
    if (background == Colors.white) return const Color(0xFFD9D9D9);
    if (background == HappifyColors.green) return HappifyColors.greenDark;
    if (background == HappifyColors.blue) return HappifyColors.blueDark;
    if (background == HappifyColors.purple) return HappifyColors.purpleDark;
    if (background == HappifyColors.gold) return HappifyColors.goldDark;
    if (background == HappifyColors.red) return HappifyColors.redDark;
    if (background == HappifyColors.orange) return HappifyColors.orangeDark;
    return background;
  }

  @override
  Widget build(BuildContext context) {
    return _PressableShadow(
      enabled: onPressed != null,
      shadowColor: _shadowColor,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        label: label,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: onPressed,
            icon:
                leading ??
                (icon == null ? const SizedBox.shrink() : Icon(icon, size: 20)),
            label: Text(label),
            style: FilledButton.styleFrom(
              backgroundColor: background,
              foregroundColor: foreground,
              disabledBackgroundColor: HappifyColors.surfaceMuted,
              disabledForegroundColor: HappifyColors.inkMuted,
              elevation: 0,
              shadowColor: Colors.transparent,
              side: background == Colors.white
                  ? const BorderSide(color: HappifyColors.line, width: 2)
                  : BorderSide.none,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: .1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HappifyRadii.button),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PressableShadow extends StatefulWidget {
  const _PressableShadow({
    required this.child,
    required this.enabled,
    required this.shadowColor,
  });

  final Widget child;
  final bool enabled;
  final Color shadowColor;

  @override
  State<_PressableShadow> createState() => _PressableShadowState();
}

class _PressableShadowState extends State<_PressableShadow> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 61,
      child: Listener(
        onPointerDown: (_) => _setPressed(true),
        onPointerUp: (_) => _setPressed(false),
        onPointerCancel: (_) => _setPressed(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _pressed ? 5 : 0, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HappifyRadii.button),
            boxShadow: widget.enabled && !_pressed
                ? [
                    BoxShadow(
                      color: widget.shadowColor,
                      offset: const Offset(0, 5),
                      blurRadius: 0,
                    ),
                  ]
                : const [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
