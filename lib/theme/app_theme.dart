import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Futuristic Colors
  static const Color deepNavy = Color(0xFF060B19);
  static const Color royalBlue = Color(0xFF1D4ED8);
  static const Color electricCyan = Color(0xFF00E5FF);
  static const Color softViolet = Color(0xFF8B5CF6);
  static const Color silver = Color(0xFF94A3B8);
  
  // Status Colors
  static const Color safeGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color criticalRed = Color(0xFFEF4444);
  
  // Surface Colors
  static const Color lightSurface = Color(0xFFF8FAFC);
  static const Color darkSurface = Color(0xFF0F172A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: royalBlue,
        brightness: Brightness.light,
        primary: royalBlue,
        secondary: electricCyan,
        surface: lightSurface,
      ),
      scaffoldBackgroundColor: lightSurface,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: _textTheme(Colors.black87, royalBlue),
      cardTheme: _cardTheme(Colors.white),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: deepNavy,
        brightness: Brightness.dark,
        primary: electricCyan,
        secondary: softViolet,
        surface: darkSurface,
      ),
      scaffoldBackgroundColor: deepNavy,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: _textTheme(Colors.white.withValues(alpha: 0.9), Colors.white),
      cardTheme: _cardTheme(darkSurface),
    );
  }

  static TextTheme _textTheme(Color bodyColor, Color titleColor) {
    return TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: titleColor, letterSpacing: -1.0),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: titleColor, letterSpacing: -0.5),
      titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: titleColor, letterSpacing: -0.3),
      titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: titleColor, letterSpacing: -0.2),
      bodyLarge: TextStyle(fontSize: 18, color: bodyColor, letterSpacing: 0.1),
      bodyMedium: TextStyle(fontSize: 16, color: bodyColor, letterSpacing: 0.1),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: electricCyan),
    );
  }

  static CardThemeData _cardTheme(Color surfaceColor) {
    return CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: electricCyan.withValues(alpha: 0.1), width: 1),
      ),
      color: surfaceColor.withValues(alpha: 0.5),
    );
  }
}
