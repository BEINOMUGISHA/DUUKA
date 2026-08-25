import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Luxury Emerald & Deep Forest Palette
  static const Color primaryDark = Color(0xFF062319);
  static const Color primaryForest = Color(0xFF0B4F37);
  static const Color primaryLight = Color(0xFF107350);
  static const Color primaryEmerald = Color(0xFF10B981);
  static const Color emeraldNeon = Color(0xFF34D399);

  // Warm Gold & Accents
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color goldLight = Color(0xFFFDE68A);
  static const Color accentAmber = Color(0xFFD97706);
  static const Color streakFlame = Color(0xFFFF6B4A);

  // Uganda Payment Gateway Colors
  static const Color mtnYellow = Color(0xFFFFCC00);
  static const Color mtnYellowDark = Color(0xFFE5B800);
  static const Color airtelRed = Color(0xFFE60000);
  static const Color airtelRedLight = Color(0xFFFF3333);
  static const Color cashGreen = Color(0xFF10B981);
  static const Color bankBlue = Color(0xFF2563EB);

  // Status & Surfaces
  static const Color creditAmber = Color(0xFFF97316);
  static const Color efrisIndigo = Color(0xFF6366F1);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color textMain = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFF1F5F9);
  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);

  // Premium Gradients
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF062D20), Color(0xFF0B4F37), Color(0xFF0D6345)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient momoGradient = LinearGradient(
    colors: [Color(0xFFFFD633), Color(0xFFFFCC00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient airtelGradient = LinearGradient(
    colors: [Color(0xFFFF3B30), Color(0xFFE60000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient creditGradient = LinearGradient(
    colors: [Color(0xFFFF7A59), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryForest,
        primary: AppColors.primaryForest,
        secondary: AppColors.accentGold,
        surface: AppColors.background,
        background: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: AppColors.textMain, letterSpacing: -0.5),
        headlineLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.textMain, letterSpacing: -0.5),
        headlineMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.textMain),
        titleLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.textMain),
        titleMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.textMain),
        bodyLarge: GoogleFonts.plusJakartaSans(color: AppColors.textMain, fontSize: 15, fontWeight: FontWeight.w500),
        bodyMedium: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 13),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryForest,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.primaryForest.withOpacity(0.35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textLight, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryForest, width: 2),
        ),
      ),
    );
  }
}
