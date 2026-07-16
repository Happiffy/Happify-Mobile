import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class QuokkaBadge extends StatelessWidget {
  const QuokkaBadge({super.key, this.size = 132, this.calm = false});

  final double size;
  final bool calm;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: calm
          ? 'A calm Quokka mascot keeping you company'
          : 'Happify’s Quokka mascot',
      image: true,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * .12),
        decoration: BoxDecoration(
          color: calm ? const Color(0xFFDCE7D6) : const Color(0xFFF7E0C7),
          shape: BoxShape.circle,
        ),
        child: SvgPicture.asset(
          'assets/mascot/quokka.svg',
          semanticsLabel: 'Quokka',
        ),
      ),
    );
  }
}
