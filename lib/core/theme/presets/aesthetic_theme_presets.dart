import 'package:flutter/material.dart';
import '../../../../models/models.dart';
import 'preset_palette.dart';

class AestheticThemePresets {
  static PresetPalette? getPalette(AppThemePreset preset, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (preset) {
      case AppThemePreset.floralRose:
        return isDark
            ? PresetPalette(
                scheme: PresetPalette.buildScheme(
                  brightness: Brightness.dark,
                  primary: const Color(0xFFFF80AB),
                  secondary: const Color(0xFFFF4081),
                  surface: const Color(0xFF240D17),
                  bg: const Color(0xFF1A070F),
                  onSurface: const Color(0xFFFFD9E3),
                  outline: const Color(0xFF5A1A30),
                ),
                scaffoldBg: const Color(0xFF160510),
                appBarBg: const Color(0xFF1A070F),
                cardColor: const Color(0xFF240D17),
                borderColor: const Color(0xFF5A1A30),
                chipBg: const Color(0xFF3A1025),
                inputFill: const Color(0xFF2A0E1C),
                gradientColors: [const Color(0xFF2D0A1A), const Color(0xFF160510)],
              )
            : PresetPalette(
                scheme: PresetPalette.buildScheme(
                  brightness: Brightness.light,
                  primary: const Color(0xFFD81B60),
                  secondary: const Color(0xFFFF6B9D),
                  surface: const Color(0xFFFFFFFF),
                  bg: const Color(0xFFFFF0F3),
                  onSurface: const Color(0xFF3B0A1F),
                  outline: const Color(0xFFFFB3C6),
                ),
                scaffoldBg: const Color(0xFFFFF0F3),
                appBarBg: const Color(0xFFFFF8FA),
                cardColor: const Color(0xFFFFF8FA),
                borderColor: const Color(0xFFFFB3C6),
                chipBg: const Color(0xFFFFE4EC),
                inputFill: const Color(0xFFFFF0F5),
                gradientColors: [const Color(0xFFFFE4EC), const Color(0xFFFFF0F3)],
              );

      case AppThemePreset.sakura:
        return isDark
            ? PresetPalette(
                scheme: PresetPalette.buildScheme(
                  brightness: Brightness.dark,
                  primary: const Color(0xFFF48FB1),
                  secondary: const Color(0xFFF8BBD0),
                  surface: const Color(0xFF240D18),
                  bg: const Color(0xFF1A0810),
                  onSurface: const Color(0xFFFFD6E7),
                  outline: const Color(0xFF601830),
                ),
                scaffoldBg: const Color(0xFF14060C),
                appBarBg: const Color(0xFF1A0810),
                cardColor: const Color(0xFF240D18),
                borderColor: const Color(0xFF601830),
                chipBg: const Color(0xFF3A1025),
                inputFill: const Color(0xFF2A0E1C),
                gradientColors: [const Color(0xFF2A0E1C), const Color(0xFF14060C)],
              )
            : PresetPalette(
                scheme: PresetPalette.buildScheme(
                  brightness: Brightness.light,
                  primary: const Color(0xFFE91E7A),
                  secondary: const Color(0xFFF8BBD0),
                  surface: const Color(0xFFFFFFFF),
                  bg: const Color(0xFFFFF5F8),
                  onSurface: const Color(0xFF3D0A20),
                  outline: const Color(0xFFF48FB1),
                ),
                scaffoldBg: const Color(0xFFFFF5F8),
                appBarBg: const Color(0xFFFFFAFC),
                cardColor: const Color(0xFFFFFAFC),
                borderColor: const Color(0xFFF48FB1),
                chipBg: const Color(0xFFFFDDEC),
                inputFill: const Color(0xFFFFF0F5),
                gradientColors: [const Color(0xFFFFDDEC), const Color(0xFFFFF5F8)],
              );

      case AppThemePreset.lavenderDream:
        return isDark
            ? PresetPalette(
                scheme: PresetPalette.buildScheme(
                  brightness: Brightness.dark,
                  primary: const Color(0xFFCE93D8),
                  secondary: const Color(0xFFE1BEE7),
                  surface: const Color(0xFF1A0F24),
                  bg: const Color(0xFF12091A),
                  onSurface: const Color(0xFFEDD9F5),
                  outline: const Color(0xFF5A1F70),
                ),
                scaffoldBg: const Color(0xFF0E0714),
                appBarBg: const Color(0xFF12091A),
                cardColor: const Color(0xFF1A0F24),
                borderColor: const Color(0xFF5A1F70),
                chipBg: const Color(0xFF2D1040),
                inputFill: const Color(0xFF200D30),
                gradientColors: [const Color(0xFF200D30), const Color(0xFF0E0714)],
              )
            : PresetPalette(
                scheme: PresetPalette.buildScheme(
                  brightness: Brightness.light,
                  primary: const Color(0xFF8E24AA),
                  secondary: const Color(0xFFCE93D8),
                  surface: const Color(0xFFFFFFFF),
                  bg: const Color(0xFFF8F0FF),
                  onSurface: const Color(0xFF2A0A3D),
                  outline: const Color(0xFFE1BEE7),
                ),
                scaffoldBg: const Color(0xFFF8F0FF),
                appBarBg: const Color(0xFFFCF5FF),
                cardColor: const Color(0xFFFCF5FF),
                borderColor: const Color(0xFFE1BEE7),
                chipBg: const Color(0xFFEED8FF),
                inputFill: const Color(0xFFF5EAFF),
                gradientColors: [const Color(0xFFEED8FF), const Color(0xFFF8F0FF)],
              );

      case AppThemePreset.candyPop:
        return isDark
            ? PresetPalette(
                scheme: PresetPalette.buildScheme(
                  brightness: Brightness.dark,
                  primary: const Color(0xFFFF80CE),
                  secondary: const Color(0xFFFFB3E6),
                  surface: const Color(0xFF240A1E),
                  bg: const Color(0xFF1A0515),
                  onSurface: const Color(0xFFFFD9F3),
                  outline: const Color(0xFF7A0F60),
                ),
                scaffoldBg: const Color(0xFF12030E),
                appBarBg: const Color(0xFF1A0515),
                cardColor: const Color(0xFF240A1E),
                borderColor: const Color(0xFF7A0F60),
                chipBg: const Color(0xFF380A2E),
                inputFill: const Color(0xFF280820),
                gradientColors: [const Color(0xFF300820), const Color(0xFF12030E)],
              )
            : PresetPalette(
                scheme: PresetPalette.buildScheme(
                  brightness: Brightness.light,
                  primary: const Color(0xFFE91E8C),
                  secondary: const Color(0xFFFF80CE),
                  surface: const Color(0xFFFFFFFF),
                  bg: const Color(0xFFFFF0FB),
                  onSurface: const Color(0xFF3D0030),
                  outline: const Color(0xFFFFB3E6),
                ),
                scaffoldBg: const Color(0xFFFFF0FB),
                appBarBg: const Color(0xFFFFF5FD),
                cardColor: const Color(0xFFFFF5FD),
                borderColor: const Color(0xFFFFB3E6),
                chipBg: const Color(0xFFFFD0F0),
                inputFill: const Color(0xFFFFE8F8),
                gradientColors: [const Color(0xFFFFD0F0), const Color(0xFFFFF0FB)],
              );

      case AppThemePreset.cloudPastel:
        return isDark
            ? PresetPalette(
                scheme: PresetPalette.buildScheme(
                  brightness: Brightness.dark,
                  primary: const Color(0xFF90B0E8),
                  secondary: const Color(0xFFB3C6F0),
                  surface: const Color(0xFF0E1726),
                  bg: const Color(0xFF080F1A),
                  onSurface: const Color(0xFFD6E4FF),
                  outline: const Color(0xFF1A2E5C),
                ),
                scaffoldBg: const Color(0xFF050A12),
                appBarBg: const Color(0xFF080F1A),
                cardColor: const Color(0xFF0E1726),
                borderColor: const Color(0xFF1A2E5C),
                chipBg: const Color(0xFF102040),
                inputFill: const Color(0xFF0C1830),
                gradientColors: [const Color(0xFF102040), const Color(0xFF050A12)],
              )
            : PresetPalette(
                scheme: PresetPalette.buildScheme(
                  brightness: Brightness.light,
                  primary: const Color(0xFF5472C4),
                  secondary: const Color(0xFFB3C6F0),
                  surface: const Color(0xFFFFFFFF),
                  bg: const Color(0xFFF0F5FF),
                  onSurface: const Color(0xFF0D1A40),
                  outline: const Color(0xFFBFD0F5),
                ),
                scaffoldBg: const Color(0xFFF0F5FF),
                appBarBg: const Color(0xFFF5F8FF),
                cardColor: const Color(0xFFF5F8FF),
                borderColor: const Color(0xFFBFD0F5),
                chipBg: const Color(0xFFD5E5FF),
                inputFill: const Color(0xFFE5EEFF),
                gradientColors: [const Color(0xFFD5E5FF), const Color(0xFFF0F5FF)],
              );

      case AppThemePreset.oceanBreeze:
        return isDark
            ? PresetPalette(
                scheme: PresetPalette.buildScheme(
                  brightness: Brightness.dark,
                  primary: const Color(0xFF4FC3F7),
                  secondary: const Color(0xFF81D4FA),
                  surface: const Color(0xFF071A24),
                  bg: const Color(0xFF031218),
                  onSurface: const Color(0xFFCEEDFF),
                  outline: const Color(0xFF0E4D6B),
                ),
                scaffoldBg: const Color(0xFF020C10),
                appBarBg: const Color(0xFF031218),
                cardColor: const Color(0xFF071A24),
                borderColor: const Color(0xFF0E4D6B),
                chipBg: const Color(0xFF0A2A3A),
                inputFill: const Color(0xFF071820),
                gradientColors: [const Color(0xFF082030), const Color(0xFF020C10)],
              )
            : PresetPalette(
                scheme: PresetPalette.buildScheme(
                  brightness: Brightness.light,
                  primary: const Color(0xFF0277BD),
                  secondary: const Color(0xFF4FC3F7),
                  surface: const Color(0xFFFFFFFF),
                  bg: const Color(0xFFEFF8FF),
                  onSurface: const Color(0xFF002033),
                  outline: const Color(0xFFB3E5FC),
                ),
                scaffoldBg: const Color(0xFFEFF8FF),
                appBarBg: const Color(0xFFF5FBFF),
                cardColor: const Color(0xFFF5FBFF),
                borderColor: const Color(0xFFB3E5FC),
                chipBg: const Color(0xFFD0ECFF),
                inputFill: const Color(0xFFE5F4FF),
                gradientColors: [const Color(0xFFD0ECFF), const Color(0xFFEFF8FF)],
              );
      default:
        return null;
    }
  }
}
