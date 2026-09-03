import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Exact Design System Tokens from Showcase
  static const Color forestGreen = Color(0xFF1B4332);
  static const Color emerald = Color(0xFF2D6A4F);
  static const Color warmGold = Color(0xFFD4A017);
  static const Color ivoryBg = Color(0xFFF8F5F0);
  static const Color charcoal = Color(0xFF1F1F1F);
  static const Color softSage = Color(0xFFE8ECE6);
  static const Color alertAmber = Color(0xFFF59E0B);

  // Brand Palette Mapping
  static const Color primaryDark = Color(0xFF1B4332);
  static const Color primaryForest = Color(0xFF1B4332);
  static const Color primaryLight = Color(0xFF2D6A4F);
  static const Color primaryEmerald = Color(0xFF2D6A4F);
  static const Color emeraldNeon = Color(0xFF34D399);

  // Warm Gold & Accents
  static const Color accentGold = Color(0xFFD4A017);
  static const Color goldLight = Color(0xFFFDE68A);
  static const Color accentAmber = Color(0xFFD97706);
  static const Color streakFlame = Color(0xFFFF6B4A);

  // Uganda Payment Gateway Colors
  static const Color mtnYellow = Color(0xFFFFCC00);
  static const Color mtnYellowDark = Color(0xFFE5B800);
  static const Color airtelRed = Color(0xFFE60000);
  static const Color airtelRedLight = Color(0xFFFF3333);
  static const Color cashGreen = Color(0xFF2D6A4F);
  static const Color bankBlue = Color(0xFF2563EB);

  // Status & Surfaces (Light)
  static const Color creditAmber = Color(0xFFF97316);
  static const Color efrisIndigo = Color(0xFF6366F1);
  static const Color background = Color(0xFFF8F5F0);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFE8ECE6);
  static const Color textMain = Color(0xFF1F1F1F);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFE8ECE6);
  static const Color borderSubtle = Color(0xFFF1F5F9);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF2D6A4F);

  // Dark Mode Surfaces (Deep Obsidian Emerald)
  static const Color darkBackground = Color(0xFF07110D);
  static const Color darkSurface = Color(0xFF0E1F18);
  static const Color darkCard = Color(0xFF132A21);
  static const Color darkCardElevated = Color(0xFF18352A);
  static const Color darkBorder = Color(0xFF1F4335);
  static const Color darkTextMain = Color(0xFFF1F5F9);
  static const Color darkTextMuted = Color(0xFF94A3B8);

  // Premium Gradients
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF062D20), Color(0xFF0B4F37), Color(0xFF0D6345)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkHeroGradient = LinearGradient(
    colors: [Color(0xFF041811), Color(0xFF0B3B2A), Color(0xFF0E4D37)],
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

// ─── Custom Customer Favorite & Tag Colors Palette ──────────────────────────
class CustomerFavoriteColorPreset {
  final String name;
  final String label;
  final Color color;
  final Color lightBg;
  final IconData icon;

  const CustomerFavoriteColorPreset({
    required this.name,
    required this.label,
    required this.color,
    required this.lightBg,
    required this.icon,
  });

  int get value => color.value;
}

class CustomerFavoriteColors {
  static const List<CustomerFavoriteColorPreset> presets = [
    CustomerFavoriteColorPreset(
      name: 'emerald',
      label: 'Loyal Emerald',
      color: Color(0xFF0B4F37),
      lightBg: Color(0xFFE6F4EA),
      icon: Icons.eco_rounded,
    ),
    CustomerFavoriteColorPreset(
      name: 'gold',
      label: 'VIP Gold',
      color: Color(0xFFD97706),
      lightBg: Color(0xFFFEF3C7),
      icon: Icons.star_rounded,
    ),
    CustomerFavoriteColorPreset(
      name: 'purple',
      label: 'Wholesale Purple',
      color: Color(0xFF7C3AED),
      lightBg: Color(0xFFF3E8FF),
      icon: Icons.workspace_premium_rounded,
    ),
    CustomerFavoriteColorPreset(
      name: 'blue',
      label: 'Nile Blue',
      color: Color(0xFF0284C7),
      lightBg: Color(0xFFE0F2FE),
      icon: Icons.verified_rounded,
    ),
    CustomerFavoriteColorPreset(
      name: 'rose',
      label: 'Crimson Rose',
      color: Color(0xFFE11D48),
      lightBg: Color(0xFFFFE4E6),
      icon: Icons.favorite_rounded,
    ),
    CustomerFavoriteColorPreset(
      name: 'teal',
      label: 'Teal Oasis',
      color: Color(0xFF0D9488),
      lightBg: Color(0xFFCCFBF1),
      icon: Icons.diamond_rounded,
    ),
    CustomerFavoriteColorPreset(
      name: 'sunset',
      label: 'Sunset Amber',
      color: Color(0xFFEA580C),
      lightBg: Color(0xFFFFEDD5),
      icon: Icons.local_fire_department_rounded,
    ),
    CustomerFavoriteColorPreset(
      name: 'slate',
      label: 'Classic Slate',
      color: Color(0xFF475569),
      lightBg: Color(0xFFF1F5F9),
      icon: Icons.person_rounded,
    ),
  ];

  static CustomerFavoriteColorPreset getByColorValue(int value) {
    for (final p in presets) {
      if (p.color.value == value ||
          (p.color.value & 0xFFFFFF) == (value & 0xFFFFFF)) {
        return p;
      }
    }
    return presets[0];
  }
}

class AppTheme {
  static ThemeData get lightTheme =>
      buildTheme(AppColors.primaryForest, isDark: false);
  static ThemeData get darkTheme =>
      buildTheme(AppColors.primaryForest, isDark: true);

  static ThemeData buildTheme(Color primaryColor, {required bool isDark}) {
    if (isDark) {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
          primary: primaryColor == AppColors.primaryForest
              ? AppColors.emeraldNeon
              : primaryColor,
          secondary: AppColors.accentGold,
          surface: AppColors.darkSurface,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        textTheme:
            GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme)
                .copyWith(
          displayLarge: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w900,
              color: AppColors.darkTextMain,
              letterSpacing: -0.5),
          headlineLarge: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: AppColors.darkTextMain,
              letterSpacing: -0.5),
          headlineMedium: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800, color: AppColors.darkTextMain),
          titleLarge: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700, color: AppColors.darkTextMain),
          titleMedium: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600, color: AppColors.darkTextMain),
          bodyLarge: GoogleFonts.plusJakartaSans(
              color: AppColors.darkTextMain,
              fontSize: 15,
              fontWeight: FontWeight.w500),
          bodyMedium: GoogleFonts.plusJakartaSans(
              color: AppColors.darkTextMuted, fontSize: 13),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkSurface,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor == AppColors.primaryForest
                ? AppColors.primaryEmerald
                : primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: primaryColor.withValues(alpha: 0.2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            textStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkCard,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.darkBorder, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkCard,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: GoogleFonts.plusJakartaSans(
              color: AppColors.darkTextMuted, fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
        ),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: AppColors.accentGold,
        surface: AppColors.surfaceCard,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w900,
            color: AppColors.textMain,
            letterSpacing: -0.5),
        headlineLarge: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: AppColors.textMain,
            letterSpacing: -0.5),
        headlineMedium: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800, color: AppColors.textMain),
        titleLarge: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700, color: AppColors.textMain),
        titleMedium: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600, color: AppColors.textMain),
        bodyLarge: GoogleFonts.inter(
            color: AppColors.textMain,
            fontSize: 15,
            fontWeight: FontWeight.w500),
        bodyMedium: GoogleFonts.inter(
            color: AppColors.textMuted, fontSize: 13),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor == AppColors.primaryForest
            ? AppColors.primaryDark
            : primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: primaryColor.withValues(alpha: 0.2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(
            color: AppColors.textLight, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }
}
