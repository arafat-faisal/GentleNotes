import 'package:flutter/material.dart';
import '../../../../models/models.dart';
import 'preset_palette.dart';

class CalmThemePresets {
  static PresetPalette? getPalette(AppThemePreset preset, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (preset) {
      case AppThemePreset.cottagecore:
        return isDark
            ? PresetPalette(
                scheme: PresetPalette.buildScheme(
                  brightness: Brightness.dark,
                  primary: const Color(0xFFAED581),
                  secondary: const Color(0xFFC5E1A5),
                  surface: const Color(0xFF0F1A08),
                  bg: const Color(0xFF0A1205),
                  onSurface: const Color(0xFFD7ECC0),
                  outline: const Color(0xFF1E4010),
                ),
                scaffoldBg: const Color(0xFF070D04),
                appBarBg: const Color(0xFF0A1205),
                cardColor: const Color(0xFF0F1A08),
                borderColor: const Color(0xFF1E4010),
                chipBg: const Color(0xFF142810),
                inputFill: const Color(0xFF101E0A),
                gradientColors: [const Color(0xFF182810), const Color(0xFF070D04)],
              )
            : PresetPalette(
                scheme: PresetPalette.buildScheme(
                  brightness: Brightness.light,
                  primary: const Color(0xFF558B2F),
                  secondary: const Color(0xFF8BC34A),
                  surface: const Color(0xFFFFFFFF),
                  bg: const Color(0xFFF4FAF0),
                  onSurface: const Color(0xFF1A2B0A),
                  outline: const Color(0xFFC5E1A5),
                ),
                scaffoldBg: const Color(0xFFF4FAF0),
                appBarBg: const Color(0xFFF8FCF4),
                cardColor: const Color(0xFFF8FCF4),
                borderColor: const Color(0xFFC5E1A5),
                chipBg: const Color(0xFFD8EEC8),
                inputFill: const Color(0xFFEBF5E0),
                gradientColors: [const Color(0xFFD8EEC8), const Color(0xFFF4FAF0)],
              );

      case AppThemePreset.matchaLatte:
        return isDark
            ? PresetPalette(
                scheme: PresetPalette.buildScheme(
                  brightness: Brightness.dark,
                  primary: const Color(0xFFB5CC8E),
                  secondary: const Color(0xFFC5D99E),
                  surface: const Color(0xFF131F0B),
                  bg: const Color(0xFF0D1508),
                  onSurface: const Color(0xFFD9EDBB),
                  outline: const Color(0xFF2A4A12),
                ),
                scaffoldBg: const Color(0xFF080E05),
                appBarBg: const Color(0xFF0D1508),
                cardColor: const Color(0xFF131F0B),
                borderColor: const Color(0xFF2A4A12),
                chipBg: const Color(0xFF1A2E0A),
                inputFill: const Color(0xFF101A08),
                gradientColors: [const Color(0xFF1A2E0A), const Color(0xFF080E05)],
              )
            : PresetPalette(
                scheme: PresetPalette.buildScheme(
                  brightness: Brightness.light,
                  primary: const Color(0xFF689F38),
                  secondary: const Color(0xFFA5C461),
                  surface: const Color(0xFFFFFFFF),
                  bg: const Color(0xFFF5F8F0),
                  onSurface: const Color(0xFF1A2908),
                  outline: const Color(0xFFDCEDC8),
                ),
                scaffoldBg: const Color(0xFFF5F8F0),
                appBarBg: const Color(0xFFF9FBF5),
                cardColor: const Color(0xFFF9FBF5),
                borderColor: const Color(0xFFDCEDC8),
                chipBg: const Color(0xFFD8ECC0),
                inputFill: const Color(0xFFECF5E0),
                gradientColors: [const Color(0xFFD8ECC0), const Color(0xFFF5F8F0)],
              );
      default:
        return null;
    }
  }
}
