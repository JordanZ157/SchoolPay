import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryDark = Color(0xFF1A1A2E);
  static const Color primaryMid = Color(0xFF16213E);
  static const Color primaryLight = Color(0xFF0F3460);
  
  // Accent Colors
  static const Color accentPrimary = Color(0xFF6C63FF);
  static const Color accentSecondary = Color(0xFF00D9FF);
  static const Color accentGradientStart = Color(0xFF667EEA);
  static const Color accentGradientEnd = Color(0xFF764BA2);
  
  // Status Colors
  static const Color successColor = Color(0xFF00C853);
  static const Color warningColor = Color(0xFFFFAB00);
  static const Color errorColor = Color(0xFFFF5252);
  static const Color infoColor = Color(0xFF448AFF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textMuted = Color(0xFF6B6B6B);
  
  // Card/Surface Colors
  static const Color cardBackground = Color(0xFF1E1E30);
  static const Color surfaceColor = Color(0xFF252540);
  static const Color dividerColor = Color(0xFF3A3A5A);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentGradientStart, accentGradientEnd],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A2A4A), Color(0xFF1E1E35)],
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryDark,
      primaryColor: accentPrimary,
      colorScheme: ColorScheme.dark(
        primary: accentPrimary,
        secondary: accentSecondary,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: textPrimary,
        onSecondary: primaryDark,
        onSurface: textPrimary,
        onError: textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      cardTheme: const CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPrimary,
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentPrimary,
          side: const BorderSide(color: accentPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.inter(color: textMuted),
        labelStyle: GoogleFonts.inter(color: textSecondary),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 24,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
    );
  }

  // Status color helpers
  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return successColor;
      case 'UNPAID':
        return errorColor;
      case 'PARTIAL':
        return warningColor;
      case 'EXPIRED':
        return textMuted;
      case 'PENDING':
        return infoColor;
      default:
        return textSecondary;
    }
  }

  // Glassmorphism decoration
  static BoxDecoration get glassDecoration => BoxDecoration(
    color: surfaceColor.withValues(alpha: 0.7),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: dividerColor.withValues(alpha: 0.3),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );

  // Gradient card decoration
  static BoxDecoration get gradientCardDecoration => BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: dividerColor.withValues(alpha: 0.3),
      width: 1,
    ),
  );
}
