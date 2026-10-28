import 'package:flutter/material.dart';

const Color appPrimaryColor = Color(0xFF279DE0);
const Color appPrimaryDarkColor = Color(0xFF1679BA);
const Color appBackgroundColor = Color(0xFFF2F4F7);
const Color appTextColor = Color(0xFF263238);
const Color appSecondaryTextColor = Color(0xFF8A939B);
const Color appCardBorderColor = Color(0xFFE9EDF2);

ThemeData buildAppTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: appPrimaryColor,
    onPrimary: Colors.white,
    secondary: Color(0xFF62C6B4),
    onSecondary: Colors.white,
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
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: appCardBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: appCardBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: appPrimaryColor, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: appPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
