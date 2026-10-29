import 'package:flutter/material.dart';

const Color appPrimaryColor = Color(0xFF172B3A);
const Color appPrimaryDarkColor = Color(0xFF10212D);
const Color appAccentColor = Color(0xFFB7F36B);
const Color appBackgroundColor = Color(0xFFF5F4F0);
const Color appTextColor = Color(0xFF172B3A);
const Color appSecondaryTextColor = Color(0xFF70808C);
const Color appCardBorderColor = Color(0xFFE7E6DF);

ThemeData buildAppTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: appPrimaryColor,
    onPrimary: Colors.white,
    secondary: appAccentColor,
    onSecondary: appPrimaryColor,
    error: Color(0xFFE25D5D),
    onError: Colors.white,
    surface: Colors.white,
    onSurface: appTextColor,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: appBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: appBackgroundColor,
      foregroundColor: appTextColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: appTextColor,
        fontFamily: 'Poppins',
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: appCardBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: appCardBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: appPrimaryColor, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: appPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
