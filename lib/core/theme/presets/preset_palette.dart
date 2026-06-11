import 'package:flutter/material.dart';

class PresetPalette {
  final ColorScheme scheme;
  final Color scaffoldBg;
  final Color appBarBg;
  final Color cardColor;
  final Color borderColor;
  final Color chipBg;
  final Color inputFill;
  final List<Color> gradientColors;

  const PresetPalette({
    required this.scheme,
    required this.scaffoldBg,
    required this.appBarBg,
    required this.cardColor,
    required this.borderColor,
    required this.chipBg,
    required this.inputFill,
    required this.gradientColors,
  });

  static ColorScheme buildScheme({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
    required Color surface,
    required Color bg,
    required Color onSurface,
    required Color outline,
  }) {
    return ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: brightness == Brightness.dark ? Colors.black : Colors.white,
      secondary: secondary,
      onSecondary: brightness == Brightness.dark ? Colors.black : Colors.white,
      tertiary: secondary,
      onTertiary: brightness == Brightness.dark ? Colors.black : Colors.white,
      error: brightness == Brightness.dark
          ? const Color(0xFFEF9A9A)
          : const Color(0xFFE53935),
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: bg,
      outline: outline,
      outlineVariant: outline.withValues(alpha: 0.5),
      shadow: Colors.black.withValues(alpha: 0.08),
      scrim: Colors.black,
      inverseSurface: onSurface,
      onInverseSurface: surface,
      inversePrimary: secondary,
      surfaceTint: primary.withValues(alpha: 0.05),
    );
  }
}
