import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Theme Color Palette - Remapped to Premium Light Mode
  static const Color darkBg = Color(0xFFF8FAFC); // Slate 50 (Background)
  static const Color darkCard = Colors.white; // White (Cards)
  static const Color primaryTeal = Color(0xFF0D9488); // Teal 600 (Primary Brand)
  static const Color secondaryIndigo = Color(0xFF4F46E5); // Indigo 600 (Secondary Brand)
  static const Color accentEmerald = Color(0xFF10B981); // Emerald 500 (Success)
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900 (Primary text)
  static const Color textSecondary = Color(0xFF475569); // Slate 600 (Secondary text)
  static const Color errorRed = Color(0xFFE11D48); // Rose 600 (Errors)
  static const Color borderSlate = Color(0xFFE2E8F0); // Slate 200 (Borders)

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: darkBg,
      primaryColor: primaryTeal,
      colorScheme: const ColorScheme.light(
        primary: primaryTeal,
        secondary: secondaryIndigo,
        surface: darkCard,
        error: errorRed,
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 2,
        shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderSlate, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSlate),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSlate),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryTeal, width: 1.5),
        ),
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.light().textTheme.copyWith(
              titleLarge: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              titleMedium: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
              bodyLarge: const TextStyle(
                fontSize: 16,
                color: textPrimary,
              ),
              bodyMedium: const TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryTeal,
          elevation: 1,
          shadowColor: primaryTeal.withValues(alpha: 0.2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryTeal;
          }
          return null;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
