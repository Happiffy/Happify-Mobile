import 'package:flutter/material.dart';

import '../theme/happify_colors.dart';
import 'happify_emoji.dart';

class HappifyAvatar extends StatelessWidget {
  const HappifyAvatar({
    required this.size,
    this.imageUrl,
    this.fallbackName,
    super.key,
  });

  final double size;
  final String? imageUrl;
  final String? fallbackName;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final fallback = fallbackName?.trim();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: HappifyColors.greenSurface,
        shape: BoxShape.circle,
        border: Border.all(color: HappifyColors.line, width: 2),
        boxShadow: const [
          BoxShadow(
            color: HappifyColors.shadow,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null || url.isEmpty
          ? _AvatarFallback(size: size, name: fallback)
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _AvatarFallback(size: size, name: fallback),
            ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.size, required this.name});

  final double size;
  final String? name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: (name == null || name!.isEmpty)
          ? HappifyEmoji.profile(size: size * .58)
          : Text(
              name!.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: HappifyColors.greenDark,
                fontSize: size * .38,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}

class HappifyMascot extends StatelessWidget {
  const HappifyMascot({super.key, this.size = 132, this.semanticLabel});

  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      child: Image.asset(
        'assets/mascot/happify-app-icon.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        excludeFromSemantics: semanticLabel == null,
      ),
    );
  }
}

class QuokkaBadge extends StatelessWidget {
  const QuokkaBadge({super.key, this.size = 132, this.calm = false});

  final double size;
  final bool calm;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .08),
      decoration: BoxDecoration(
        color: calm ? HappifyColors.greenSurface : const Color(0xFFFFF8DF),
        borderRadius: BorderRadius.circular(size * .28),
        border: Border.all(color: HappifyColors.line, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFD9D9D9),
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: const HappifyMascot(semanticLabel: 'Happify mascot'),
    );
  }
}
