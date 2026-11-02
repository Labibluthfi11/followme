import 'package:flutter/material.dart';

abstract final class FollowMeDesign {
  static const Color primary = Color(0xFF2F5BEA);
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color deepSpace = Color(0xFF0A1030);
  static const Color violet = Color(0xFF7C3AED);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color success = Color(0xFF15803D);
  static const Color successLight = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFC2410C);
  static const Color warningDark = Color(0xFF9A3412);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color warningText = Color(0xFF92400E);
  static const Color background = Color(0xFFF5F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color border = Color(0xFFCBD5E1);
  static const Color greenBadgeBg = Color(0xFFDCFCE7);
  static const Color greenBadgeText = Color(0xFF166534);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF10B981), success],
  );

  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFF59E0B), warning],
  );

  static const LinearGradient textGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [cyan, successLight],
  );

  static const BorderRadius radius14 = BorderRadius.all(Radius.circular(14));
  static const BorderRadius radius16 = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radius20 = BorderRadius.all(Radius.circular(20));
  static const BorderRadius radius22 = BorderRadius.all(Radius.circular(22));
  static const BorderRadius radius30 = BorderRadius.all(Radius.circular(30));

  static const EdgeInsets padding8 = EdgeInsets.all(8);
  static const EdgeInsets padding12 = EdgeInsets.all(12);
  static const EdgeInsets padding16 = EdgeInsets.all(16);
  static const EdgeInsets padding20 = EdgeInsets.all(20);

  static TextStyle get titleLarge => const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
    color: textPrimary,
    height: 1.1,
  );

  static TextStyle get titleMedium => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    color: textPrimary,
  );

  static TextStyle get bodyLarge => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get bodyMedium => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static TextStyle get labelStrong => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
    color: textSecondary,
  );
}
