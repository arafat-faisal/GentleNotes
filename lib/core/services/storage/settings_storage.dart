import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../models/models.dart';

class SettingsStorage {
  final SharedPreferences sharedPrefs;

  SettingsStorage({required this.sharedPrefs});

  AppSettingsModel getSettings() {
    final theme = sharedPrefs.getString(AppConstants.prefThemeMode) ?? 'system';
    final accent = sharedPrefs.getString(AppConstants.prefAccentColor) ?? AppConstants.defaultAccentHex;
    final layout = sharedPrefs.getString(AppConstants.prefLayoutMode) ?? 'grid';
    final editor = sharedPrefs.getString(AppConstants.prefEditorMode) ?? 'gentleNote';
    final noteType = sharedPrefs.getString(AppConstants.prefDefaultNoteType) ?? 'mixed';
    final autoSave = sharedPrefs.getBool(AppConstants.prefAutoSave) ?? true;
    final codeTheme = sharedPrefs.getString(AppConstants.prefCodeTheme) ?? AppConstants.defaultCodeTheme;
    final layoutVariant = sharedPrefs.getString(AppConstants.prefEditorLayout) ?? 'classic';
    final themePreset = sharedPrefs.getString(AppConstants.prefThemePreset) ?? 'none';
    final userMode = sharedPrefs.getString(AppConstants.prefUserMode) ?? 'normal';
    final isAdvanced = sharedPrefs.getBool(AppConstants.prefIsAdvancedMode) ?? false;
    final customLayouts = sharedPrefs.getStringList(AppConstants.prefCustomEnabledLayouts) ??
        EditorLayoutVariant.values.map((e) => e.name).toList();
    final customThemes = sharedPrefs.getStringList(AppConstants.prefCustomEnabledThemes) ??
        AppThemePreset.values.map((e) => e.name).toList();
    final customTools = sharedPrefs.getStringList(AppConstants.prefCustomEnabledTools) ??
        ['format', 'color', 'heading', 'align', 'lists', 'insert', 'indent'];
    final fontFamily = sharedPrefs.getString(AppConstants.prefEditorFontFamily) ?? 'Inter';
    final fontSize = sharedPrefs.getDouble(AppConstants.prefEditorFontSize) ?? 16.0;
    final lineHeight = sharedPrefs.getDouble(AppConstants.prefEditorLineHeight) ?? 1.5;

    return AppSettingsModel(
      themeMode: ThemeModeSetting.values.firstWhere((e) => e.name == theme, orElse: () => ThemeModeSetting.system),
      accentColorHex: accent,
      layoutMode: LayoutMode.values.firstWhere((e) => e.name == layout, orElse: () => LayoutMode.grid),
      editorMode: EditorMode.values.firstWhere((e) => e.name == editor, orElse: () => EditorMode.gentleNote),
      defaultNoteType: NoteType.values.firstWhere((e) => e.name == noteType, orElse: () => NoteType.markdown),
      autoSaveEnabled: autoSave,
      activeCodeTheme: codeTheme,
      editorLayout: EditorLayoutVariant.values.firstWhere((e) => e.name == layoutVariant, orElse: () => EditorLayoutVariant.classic),
      themePreset: AppThemePreset.values.firstWhere((e) => e.name == themePreset, orElse: () => AppThemePreset.none),
      userMode: AppUserMode.values.firstWhere((e) => e.name == userMode, orElse: () => AppUserMode.normal),
      isAdvancedMode: isAdvanced,
      customEnabledLayouts: customLayouts.map((name) => EditorLayoutVariant.values.firstWhere((e) => e.name == name, orElse: () => EditorLayoutVariant.classic)).toList(),
      customEnabledThemes: customThemes.map((name) => AppThemePreset.values.firstWhere((e) => e.name == name, orElse: () => AppThemePreset.none)).toList(),
      customEnabledTools: customTools,
      editorFontFamily: fontFamily,
      editorFontSize: fontSize,
      editorLineHeight: lineHeight,
    );
  }

  Future<void> saveSettings(AppSettingsModel settings) async {
    await sharedPrefs.setString(AppConstants.prefThemeMode, settings.themeMode.name);
    await sharedPrefs.setString(AppConstants.prefAccentColor, settings.accentColorHex);
    await sharedPrefs.setString(AppConstants.prefLayoutMode, settings.layoutMode.name);
    await sharedPrefs.setString(AppConstants.prefEditorMode, settings.editorMode.name);
    await sharedPrefs.setString(AppConstants.prefDefaultNoteType, settings.defaultNoteType.name);
    await sharedPrefs.setBool(AppConstants.prefAutoSave, settings.autoSaveEnabled);
    await sharedPrefs.setString(AppConstants.prefCodeTheme, settings.activeCodeTheme);
    await sharedPrefs.setString(AppConstants.prefEditorLayout, settings.editorLayout.name);
    await sharedPrefs.setString(AppConstants.prefThemePreset, settings.themePreset.name);
    await sharedPrefs.setString(AppConstants.prefUserMode, settings.userMode.name);
    await sharedPrefs.setBool(AppConstants.prefIsAdvancedMode, settings.isAdvancedMode);
    await sharedPrefs.setStringList(AppConstants.prefCustomEnabledLayouts, settings.customEnabledLayouts.map((e) => e.name).toList());
    await sharedPrefs.setStringList(AppConstants.prefCustomEnabledThemes, settings.customEnabledThemes.map((e) => e.name).toList());
    await sharedPrefs.setStringList(AppConstants.prefCustomEnabledTools, settings.customEnabledTools);
    await sharedPrefs.setString(AppConstants.prefEditorFontFamily, settings.editorFontFamily);
    await sharedPrefs.setDouble(AppConstants.prefEditorFontSize, settings.editorFontSize);
    await sharedPrefs.setDouble(AppConstants.prefEditorLineHeight, settings.editorLineHeight);
  }

  UserRole getUserRole() {
    final roleStr = sharedPrefs.getString(AppConstants.prefUserRole) ?? 'subscriber';
    return UserRole.values.firstWhere((e) => e.name == roleStr, orElse: () => UserRole.subscriber);
  }

  Future<void> saveUserRole(UserRole role) async {
    await sharedPrefs.setString(AppConstants.prefUserRole, role.name);
  }
}
