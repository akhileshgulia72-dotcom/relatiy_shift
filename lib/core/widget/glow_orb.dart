import 'package:flutter/material.dart';

class GlowOrb extends StatelessWidget {
  const GlowOrb({
    super.key,
    this.size = 220,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Color(0xAA00D4FF),
              Color(0x668A2BE2),
              Color(0x2200D4FF),
              Colors.transparent,
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
        ),
      ),
    );
  }
}