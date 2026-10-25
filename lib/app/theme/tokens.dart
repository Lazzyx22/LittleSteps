import 'package:flutter/material.dart';

abstract final class Tokens {
  static const double spacing = 20,
      radius = 28,
      preschoolControl = 96,
      schoolControl = 64,
      icon = 44;
  static const Duration animation = Duration(milliseconds: 220);
  static ThemeData theme() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff28766e)),
    scaffoldBackgroundColor: const Color(0xfffff8ed),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 20),
      bodyMedium: TextStyle(fontSize: 18),
      titleLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 64),
        textStyle: const TextStyle(fontSize: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    ),
  );
}
