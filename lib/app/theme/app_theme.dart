import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Membentuk tema Material yang mengikuti palet Pomodoro Belajar.
abstract final class AppTheme {
  static const focus = AppColors.lightPrimary;
  static const shortBreak = AppColors.lightShortBreak;
  static const longBreak = AppColors.lightLongBreak;

  /// Tema terang bernuansa krem dengan permukaan putih.
  static ThemeData light() => _create(Brightness.light);

  /// Tema gelap dengan aksen mode yang tetap terbaca.
  static ThemeData dark() => _create(Brightness.dark);

  static ThemeData _create(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final background = isLight
        ? AppColors.lightBackground
        : AppColors.darkBackground;
    final surface = isLight ? AppColors.lightSurface : AppColors.darkSurface;
    final foreground = isLight ? AppColors.lightText : AppColors.darkText;
    final secondary = isLight
        ? AppColors.lightSecondaryText
        : AppColors.darkSecondaryText;
    final primary = isLight ? AppColors.lightPrimary : AppColors.darkPrimary;
    final outline = isLight ? AppColors.lightOutline : AppColors.darkOutline;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: isLight ? Colors.white : AppColors.darkBackground,
      secondary: isLight
          ? AppColors.lightShortBreak
          : AppColors.darkShortBreak,
      onSecondary: isLight ? Colors.white : AppColors.darkBackground,
      error: isLight ? AppColors.lightError : const Color(0xFFFFB4AB),
      onError: isLight ? Colors.white : AppColors.darkBackground,
      surface: surface,
      onSurface: foreground,
      onSurfaceVariant: secondary,
      outline: outline,
      outlineVariant: outline,
      surfaceContainerHighest: isLight
          ? AppColors.lightSurfaceHigh
          : AppColors.darkSurfaceHigh,
      primaryContainer: isLight
          ? AppColors.lightBlush
          : AppColors.darkPrimaryContainer,
      onPrimaryContainer: foreground,
      secondaryContainer: isLight
          ? AppColors.lightShortBreakContainer
          : AppColors.darkSurfaceHigh,
      onSecondaryContainer: foreground,
      tertiary: isLight
          ? AppColors.lightLongBreak
          : AppColors.darkLongBreak,
      onTertiary: isLight ? Colors.white : AppColors.darkBackground,
      tertiaryContainer: isLight
          ? AppColors.lightLongBreakContainer
          : AppColors.darkSurfaceHigh,
      onTertiaryContainer: foreground,
      surfaceTint: primary,
      inverseSurface: foreground,
      onInverseSurface: background,
      inversePrimary: isLight
          ? AppColors.darkPrimary
          : AppColors.lightPrimary,
      scrim: Colors.black,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: AppTextStyles.body,
      textTheme: AppTextStyles.create(foreground),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.create(foreground).titleMedium,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: outline),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: foreground, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 56),
          textStyle: const TextStyle(
            fontFamily: AppTextStyles.body,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          shape: const StadiumBorder(),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: foreground,
        contentTextStyle: TextStyle(
          fontFamily: AppTextStyles.body,
          color: background,
        ),
        shape: const StadiumBorder(),
      ),
    );
  }
}
