import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium dark theme for the Smart Light Monitor app.
///
/// Design system built around a deep navy background with amber/gold
/// accents for "light on" states and cool blue-grey for "light off".
class AppTheme {
  AppTheme._();

  // ─── Core Colors ─────────────────────────────────────────

  /// Deep navy background
  static const Color background = Color(0xFF0D1117);

  /// Slightly lighter surface for cards
  static const Color surface = Color(0xFF161B22);

  /// Card/container overlay
  static const Color cardColor = Color(0xFF1C2333);

  /// Subtle borders
  static const Color border = Color(0xFF30363D);

  /// Primary text
  static const Color textPrimary = Color(0xFFE6EDF3);

  /// Secondary text
  static const Color textSecondary = Color(0xFF8B949E);

  /// Muted text
  static const Color textMuted = Color(0xFF484F58);

  // ─── Accent Colors ───────────────────────────────────────

  /// Amber/gold for "light on" — warm glow
  static const Color lightOn = Color(0xFFFFB020);

  /// Light-on glow (softer, for backgrounds)
  static const Color lightOnGlow = Color(0x33FFB020);

  /// Cool blue for "light off"
  static const Color lightOff = Color(0xFF58A6FF);

  /// Light-off glow
  static const Color lightOffGlow = Color(0x3358A6FF);

  /// Success green
  static const Color success = Color(0xFF3FB950);

  /// Error/warning red
  static const Color error = Color(0xFFF85149);

  /// Nudge/action purple
  static const Color accent = Color(0xFFBC8CFF);

  // ─── Gradients ───────────────────────────────────────────

  static const LinearGradient lightOnGradient = LinearGradient(
    colors: [Color(0xFFFFB020), Color(0xFFFF6B35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightOffGradient = LinearGradient(
    colors: [Color(0xFF58A6FF), Color(0xFF1F6FEB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0D1117), Color(0xFF161B22)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1C2333), Color(0xFF161B22)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Shadows ─────────────────────────────────────────────

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> lightOnShadow(double intensity) => [
        BoxShadow(
          color: lightOn.withValues(alpha: 0.3 * intensity),
          blurRadius: 24 * intensity,
          spreadRadius: 2 * intensity,
        ),
      ];

  static List<BoxShadow> lightOffShadow(double intensity) => [
        BoxShadow(
          color: lightOff.withValues(alpha: 0.2 * intensity),
          blurRadius: 16 * intensity,
          spreadRadius: 1 * intensity,
        ),
      ];

  // ─── Border Radius ───────────────────────────────────────

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;

  // ─── Glassmorphism ───────────────────────────────────────

  static BoxDecoration get glassCard => BoxDecoration(
        color: cardColor.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(radiusMedium),
        border: Border.all(
          color: border.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: cardShadow,
      );

  // ─── ThemeData ───────────────────────────────────────────

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: lightOn,
        secondary: lightOff,
        tertiary: accent,
        error: error,
        onPrimary: Color(0xFF1A1A1A),
        onSurface: textPrimary,
        onSecondary: textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: BorderSide(color: border.withValues(alpha: 0.5)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightOn,
          foregroundColor: const Color(0xFF1A1A1A),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: GoogleFonts.inter(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: lightOn, width: 2),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: lightOn,
        foregroundColor: Color(0xFF1A1A1A),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardColor,
        contentTextStyle: GoogleFonts.inter(color: textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),
    );
  }
}
