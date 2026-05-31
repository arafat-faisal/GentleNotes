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
  }

  UserRole getUserRole() {
    final roleStr = sharedPrefs.getString(AppConstants.prefUserRole) ?? 'subscriber';
    return UserRole.values.firstWhere((e) => e.name == roleStr, orElse: () => UserRole.subscriber);
  }

  Future<void> saveUserRole(UserRole role) async {
    await sharedPrefs.setString(AppConstants.prefUserRole, role.name);
  }
}
