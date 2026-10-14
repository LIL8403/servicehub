import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Plus Jakarta Sans';

  static TextStyle display = GoogleFonts.plusJakartaSans(
    fontSize: 36,
    height: 44 / 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.02,
  );

  static TextStyle h1 = GoogleFonts.plusJakartaSans(
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.015,
  );

  static TextStyle h2 = GoogleFonts.plusJakartaSans(
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.01,
  );

  static TextStyle h3 = GoogleFonts.plusJakartaSans(
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.0,
  );

  static TextStyle h4 = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.0,
  );

  static TextStyle bodyLarge = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.0,
  );

  static TextStyle bodyMedium = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.0,
  );

  static TextStyle bodySmall = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.01,
  );

  static TextStyle caption = GoogleFonts.plusJakartaSans(
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.02,
  );

  static TextStyle overline = GoogleFonts.plusJakartaSans(
    fontSize: 10,
    height: 14 / 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.08,
  );

  static TextTheme textTheme(Color color) {
    return TextTheme(
      displayMedium: display.copyWith(color: color),
      headlineLarge: h1.copyWith(color: color),
      headlineMedium: h2.copyWith(color: color),
      titleLarge: h3.copyWith(color: color),
      titleMedium: h4.copyWith(color: color),
      bodyLarge: bodyLarge.copyWith(color: color),
      bodyMedium: bodyMedium.copyWith(color: color),
      bodySmall: bodySmall.copyWith(color: color),
      labelSmall: caption.copyWith(color: color),
    );
  }
}
