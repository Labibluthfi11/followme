import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

abstract final class FollowMeTokens {
  static const primary = AppColors.primary;
  static const primaryDark = AppColors.primaryDark;
  static const accent = AppColors.accent;
  static const canvas = AppColors.canvas;
  static const surface = AppColors.surface;
  static const ink = AppColors.ink;
  static const mutedInk = AppColors.mutedInk;
  static const border = AppColors.border;

  static const present = AppColors.success;
  static const late = AppColors.warning;
  static const leave = AppColors.info;
  static const absent = AppColors.error;
  static const overtime = AppColors.overtime;

  static const space1 = AppSpacing.xxs;
  static const space2 = AppSpacing.xs;
  static const space3 = AppSpacing.sm;
  static const space4 = AppSpacing.md;
  static const space5 = AppSpacing.lg;
  static const space6 = AppSpacing.xl;
  static const radiusSmall = AppRadius.small;
  static const radiusMedium = AppRadius.large;
  static const radiusLarge = AppRadius.extraLarge;
}

class FollowMeThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedMode = preferences.getString('followme_theme_mode');
    if (savedMode == ThemeMode.dark.name) {
      _mode = ThemeMode.dark;
      notifyListeners();
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    _mode = enabled ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('followme_theme_mode', _mode.name);
  }
}

const Color appPrimaryColor = AppColors.primary;
const Color appPrimaryDarkColor = AppColors.primaryDark;
const Color appAccentColor = AppColors.accent;
const Color appBackgroundColor = AppColors.canvas;
const Color appTextColor = AppColors.ink;
const Color appSecondaryTextColor = AppColors.mutedInk;
const Color appCardBorderColor = AppColors.border;

ThemeData buildAppTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFDCEDE8),
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.accent,
    onSecondary: AppColors.ink,
    secondaryContainer: Color(0xFFEDF5C8),
    onSecondaryContainer: AppColors.ink,
    error: AppColors.error,
    onError: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    surfaceContainerHighest: AppColors.canvas,
    onSurfaceVariant: AppColors.mutedInk,
    outline: AppColors.border,
    outlineVariant: AppColors.border,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.ink,
    onInverseSurface: Colors.white,
    inversePrimary: Color(0xFF82C9C1),
  );

  return _buildTheme(
    colorScheme,
    canvas: AppColors.canvas,
    textColor: AppColors.ink,
    mutedColor: AppColors.mutedInk,
    borderColor: AppColors.border,
  );
}

ThemeData buildAppDarkTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF82C9C1),
    onPrimary: Color(0xFF073B38),
    primaryContainer: Color(0xFF124F4D),
    onPrimaryContainer: Color(0xFFD1F0EC),
    secondary: AppColors.accent,
    onSecondary: AppColors.ink,
    secondaryContainer: Color(0xFF39451A),
    onSecondaryContainer: Color(0xFFEDF5C8),
    error: Color(0xFFFF7B82),
    onError: Color(0xFF5F1018),
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkInk,
    surfaceContainerHighest: AppColors.darkCanvas,
    onSurfaceVariant: AppColors.darkMutedInk,
    outline: AppColors.darkBorder,
    outlineVariant: AppColors.darkBorder,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.darkInk,
    onInverseSurface: AppColors.darkCanvas,
    inversePrimary: AppColors.primary,
  );

  return _buildTheme(
    colorScheme,
    canvas: AppColors.darkCanvas,
    textColor: AppColors.darkInk,
    mutedColor: AppColors.darkMutedInk,
    borderColor: AppColors.darkBorder,
  );
}

ThemeData _buildTheme(
  ColorScheme colorScheme, {
  required Color canvas,
  required Color textColor,
  required Color mutedColor,
  required Color borderColor,
}) {
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.medium),
  );
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.small),
    borderSide: BorderSide(color: borderColor),
  );
  final textTheme = AppTextStyles.textTheme(
    textColor: textColor,
    mutedColor: mutedColor,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: canvas,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: canvas,
      foregroundColor: textColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: textTheme.titleMedium,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 3,
      ),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        borderSide: BorderSide(color: colorScheme.error, width: 1.5),
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(color: mutedColor),
      labelStyle: textTheme.bodyMedium?.copyWith(color: mutedColor),
      errorStyle: textTheme.bodySmall?.copyWith(color: colorScheme.error),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        minimumSize: const Size.fromHeight(48),
        shape: shape,
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: borderColor),
        shape: shape,
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        shape: shape,
        textStyle: textTheme.labelLarge,
      ),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        side: BorderSide(color: borderColor),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      modalBackgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: mutedColor.withValues(alpha: 0.35),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.extraLarge),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onInverseSurface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: borderColor,
      thickness: 1,
      space: AppSpacing.md,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: colorScheme.primary.withValues(alpha: 0.12),
      circularTrackColor: colorScheme.primary.withValues(alpha: 0.12),
    ),
  );
}
