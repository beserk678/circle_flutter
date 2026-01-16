import 'package:flutter/material.dart';
import 'design_tokens.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: DesignTokens.primaryColor,
    scaffoldBackgroundColor: DesignTokens.lightBackgroundColor,
    colorScheme: const ColorScheme.light(
      primary: DesignTokens.primaryColor,
      secondary: DesignTokens.secondaryColor,
      surface: DesignTokens.lightSurfaceColor,
      error: DesignTokens.errorColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: DesignTokens.lightBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: DesignTokens.lightTextPrimary),
      titleTextStyle: TextStyle(
        color: DesignTokens.lightTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardTheme(
      color: DesignTokens.lightCardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DesignTokens.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacing16,
          vertical: DesignTokens.spacing12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: DesignTokens.primaryColor),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DesignTokens.lightInputFillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        borderSide: const BorderSide(color: DesignTokens.lightBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        borderSide: const BorderSide(color: DesignTokens.lightBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        borderSide: const BorderSide(
          color: DesignTokens.primaryColor,
          width: 2,
        ),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: DesignTokens.primaryColor,
    scaffoldBackgroundColor: DesignTokens.darkBackgroundColor,
    colorScheme: const ColorScheme.dark(
      primary: DesignTokens.primaryColor,
      secondary: DesignTokens.secondaryColor,
      surface: DesignTokens.darkSurfaceColor,
      error: DesignTokens.errorColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: DesignTokens.darkBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: DesignTokens.darkTextPrimary),
      titleTextStyle: TextStyle(
        color: DesignTokens.darkTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardTheme(
      color: DesignTokens.darkCardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DesignTokens.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacing16,
          vertical: DesignTokens.spacing12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: DesignTokens.primaryColor),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DesignTokens.darkInputFillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        borderSide: const BorderSide(color: DesignTokens.darkBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        borderSide: const BorderSide(color: DesignTokens.darkBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        borderSide: const BorderSide(
          color: DesignTokens.primaryColor,
          width: 2,
        ),
      ),
    ),
  );
}
