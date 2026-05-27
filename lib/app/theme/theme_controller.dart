import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/data/settings_repository.dart';
import 'app_theme.dart';

final appThemeProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(settingsProvider);
  return AppTheme.lightTheme(settings.accentColor);
});

final appDarkThemeProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(settingsProvider);
  return AppTheme.darkTheme(settings.accentColor);
});

final appThemeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.themeMode.toThemeMode;
});
