import 'package:flutter/material.dart';

class AppTheme {
  static const Color defaultPrimaryColor = Color(0xFF2563EB); // Royal Blue

  static const List<Color> availableColors = [
    Color(0xFF2563EB), // Azul Royal
    Color(0xFF059669), // Esmeralda
    Color(0xFF7C3AED), // Violeta
    Color(0xFFDC2626), // Carmesí
    Color(0xFFD97706), // Ámbar
    Color(0xFF0891B2), // Cian
    Color(0xFF4F46E5), // Índigo
    Color(0xFFBE185D), // Rosa
  ];

  static ThemeData lightTheme(ColorScheme? lightColorScheme, Color seedColor) {
    final scheme = lightColorScheme ??
        ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  static ThemeData darkTheme(ColorScheme? darkColorScheme, Color seedColor) {
    final scheme = darkColorScheme ??
        ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

