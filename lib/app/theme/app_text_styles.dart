import 'package:flutter/material.dart';

/// Gaya huruf Inter lokal menjaga tampilan tetap konsisten saat offline.
abstract final class AppTextStyles {
  static const display = 'Inter';
  static const body = 'Inter';

  /// Membuat tema teks display dan isi dengan keluarga font Inter.
  static TextTheme create(Color color) => TextTheme(
    displayLarge: TextStyle(
      fontFamily: display,
      fontSize: 44,
      fontWeight: FontWeight.w900,
      height: 0.96,
      color: color,
    ),
    headlineLarge: TextStyle(
      fontFamily: display,
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: color,
    ),
    headlineMedium: TextStyle(
      fontFamily: display,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: color,
    ),
    titleLarge: TextStyle(
      fontFamily: body,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: color,
    ),
    titleMedium: TextStyle(
      fontFamily: body,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: color,
    ),
    bodyLarge: TextStyle(
      fontFamily: body,
      fontSize: 16,
      color: color,
    ),
    bodyMedium: TextStyle(
      fontFamily: body,
      fontSize: 14,
      color: color,
    ),
    bodySmall: TextStyle(
      fontFamily: body,
      fontSize: 12,
      color: color,
    ),
    labelLarge: TextStyle(
      fontFamily: body,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: color,
    ),
  );
}
