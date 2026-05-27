/// Riverpod providers for the theme system.
///
/// These providers watch [settingsProvider] and reactively rebuild the
/// [MaterialApp] whenever the user changes theme mode or accent color.
///
/// Kept separate from [AppTheme] to avoid mixing Riverpod deps into
/// the pure theme data builder.
library theme_providers;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/settings/presentation/controllers/settings_controller.dart';
import 'app_theme.dart';

/// Provides the light [ThemeData] based on the current accent color setting.
final appThemeProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(settingsProvider);
  return AppTheme.lightTheme(settings.accentColor);
});

/// Provides the dark [ThemeData] based on the current accent color setting.
final appDarkThemeProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(settingsProvider);
  return AppTheme.darkTheme(settings.accentColor);
});

/// Provides the [ThemeMode] derived from the user's theme mode preference.
final appThemeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.themeMode.toThemeMode;
});
