import 'package:flutter/material.dart';

/// Vocab Ishtika colors: soft, bright and friendly.
class AppColors {
  static const purple = Color(0xFF7C4DFF);
  static const deepPurple = Color(0xFF4A2C8F);
  static const coral = Color(0xFFFF7A59);
  static const sunny = Color(0xFFFFC53D);
  static const mint = Color(0xFF2EC4A6);
  static const sky = Color(0xFF3FA9F5);
  static const pink = Color(0xFFFF6FAE);
  static const leaf = Color(0xFF6CC24A);
  static const cream = Color(0xFFFFF8EE);
  static const ink = Color(0xFF2B2440);
  static const soft = Color(0xFF7A7392);
  static const right = Color(0xFF22B573);
  static const tryAgain = Color(0xFFFF9F43);

  static const grade1 = coral;
  static const grade2 = mint;
  static Color forGrade(int g) => g == 1 ? grade1 : grade2;
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.purple,
    primary: AppColors.purple,
    secondary: AppColors.coral,
    surface: Colors.white,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.cream,
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 56),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}
