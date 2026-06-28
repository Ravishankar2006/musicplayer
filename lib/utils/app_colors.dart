import 'package:flutter/material.dart';

class AppColors {
  // Base Palette: Matte Charcoal & Graphite
  static const Color background = Color(0xFF0B0D10);
  static const Color surface = Color(0xFF14181D);
  static const Color elevatedSurface = Color(0xFF1B2027);
  
  // Text Colors: Crisp & Muted
  static const Color primaryText = Color(0xFFF3F5F7);
  static const Color secondaryText = Color(0xFF98A2B3);
  
  // Decorative
  static const Color border = Color(0x1AFFFFFF); // White at 10%
  static const Color shadow = Color(0x40000000); // Soft black shadow
  
  // Dynamic Accent Logic
  static Color getDesaturatedAccent(Color source) {
    final hsl = HSLColor.fromColor(source);
    return hsl
        .withSaturation((hsl.saturation - 0.3).clamp(0.0, 1.0))
        .withLightness((hsl.lightness).clamp(0.4, 0.7))
        .toColor();
  }
}
