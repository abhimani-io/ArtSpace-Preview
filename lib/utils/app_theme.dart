import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized configuration for the ArtSpace Preview App Theme.
/// Complies with the premium luxury minimal aesthetic NFRs:
/// warm beige backgrounds, sophisticated dark typography, and 24px corner radiuses.
class AppTheme {
  static bool isDarkMode = false;

  // --- Colors ---
  static Color get backgroundBeige => isDarkMode ? const Color(0xFF121212) : const Color(0xFFF7F4EF);
  static Color get surfaceWhite => isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
  static Color get textDark => isDarkMode ? const Color(0xFFF7F4EF) : const Color(0xFF1E1A16);
  static Color get textMuted => isDarkMode ? const Color(0xFFA09B96) : const Color(0xFF706B63); // Darkened for accessibility
  static Color get primaryAccent => isDarkMode ? const Color(0xFFD7CCC8) : const Color(0xFF38322B);

  // --- Constants ---
  static BorderRadius defaultRadius = BorderRadius.circular(24.0);
  static BorderRadius smallRadius = BorderRadius.circular(16.0);

  // --- Shadows ---
  static List<BoxShadow> get premiumShadow => [
    BoxShadow(
      color: textDark.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 12),
      spreadRadius: 0,
    ),
  ];

  // --- Global Theme Data ---
  static ThemeData get lightTheme {
    return _buildTheme(false);
  }

  static ThemeData get darkTheme {
    return _buildTheme(true);
  }

  static ThemeData _buildTheme(bool dark) {
    final bg = dark ? const Color(0xFF121212) : const Color(0xFFF7F4EF);
    final surface = dark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
    final textD = dark ? const Color(0xFFF7F4EF) : const Color(0xFF1E1A16);
    final textM = dark ? const Color(0xFFA09B96) : const Color(0xFF706B63);
    final primary = dark ? const Color(0xFFD7CCC8) : const Color(0xFF38322B);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      primaryColor: primary,
      colorScheme: dark 
        ? ColorScheme.dark(
            primary: primary,
            secondary: textM,
            surface: surface,
            onSurface: textD,
          )
        : ColorScheme.light(
            primary: primary,
            secondary: textM,
            surface: surface,
            onSurface: textD,
          ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          color: textD,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.0,
        ),
        headlineMedium: GoogleFonts.outfit(
          color: textD,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        titleMedium: GoogleFonts.outfit(
          color: textD,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.outfit(
          color: textD,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.outfit(
          color: textM,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: dark ? const Color(0xFF121212) : Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: defaultRadius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: defaultRadius,
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textD),
        titleTextStyle: GoogleFonts.outfit(
          color: textD,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        selectedItemColor: primary,
        unselectedItemColor: textM,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }

  // --- Utility Styling ---
  
  /// Reusable Glassmorphic decoration preset.
  /// Usage: Place this on a Container that sits above a Blurred BackdropFilter
  /// or directly use it for an overlay feel.
  static BoxDecoration get glassDecoration {
    return BoxDecoration(
      color: surfaceWhite.withValues(alpha: 0.5),
      borderRadius: defaultRadius,
      border: Border.all(
        color: surfaceWhite.withValues(alpha: 0.6),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: primaryAccent.withValues(alpha: 0.04),
          blurRadius: 32,
          offset: const Offset(0, 8),
        )
      ],
    );
  }
}
