import 'package:flutter/material.dart';

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
      builder: (context, constraints) => IgnorePointer(
        ignoring: loading,
        child: Semantics(
          button: true,
          enabled: !loading,
          label: loading ? 'Google sign-in loading' : label,
          child: SizedBox(
            width: constraints.maxWidth,
            height: 56,
            child: OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: HappifyColors.ink,
                side: const BorderSide(color: HappifyColors.line, width: 2),
                backgroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(HappifyRadii.button),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              child: loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _GoogleMark(),
                        const SizedBox(width: 12),
                        Text(label),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      width: 22,
      child: CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -.42,
      1.28,
      true,
      paint,
    );
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      .86,
      1.6,
      true,
      paint,
    );
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.46,
      1.25,
      true,
      paint,
    );
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.71,
      2.15,
      true,
      paint,
    );
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * .48, paint);
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(center.dx, center.dy - radius * .18, radius, radius * .36),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

  @override
  Widget build(BuildContext context) {
    return Semantics(
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
    );
  }
}

class HappifyIconButton extends StatelessWidget {
  const HappifyIconButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: IconButton(onPressed: onPressed, icon: Icon(icon)),
    );
  }
}
