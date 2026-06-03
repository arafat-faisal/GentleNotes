import 'package:flutter/material.dart';
import '../../../../models/models.dart';
import 'preset_palette.dart';

class HighContrastThemePresets {
  static PresetPalette? getPalette(AppThemePreset preset, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (preset) {
      case AppThemePreset.none:
        return isDark
            ? PresetPalette(
                scheme: PresetPalette.buildScheme(
                  brightness: Brightness.dark,
                  primary: const Color(0xFF8B5CF6),
                  secondary: const Color(0xFFA78BFA),
                  surface: const Color(0xFF10121F),
                  bg: const Color(0xFF090B16),
                  onSurface: const Color(0xFFF1EFF9),
                  outline: const Color(0xFF2D2B45),
                ),
                scaffoldBg: const Color(0xFF090B16),
                appBarBg: const Color(0xFF0D0F1E),
                cardColor: const Color(0xFF10121F),
                borderColor: const Color(0xFF2D2B45),
                chipBg: const Color(0xFF1E1A35),
                inputFill: const Color(0xFF1A172E),
                gradientColors: [const Color(0xFF090B16), const Color(0xFF14102A)],
              )
            : PresetPalette(
                scheme: PresetPalette.buildScheme(
                  brightness: Brightness.light,
                  primary: const Color(0xFF6366F1),
                  secondary: const Color(0xFF8B5CF6),
                  surface: const Color(0xFFFFFFFF),
                  bg: const Color(0xFFF5F3FF),
                  onSurface: const Color(0xFF1A0F3C),
                  outline: const Color(0xFFDDD8F8),
                ),
                scaffoldBg: const Color(0xFFF5F3FF),
                appBarBg: Colors.transparent,
                cardColor: const Color(0xFFFFFFFF),
                borderColor: const Color(0xFFDDD8F8),
                chipBg: const Color(0xFFEDE9FB),
                inputFill: const Color(0xFFF0EDFB),
                gradientColors: [const Color(0xFFEDE9FB), const Color(0xFFF5F3FF)],
              );
      default:
        return null;
    }
  }
}
