import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTextStyles {
  static TextTheme textTheme({
    required Color textColor,
    required Color mutedColor,
  }) {
    final base = GoogleFonts.poppinsTextTheme();

    return base.copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32,
        height: 1.15,
        fontWeight: FontWeight.w800,
        color: textColor,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w800,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: mutedColor,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        height: 1.35,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: mutedColor,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 10,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: mutedColor,
      ),
    );
  }
}
