import 'package:flutter/material.dart';

class GlowBackground extends StatelessWidget {
  const GlowBackground({
    super.key,
    this.backgroundColor = const Color(0xFF0A1030),
    this.glows = const [
      Color(0xFF7C3AED),
      Color(0xFF22D3EE),
      Color(0xFF2F5BEA),
    ],
  });

  final Color backgroundColor;
  final List<Color> glows;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [backgroundColor, const Color(0xFF0B132d)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              left: -60,
              child: _orb(glows[0], 220),
            ),
            Positioned(
              top: 80,
              right: -50,
              child: _orb(glows[1], 260),
            ),
            Positioned(
              bottom: -90,
              left: -60,
              child: _orb(glows[2], 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.35),
      ),
    );
  }
}
