library theme_presets;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/models.dart';
import 'presets/preset_palette.dart';
import 'presets/calm_theme_presets.dart';
import 'presets/dark_theme_presets.dart';
import 'presets/notebook_theme_presets.dart';
import 'presets/aesthetic_theme_presets.dart';
import 'presets/high_contrast_theme_presets.dart';

class ThemePresets {
  ThemePresets._();

  static ThemeData lightThemeData(AppThemePreset preset) =>
      _presetData(preset, Brightness.light);

  static ThemeData darkThemeData(AppThemePreset preset) =>
      _presetData(preset, Brightness.dark);

  static ColorScheme lightScheme(AppThemePreset preset) =>
      _palette(preset, Brightness.light).scheme;

  static ColorScheme darkScheme(AppThemePreset preset) =>
      _palette(preset, Brightness.dark).scheme;

  static List<Color> gradientColors(AppThemePreset preset,
      {bool dark = false}) {
    final p = _palette(preset, dark ? Brightness.dark : Brightness.light);
    return p.gradientColors;
  }

  static ThemeData _presetData(AppThemePreset preset, Brightness brightness) {
    final p = _palette(preset, brightness);
    final isDark = brightness == Brightness.dark;
    final s = p.scheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: s,
      scaffoldBackgroundColor: p.scaffoldBg,
      fontFamily: 'Inter',

      appBarTheme: AppBarTheme(
        backgroundColor: p.appBarBg,
        foregroundColor: s.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: s.onSurface),
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          color: s.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),

      cardTheme: CardThemeData(
        color: p.cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: p.borderColor, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: s.primary,
        foregroundColor: isDark ? Colors.black : Colors.white,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: s.primary,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: s.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: s.primary,
          side: BorderSide(color: p.borderColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: p.chipBg,
        selectedColor: s.primary.withOpacity(0.18),
        labelStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: s.onSurface.withOpacity(0.85)),
        shape: StadiumBorder(side: BorderSide(color: p.borderColor)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.inputFill,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: p.borderColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: p.borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: s.primary, width: 2)),
        hintStyle: TextStyle(
            fontFamily: 'Inter',
            color: s.onSurface.withOpacity(0.4),
            fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.cardColor,
        elevation: 0,
        selectedItemColor: s.primary,
        unselectedItemColor: s.onSurface.withOpacity(0.4),
        type: BottomNavigationBarType.fixed,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: p.cardColor,
        elevation: 16,
        shadowColor: s.primary.withOpacity(0.15),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: p.borderColor)),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: p.cardColor,
        elevation: 8,
        shadowColor: s.primary.withOpacity(0.15),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: p.borderColor)),
      ),

      dividerTheme: DividerThemeData(color: p.borderColor, thickness: 1, space: 1),

      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: p.inputFill,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: p.borderColor)),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? p.scheme.primary : null),
        trackColor: WidgetStateProperty.resolveWith((st) =>
            st.contains(WidgetState.selected)
                ? p.scheme.primary.withOpacity(0.4)
                : null),
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(
            fontFamily: 'Outfit', fontWeight: FontWeight.w800,
            color: s.onSurface, letterSpacing: -1),
        headlineLarge: TextStyle(
            fontFamily: 'Outfit', fontWeight: FontWeight.w700,
            color: s.onSurface, letterSpacing: -0.5),
        headlineMedium: TextStyle(
            fontFamily: 'Outfit', fontWeight: FontWeight.w600,
            color: s.onSurface, letterSpacing: -0.3),
        titleLarge: TextStyle(
            fontFamily: 'Outfit', fontWeight: FontWeight.w600,
            color: s.onSurface),
        titleMedium: TextStyle(
            fontFamily: 'Inter', fontWeight: FontWeight.w600,
            color: s.onSurface.withOpacity(0.85)),
        titleSmall: TextStyle(
            fontFamily: 'Inter', fontWeight: FontWeight.w500,
            color: s.onSurface.withOpacity(0.65)),
        bodyLarge: TextStyle(
            fontFamily: 'Inter',
            color: s.onSurface.withOpacity(0.85), height: 1.6),
        bodyMedium: TextStyle(
            fontFamily: 'Inter',
            color: s.onSurface.withOpacity(0.65), height: 1.6),
        bodySmall: TextStyle(
            fontFamily: 'Inter',
            color: s.onSurface.withOpacity(0.5), height: 1.5),
        labelLarge: TextStyle(
            fontFamily: 'Inter', fontWeight: FontWeight.w600,
            color: s.onSurface.withOpacity(0.85)),
        labelMedium: TextStyle(
            fontFamily: 'Inter', fontWeight: FontWeight.w500,
            color: s.onSurface.withOpacity(0.65)),
        labelSmall: TextStyle(
            fontFamily: 'Inter', color: s.onSurface.withOpacity(0.5)),
      ),
    );
  }

  static PresetPalette _palette(AppThemePreset preset, Brightness brightness) {
    return HighContrastThemePresets.getPalette(preset, brightness) ??
        CalmThemePresets.getPalette(preset, brightness) ??
        DarkThemePresets.getPalette(preset, brightness) ??
        NotebookThemePresets.getPalette(preset, brightness) ??
        AestheticThemePresets.getPalette(preset, brightness) ??
        HighContrastThemePresets.getPalette(AppThemePreset.none, brightness)!;
  }
}
