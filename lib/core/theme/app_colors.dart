import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF176B68);
  static const primaryDark = Color(0xFF124F4D);
  static const accent = Color(0xFFD8F36A);

  static const canvas = Color(0xFFF4F7F5);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF172B3A);
  static const mutedInk = Color(0xFF52636B);
  static const border = Color(0xFFDCE5E1);
  static const surfaceTint = Color(0xFFE9F0ED);

  static const success = Color(0xFF237A4B);
  static const warning = Color(0xFF9A5A00);
  static const info = Color(0xFF1769AA);
  static const error = Color(0xFFB42332);
  static const overtime = Color(0xFF6941A5);

  static const darkCanvas = Color(0xFF111B20);
  static const darkSurface = Color(0xFF1D2B31);
  static const darkInk = Color(0xFFF2F6F4);
  static const darkMutedInk = Color(0xFFB4C2C0);
  static const darkBorder = Color(0xFF34454B);

  static const brandGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
