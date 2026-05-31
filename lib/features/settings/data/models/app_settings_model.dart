import 'package:flutter/material.dart';
import '../../../../models/models.dart';

class AppSettingsModel {
  final ThemeModeSetting themeMode;
  final String accentColorHex;
  final LayoutMode layoutMode;
  final EditorMode editorMode;
  final NoteType defaultNoteType;
  final bool autoSaveEnabled;
  final String activeCodeTheme;
  final EditorLayoutVariant editorLayout;
  final AppThemePreset themePreset;

  AppSettingsModel({
    required this.themeMode,
    required this.accentColorHex,
    required this.layoutMode,
    required this.editorMode,
    required this.defaultNoteType,
    required this.autoSaveEnabled,
    required this.activeCodeTheme,
    this.editorLayout = EditorLayoutVariant.classic,
    this.themePreset = AppThemePreset.none,
  });

  AppSettingsModel copyWith({
    ThemeModeSetting? themeMode,
    String? accentColorHex,
    LayoutMode? layoutMode,
    EditorMode? editorMode,
    NoteType? defaultNoteType,
    bool? autoSaveEnabled,
    String? activeCodeTheme,
    EditorLayoutVariant? editorLayout,
    AppThemePreset? themePreset,
  }) {
    return AppSettingsModel(
      themeMode: themeMode ?? this.themeMode,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      layoutMode: layoutMode ?? this.layoutMode,
      editorMode: editorMode ?? this.editorMode,
      defaultNoteType: defaultNoteType ?? this.defaultNoteType,
      autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
      activeCodeTheme: activeCodeTheme ?? this.activeCodeTheme,
      editorLayout: editorLayout ?? this.editorLayout,
      themePreset: themePreset ?? this.themePreset,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode.name,
      'accentColorHex': accentColorHex,
      'layoutMode': layoutMode.name,
      'editorMode': editorMode.name,
      'defaultNoteType': defaultNoteType.name,
      'autoSaveEnabled': autoSaveEnabled ? 1 : 0,
      'activeCodeTheme': activeCodeTheme,
      'editorLayout': editorLayout.name,
      'themePreset': themePreset.name,
    };
  }

  factory AppSettingsModel.fromMap(Map<String, dynamic> map) {
    return AppSettingsModel(
      themeMode: ThemeModeSetting.values.firstWhere((e) => e.name == map['themeMode'], orElse: () => ThemeModeSetting.system),
      accentColorHex: map['accentColorHex'] ?? '#6366F1',
      layoutMode: LayoutMode.values.firstWhere((e) => e.name == map['layoutMode'], orElse: () => LayoutMode.grid),
      editorMode: EditorMode.values.firstWhere((e) => e.name == map['editorMode'], orElse: () => EditorMode.markdown),
      defaultNoteType: NoteType.values.firstWhere((e) => e.name == map['defaultNoteType'], orElse: () => NoteType.markdown),
      autoSaveEnabled: (map['autoSaveEnabled'] == 1 || map['autoSaveEnabled'] == true || map['autoSaveEnabled'] == null),
      activeCodeTheme: map['activeCodeTheme'] ?? 'vs-dark',
      editorLayout: EditorLayoutVariant.values.firstWhere(
        (e) => e.name == map['editorLayout'],
        orElse: () => EditorLayoutVariant.classic,
      ),
      themePreset: AppThemePreset.values.firstWhere(
        (e) => e.name == map['themePreset'],
        orElse: () => AppThemePreset.none,
      ),
    );
  }

  Color get accentColor {
    final hex = accentColorHex.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return const Color(0xFF6366F1);
  }
}
