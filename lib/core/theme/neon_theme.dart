import 'package:flutter/material.dart';

class NeonTheme {
  // Colors
  static const Color primary = Color(0xFFcabeff);
  static const Color onPrimary = Color(0xFF30009b);
  static const Color primaryContainer = Color(0xFF937dff);
  static const Color onPrimaryContainer = Color(0xFF2a0088);
  
  static const Color secondary = Color(0xFF41e878);
  static const Color onSecondary = Color(0xFF003916);
  static const Color secondaryContainer = Color(0xFF04cb60);
  
  static const Color surface = Color(0xFF051424);
  static const Color surfaceBright = Color(0xFF2c3a4c);
  static const Color surfaceContainerLowest = Color(0xFF010f1f);
  static const Color surfaceContainerLow = Color(0xFF0d1c2d);
  static const Color surfaceContainer = Color(0xFF122131);
  static const Color surfaceContainerHigh = Color(0xFF1c2b3c);
  static const Color onSurface = Color(0xFFd4e4fa);
  static const Color onSurfaceVariant = Color(0xFFc9c4d8);
  
  static const Color background = Color(0xFF051424);
  static const Color onBackground = Color(0xFFd4e4fa);
  
  static const Color error = Color(0xFFffb4ab);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000a);

  // Theme Data
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        background: background,
        onBackground: onBackground,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        surfaceVariant: surfaceContainerHigh,
      ),
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -0.04 * 48, color: onBackground),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.02 * 32, color: onBackground),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: onBackground),
        titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: onSurface),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: onBackground),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: onSurfaceVariant),
        labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05 * 12, color: onBackground),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary),
        ),
      ),
    );
  }
}
