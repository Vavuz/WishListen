import 'package:flutter/material.dart';

final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.dark);

ThemeData buildLightTheme() {
  const brand = Color(0xFF1DB954);
  const lightCard = Color.fromARGB(255, 196, 196, 196);
  const lightSurface = Color(0xFFF9F9F9);

  const colorScheme = ColorScheme.light(
    primary: brand,
    secondary: brand,
    surface: lightSurface,
    tertiary: Color.fromARGB(255, 133, 131, 131),
    onPrimary: Colors.white,
    onSurface: Colors.black87,
    onBackground: Colors.black87,
  );

  return ThemeData(
    useMaterial3: false,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: brand,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: true,
    ),
    cardColor: lightCard,
    dialogTheme: const DialogTheme(
      backgroundColor: lightSurface,
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(color: Colors.black87, fontSize: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.tertiary,
      labelStyle: const TextStyle(color: Colors.black87),
      deleteIconColor: Colors.black54,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
      bodySmall: TextStyle(color: Colors.black54),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: brand),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: brand, width: 2),
      ),
      hintStyle: const TextStyle(color: Colors.black45),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: brand,
      foregroundColor: Colors.white,
    ),
  );
}

ThemeData buildDarkTheme() {
  const darkBackground = Color(0xFF191414);
  const darkSurface = Color(0xFF121212);
  const darkCard = Color.fromARGB(255, 41, 41, 41);
  const brand = Color(0xFF1DB954);

  const colorScheme = ColorScheme.dark(
    primary: brand,
    secondary: brand,
    surface: darkSurface,
    background: darkBackground,
    tertiary: Color.fromARGB(255, 0, 0, 0),
    onPrimary: Colors.white,
    onSurface: Colors.white,
    onBackground: Colors.white,
  );

  return ThemeData(
    useMaterial3: false,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: brand,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: true,
    ),
    cardColor: darkCard,
    dialogTheme: const DialogTheme(
      backgroundColor: darkSurface,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.tertiary,
      labelStyle: const TextStyle(color: Colors.white),
      deleteIconColor: Colors.white70,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
      bodySmall: TextStyle(color: Colors.white60),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: brand,
      foregroundColor: Colors.white,
    ),
  );
}