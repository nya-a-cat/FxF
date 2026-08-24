import 'package:flutter/material.dart';

class FxFColors {
  static const bg = Color(0xFFF2FBFF);
  static const ink = Color(0xFF123B58);
  static const muted = Color(0xFF6F8A9F);
  static const primary = Color(0xFF24C7D8);
  static const primaryDark = Color(0xFF0B8FA8);
  static const positive = Color(0xFF10B89A);
  static const negative = Color(0xFFFF6E7D);
  static const warning = Color(0xFFFFB84A);
  static const line = Color(0xFFDDECF4);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: FxFColors.primary, brightness: Brightness.light);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: FxFColors.bg,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: FxFColors.ink, fontWeight: FontWeight.w800),
      headlineMedium: TextStyle(color: FxFColors.ink, fontWeight: FontWeight.w800),
      titleLarge: TextStyle(color: FxFColors.ink, fontWeight: FontWeight.w800),
      titleMedium: TextStyle(color: FxFColors.ink, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(color: FxFColors.ink),
      bodyMedium: TextStyle(color: FxFColors.muted),
    ),
    navigationBarTheme: const NavigationBarThemeData(backgroundColor: Colors.white, indicatorColor: Color(0xFFD5F6FA)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: .86),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
    ),
  );
}
