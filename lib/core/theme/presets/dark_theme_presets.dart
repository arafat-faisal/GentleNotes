import 'package:flutter/material.dart';
import '../../../../models/models.dart';
import 'preset_palette.dart';

class DarkThemePresets {
  static PresetPalette? getPalette(AppThemePreset preset, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (preset) {
      case AppThemePreset.midnightStars:
        return isDark
            ? PresetPalette(
                scheme: PresetPalette.buildScheme(
                  brightness: Brightness.dark,
                  primary: const Color(0xFF9FA8DA),
                  secondary: const Color(0xFFC5CAE9),
                  surface: const Color(0xFF08081E),
                  bg: const Color(0xFF03030F),
                  onSurface: const Color(0xFFE8EAF6),
                  outline: const Color(0xFF1A1A5E),
                ),
                scaffoldBg: const Color(0xFF02020A),
                appBarBg: const Color(0xFF03030F),
                cardColor: const Color(0xFF08081E),
                borderColor: const Color(0xFF1A1A5E),
                chipBg: const Color(0xFF10103A),
                inputFill: const Color(0xFF0A0A28),
                gradientColors: [const Color(0xFF0A0A28), const Color(0xFF02020A)],
              )
            : PresetPalette(
                scheme: PresetPalette.buildScheme(
                  brightness: Brightness.light,
                  primary: const Color(0xFF3949AB),
                  secondary: const Color(0xFF7986CB),
                  surface: const Color(0xFFFFFFFF),
                  bg: const Color(0xFFF0F0FF),
                  onSurface: const Color(0xFF0A0A2E),
                  outline: const Color(0xFFC5CAE9),
                ),
                scaffoldBg: const Color(0xFFF0F0FF),
                appBarBg: const Color(0xFFF5F5FF),
                cardColor: const Color(0xFFF5F5FF),
                borderColor: const Color(0xFFC5CAE9),
                chipBg: const Color(0xFFDDE0FF),
                inputFill: const Color(0xFFE8E8FF),
                gradientColors: [const Color(0xFFDDE0FF), const Color(0xFFF0F0FF)],
              );
      default:
        return null;
    }
  }
}
