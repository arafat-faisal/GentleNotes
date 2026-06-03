import 'package:flutter/material.dart';
import '../../../../models/models.dart';
import 'preset_palette.dart';

class NotebookThemePresets {
  static PresetPalette? getPalette(AppThemePreset preset, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (preset) {
      case AppThemePreset.cookiesCream:
        return isDark
            ? PresetPalette(
                scheme: PresetPalette.buildScheme(
                  brightness: Brightness.dark,
                  primary: const Color(0xFFD4956A),
                  secondary: const Color(0xFFE8C09A),
                  surface: const Color(0xFF24160C),
                  bg: const Color(0xFF1A0F08),
                  onSurface: const Color(0xFFF5E6D5),
                  outline: const Color(0xFF5A3820),
                ),
                scaffoldBg: const Color(0xFF140C06),
                appBarBg: const Color(0xFF1A0F08),
                cardColor: const Color(0xFF24160C),
                borderColor: const Color(0xFF5A3820),
                chipBg: const Color(0xFF3A2010),
                inputFill: const Color(0xFF2A180C),
                gradientColors: [const Color(0xFF2A1A0A), const Color(0xFF140C06)],
              )
            : PresetPalette(
                scheme: PresetPalette.buildScheme(
                  brightness: Brightness.light,
                  primary: const Color(0xFF7B4F2E),
                  secondary: const Color(0xFFD4956A),
                  surface: const Color(0xFFFFFFFF),
                  bg: const Color(0xFFFFF8F0),
                  onSurface: const Color(0xFF2C1810),
                  outline: const Color(0xFFE8C9A8),
                ),
                scaffoldBg: const Color(0xFFFFF8F0),
                appBarBg: const Color(0xFFFFFBF5),
                cardColor: const Color(0xFFFFFBF5),
                borderColor: const Color(0xFFE8C9A8),
                chipBg: const Color(0xFFFFEDD8),
                inputFill: const Color(0xFFFFF5E8),
                gradientColors: [const Color(0xFFFFEDD8), const Color(0xFFFFF8F0)],
              );
      default:
        return null;
    }
  }
}
