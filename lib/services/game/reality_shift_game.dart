import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LevelHeader extends StatelessWidget {
  const LevelHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 24, top: 32, right: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEVEL NUMBER
            Center(
              child: Text(
                "MISSION 01",
                style: TextStyle(
                  color: const Color(0xFFFFD54F),
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: Colors.black87,
                      blurRadius: 12,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // TITLE
            Padding(
              padding: const EdgeInsets.only(top: 20.0, left: 10),
              child: Center(
                child: Text(
                  "🌙 Return the Moon",
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // DESCRIPTION
            Text(
              "Drag the moon into the glowing portal\n"
              "to restore the night sky.",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 17,
                height: 1.4,
                shadows: [
                  Shadow(
                    color: Colors.black87,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
