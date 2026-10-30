import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LevelHeader extends StatelessWidget {
  final String mission;
  final String title;
  final String description;

  const LevelHeader({
    super.key,
    required this.mission,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          top: 70,
          left: 20,
          right: 20,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 360,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 22,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xCC13203A),
                  Color(0xDD0B1120),
                ],
              ),
              border: Border.all(
                color: Colors.cyanAccent.withOpacity(.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(.25),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                /// Mission Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(.12),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.cyanAccent.withOpacity(.5),
                    ),
                  ),
                  child: Text(
                    mission,
                    style: GoogleFonts.orbitron(
                      color: Colors.cyanAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                /// Mission Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 14),

                /// Cyan Divider
                Container(
                  width: 90,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(.8),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /// Story Text
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.exo2(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}