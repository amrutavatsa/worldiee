import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class WorldCompanionTypography {
  static TextTheme get textTheme {
    final jakarta = GoogleFonts.plusJakartaSansTextTheme();

    return jakarta.copyWith(
      displayLarge: GoogleFonts.dmSerifDisplay(
        fontSize: 36,
        height: 44 / 36,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF0B2545),
      ),

      displayMedium: GoogleFonts.dmSerifDisplay(
        fontSize: 32,
        height: 40 / 32,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF0B2545),
      ),

      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        height: 40 / 32,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0B2545),
      ),

      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0B2545),
      ),

      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        height: 28 / 20,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0B2545),
      ),

      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        height: 26 / 18,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0B2545),
      ),

      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0B2545),
      ),

      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0B2545),
      ),

      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF0B2545),
      ),

      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF4B6075),
      ),

      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF718398),
      ),

      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0B2545),
      ),

      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF4B6075),
      ),

      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        height: 14 / 11,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF718398),
      ),
    );
  }

  static TextStyle get brand {
    return GoogleFonts.plusJakartaSans(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.4,
      color: const Color(0xFF0B2545),
    );
  }

  static TextStyle get editorial {
    return GoogleFonts.dmSerifDisplay(
      fontSize: 36,
      height: 44 / 36,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF0B2545),
    );
  }
}