import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/local_storage.dart';
import '../../../models/models.dart';

class SettingsNotifier extends StateNotifier<AppSettingsModel> {
  final LocalStorage _storage;

  SettingsNotifier(this._storage) : super(_storage.getSettings());

  Future<void> updateThemeMode(ThemeModeSetting themeMode) async {
    final updated = state.copyWith(themeMode: themeMode);
    state = updated;
    await _storage.saveSettings(updated);
  }

  Future<void> updateAccentColor(String colorHex) async {
    final updated = state.copyWith(accentColorHex: colorHex);
    state = updated;
    await _storage.saveSettings(updated);
  }

  Future<void> updateLayoutMode(LayoutMode layoutMode) async {
    final updated = state.copyWith(layoutMode: layoutMode);
    state = updated;
    await _storage.saveSettings(updated);
  }

  Future<void> updateEditorMode(EditorMode editorMode) async {
    final updated = state.copyWith(editorMode: editorMode);
    state = updated;
    await _storage.saveSettings(updated);
  }

  Future<void> updateDefaultNoteType(NoteType defaultNoteType) async {
    final updated = state.copyWith(defaultNoteType: defaultNoteType);
    state = updated;
    await _storage.saveSettings(updated);
  }

  Future<void> toggleAutoSave(bool autoSave) async {
    final updated = state.copyWith(autoSaveEnabled: autoSave);
    state = updated;
    await _storage.saveSettings(updated);
  }

  Future<void> updateActiveCodeTheme(String codeTheme) async {
    final updated = state.copyWith(activeCodeTheme: codeTheme);
    state = updated;
    await _storage.saveSettings(updated);
  }
}

class UserRoleNotifier extends StateNotifier<UserRole> {
  final LocalStorage _storage;

  UserRoleNotifier(this._storage) : super(_storage.getUserRole());

  Future<void> updateRole(UserRole role) async {
    state = role;
    await _storage.saveUserRole(role);
  }
}

final settingsStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage();
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettingsModel>((ref) {
  final storage = ref.watch(settingsStorageProvider);
  return SettingsNotifier(storage);
});

final userRoleProvider = StateNotifierProvider<UserRoleNotifier, UserRole>((ref) {
  final storage = ref.watch(settingsStorageProvider);
  return UserRoleNotifier(storage);
});
