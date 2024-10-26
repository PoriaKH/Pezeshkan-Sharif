import 'package:flutter/material.dart';

ThemeData generateTheme(ThemeMode themeData) {
  final theme =
      themeData == ThemeMode.light ? ThemeData.light() : ThemeData.dark();
  final buttonBorderRadius = BorderRadius.circular(4);

  return theme.copyWith(
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: buttonBorderRadius),
        textStyle: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: buttonBorderRadius),
        textStyle: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: buttonBorderRadius),
        textStyle: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  );
}
