import 'package:flutter/material.dart';

/// Palet aplikasi terpusat agar mode terang dan gelap tetap konsisten.
abstract final class AppColors {
  static const lightBackground = Color(0xFFFAF6F0);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceHigh = Color(0xFFF4EEE7);
  static const lightPrimary = Color(0xFFC8372D);
  static const lightPrimaryDark = Color(0xFF9E2A22);
  static const lightBlush = Color(0xFFFBE9E6);
  static const lightText = Color(0xFF1C1917);
  static const lightSecondaryText = Color(0xFF625C57);
  static const lightOutline = Color(0xFFE8E1D8);
  static const lightError = Color(0xFFB3261E);
  static const lightShortBreak = Color(0xFF55785B);
  static const lightShortBreakContainer = Color(0xFFE4EDE3);
  static const lightLongBreak = Color(0xFF496B85);
  static const lightLongBreakContainer = Color(0xFFE3EBF1);

  static const darkBackground = Color(0xFF141110);
  static const darkSurface = Color(0xFF1F1B19);
  static const darkSurfaceHigh = Color(0xFF2A2522);
  static const darkPrimary = Color(0xFFFF7B6B);
  static const darkPrimaryContainer = Color(0xFF5C1B15);
  static const darkText = Color(0xFFF5EFE8);
  static const darkSecondaryText = Color(0xFFC0B7AE);
  static const darkOutline = Color(0xFF3A3330);
  static const darkShortBreak = Color(0xFF8DB391);
  static const darkLongBreak = Color(0xFF8FB0CC);
}
