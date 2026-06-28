import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:musicplayer/utils/app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        onSurface: AppColors.primaryText,
        primary: AppColors.primaryText,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryText,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText,
          letterSpacing: -0.2,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: AppColors.primaryText,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.secondaryText,
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryText,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.secondaryText,
        ),
      ),
    );
  }
}
