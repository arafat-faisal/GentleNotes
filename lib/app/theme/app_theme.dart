import 'package:flutter/material.dart';

// ─── Futuristic Palette ───────────────────────────────────────────────────────
// Inspired by the deep dark AI-assistant aesthetics from Inspirations.
// Dark: deep navy-black bg (#090B16), purple accent (#7C3AED / #8B5CF6)
// Light: soft lavender (#F5F3FF), violet accent (#7C3AED)
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  // Dark palette
  static const darkBg = Color(0xFF090B16);
  static const darkSurface = Color(0xFF10121F);
  static const darkCard = Color(0xFF13111C);
  static const darkBorder = Color(0xFF252234);
  static const darkSurface2 = Color(0xFF1A1730);

  // Light palette
  static const lightBg = Color(0xFFF5F3FF);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFAF9FF);
  static const lightBorder = Color(0xFFE9E6F5);

  // Accents
  static const violet = Color(0xFF7C3AED);
  static const violetLight = Color(0xFF8B5CF6);
  static const violetBright = Color(0xFFA78BFA);
  static const violetMuted = Color(0xFF6D28D9);
  static const rose = Color(0xFFF43F5E);
  static const emerald = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const sky = Color(0xFF38BDF8);
}

class AppTheme {
  static ThemeData lightTheme(Color accentColor) {
    final accent = accentColor == Colors.indigo ? AppColors.violet : accentColor;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
        primary: accent,
        secondary: AppColors.violetLight,
        surface: AppColors.lightSurface,
        background: AppColors.lightBg,
        surfaceVariant: const Color(0xFFF0EDFB),
        outline: AppColors.lightBorder,
        outlineVariant: const Color(0xFFD8D0F0),
        onPrimary: Colors.white,
        onSurface: const Color(0xFF1A0F3C),
        onSurfaceVariant: const Color(0xFF5E4D8C),
        error: AppColors.rose,
      ),
      scaffoldBackgroundColor: AppColors.lightBg,
      fontFamily: 'Inter',
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 16,
        shadowColor: AppColors.violet.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1A0F3C)),
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          color: Color(0xFF1A0F3C),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w800, color: Color(0xFF1A0F3C), letterSpacing: -1),
        headlineLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700, color: Color(0xFF1A0F3C), letterSpacing: -0.5),
        headlineMedium: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, color: Color(0xFF1A0F3C), letterSpacing: -0.3),
        titleLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, color: Color(0xFF1A0F3C)),
        titleMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Color(0xFF2D1F6E)),
        titleSmall: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, color: Color(0xFF4B3B9A)),
        bodyLarge: TextStyle(fontFamily: 'Inter', color: Color(0xFF2D1F6E), height: 1.6),
        bodyMedium: TextStyle(fontFamily: 'Inter', color: Color(0xFF5E4D8C), height: 1.6),
        bodySmall: TextStyle(fontFamily: 'Inter', color: Color(0xFF7B6BA8), height: 1.5),
        labelLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Color(0xFF2D1F6E)),
        labelMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, color: Color(0xFF5E4D8C)),
        labelSmall: TextStyle(fontFamily: 'Inter', color: Color(0xFF7B6BA8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0EDFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        hintStyle: const TextStyle(fontFamily: 'Inter', color: Color(0xFFAA9ECC), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEDE9FB),
        selectedColor: accent.withOpacity(0.15),
        labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF2D1F6E)),
        shape: StadiumBorder(side: BorderSide(color: AppColors.lightBorder)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        selectedItemColor: accent,
        unselectedItemColor: const Color(0xFF9E8EC5),
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.lightSurface,
        elevation: 8,
        shadowColor: AppColors.violet.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF0EDFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.lightBorder),
          ),
        ),
      ),
    );
  }

  static ThemeData darkTheme(Color accentColor) {
    final accent = accentColor == Colors.indigo ? AppColors.violet : accentColor;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
        primary: AppColors.violetLight,
        secondary: AppColors.violetBright,
        surface: AppColors.darkSurface,
        background: AppColors.darkBg,
        surfaceVariant: AppColors.darkCard,
        outline: AppColors.darkBorder,
        outlineVariant: const Color(0xFF2D2B45),
        onPrimary: Colors.white,
        onSurface: const Color(0xFFF1EFF9),
        onSurfaceVariant: const Color(0xFFB9B0D6),
        error: AppColors.rose,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      fontFamily: 'Inter',
      cardTheme: const CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkCard,
        elevation: 24,
        shadowColor: AppColors.violet.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Color(0xFFF1EFF9)),
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          color: Color(0xFFF1EFF9),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w800, color: Color(0xFFF1EFF9), letterSpacing: -1),
        headlineLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700, color: Color(0xFFF1EFF9), letterSpacing: -0.5),
        headlineMedium: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, color: Color(0xFFF1EFF9), letterSpacing: -0.3),
        titleLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, color: Color(0xFFF1EFF9)),
        titleMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Color(0xFFE2DBF5)),
        titleSmall: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, color: Color(0xFFB9B0D6)),
        bodyLarge: TextStyle(fontFamily: 'Inter', color: Color(0xFFD4CEEE), height: 1.6),
        bodyMedium: TextStyle(fontFamily: 'Inter', color: Color(0xFFB9B0D6), height: 1.6),
        bodySmall: TextStyle(fontFamily: 'Inter', color: Color(0xFF9088B5), height: 1.5),
        labelLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Color(0xFFE2DBF5)),
        labelMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, color: Color(0xFFB9B0D6)),
        labelSmall: TextStyle(fontFamily: 'Inter', color: Color(0xFF9088B5)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.violetLight, width: 2),
        ),
        hintStyle: const TextStyle(fontFamily: 'Inter', color: Color(0xFF6B5F8A), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.violetLight,
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1E1A35),
        selectedColor: AppColors.violetLight.withOpacity(0.2),
        labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFFD4CEEE)),
        shape: const StadiumBorder(side: BorderSide(color: AppColors.darkBorder)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        selectedItemColor: AppColors.violetLight,
        unselectedItemColor: Color(0xFF6B5F8A),
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.darkCard,
        elevation: 12,
        shadowColor: AppColors.violet.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
        ),
      ),
    );
  }
}
