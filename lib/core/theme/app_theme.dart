/// Theme data builder for GentleNotes.
///
/// Provides [lightTheme] and [darkTheme] factory methods that accept a dynamic
/// accent color so the user can personalize the palette in settings.
///
/// All color constants are imported from [AppColors] — never hardcoded here.
library app_theme;

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._(); // Prevent instantiation

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
        // ignore: deprecated_member_use
        background: AppColors.lightBg,
        // ignore: deprecated_member_use
        surfaceVariant: const Color(0xFFF0EDFB),
        outline: AppColors.lightBorder,
        outlineVariant: const Color(0xFFD8D0F0),
        onPrimary: Colors.white,
        onSurface: AppColors.lightTextPrimary,
        onSurfaceVariant: AppColors.lightTextTertiary,
        error: AppColors.rose,
      ),
      scaffoldBackgroundColor: AppColors.lightBg,
      fontFamily: 'Inter',
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 16,
        shadowColor: AppColors.violet.withOpacity(0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          color: AppColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary, letterSpacing: -1),
        headlineLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary, letterSpacing: -0.3),
        titleLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary),
        titleMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppColors.lightTextSecondary),
        titleSmall: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, color: AppColors.lightTextTertiary),
        bodyLarge: TextStyle(fontFamily: 'Inter', color: AppColors.lightTextSecondary, height: 1.6),
        bodyMedium: TextStyle(fontFamily: 'Inter', color: AppColors.lightTextTertiary, height: 1.6),
        bodySmall: TextStyle(fontFamily: 'Inter', color: AppColors.lightTextMuted, height: 1.5),
        labelLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppColors.lightTextSecondary),
        labelMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, color: AppColors.lightTextTertiary),
        labelSmall: TextStyle(fontFamily: 'Inter', color: AppColors.lightTextMuted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0EDFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accent, width: 2)),
        hintStyle: const TextStyle(fontFamily: 'Inter', color: AppColors.lightTextHint, fontSize: 14),
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
        labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.lightTextSecondary),
        shape: const StadiumBorder(side: BorderSide(color: AppColors.lightBorder)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        selectedItemColor: accent,
        unselectedItemColor: AppColors.lightTextHint,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.lightBorder, thickness: 1, space: 1),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.lightSurface,
        elevation: 8,
        shadowColor: AppColors.violet.withOpacity(0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.lightBorder)),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF0EDFB),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.lightBorder)),
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
        // ignore: deprecated_member_use
        background: AppColors.darkBg,
        // ignore: deprecated_member_use
        surfaceVariant: AppColors.darkCard,
        outline: AppColors.darkBorder,
        outlineVariant: const Color(0xFF2D2B45),
        onPrimary: Colors.white,
        onSurface: AppColors.darkTextPrimary,
        onSurfaceVariant: AppColors.darkTextTertiary,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.darkBorder)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w800, color: AppColors.darkTextPrimary, letterSpacing: -1),
        headlineLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary, letterSpacing: -0.3),
        titleLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
        titleMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppColors.darkTextSecondary),
        titleSmall: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, color: AppColors.darkTextTertiary),
        bodyLarge: TextStyle(fontFamily: 'Inter', color: Color(0xFFD4CEEE), height: 1.6),
        bodyMedium: TextStyle(fontFamily: 'Inter', color: AppColors.darkTextTertiary, height: 1.6),
        bodySmall: TextStyle(fontFamily: 'Inter', color: AppColors.darkTextMuted, height: 1.5),
        labelLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppColors.darkTextSecondary),
        labelMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, color: AppColors.darkTextTertiary),
        labelSmall: TextStyle(fontFamily: 'Inter', color: AppColors.darkTextMuted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.darkBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.darkBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.violetLight, width: 2)),
        hintStyle: const TextStyle(fontFamily: 'Inter', color: AppColors.darkTextHint, fontSize: 14),
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
        unselectedItemColor: AppColors.darkTextHint,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.darkBorder, thickness: 1, space: 1),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.darkCard,
        elevation: 12,
        shadowColor: AppColors.violet.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.darkBorder)),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkCard,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.darkBorder)),
        ),
      ),
    );
  }
}
