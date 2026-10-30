import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: const Color(0xFF050816),

    textTheme: TextTheme(
      displayLarge: GoogleFonts.orbitron(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),

      headlineLarge: GoogleFonts.orbitron(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),

      headlineMedium: GoogleFonts.orbitron(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),

      bodyLarge: GoogleFonts.exo2(
        fontSize: 18,
        color: Colors.white,
      ),

      bodyMedium: GoogleFonts.exo2(
        fontSize: 16,
        color: Colors.white70,
      ),
    ),
  );
}