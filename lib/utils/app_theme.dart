import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary background: deep charcoal to near-black.
  static const Color primaryBackground = Color(0xFF0C0C0C);
  
  // Secondary background glow: midnight blue or smoked violet.
  static const Color accentGlow = Color(0xFF1A1A2E);
  
  // Glass panel tint: translucent white at low opacity.
  static const Color glassColor = Color(0x1AFFFFFF);
  
  // Border highlight: subtle cool-white edge line.
  static const Color glassBorder = Color(0x33FFFFFF);
  
  // Accent colors
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentSilver = Color(0xFFE0E0E0);
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryBackground,
      colorScheme: const ColorScheme.dark(
        primary: accentCyan,
        background: primaryBackground,
        surface: glassColor,
      ),
      textTheme: GoogleFonts.montserratTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: Colors.white70),
          bodyMedium: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
