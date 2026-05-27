/// Riverpod controllers and providers for the Settings feature.
library settings_controller;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/storage/hive_local_storage.dart';
import '../../../../core/services/storage/i_local_storage.dart';
import '../../../../models/models.dart';
import '../../data/repositories/settings_repository_impl.dart';

// ── Dependency Injection ──────────────────────────────────────────────────────

final _settingsStorageProvider = Provider<ILocalStorage>((ref) => HiveLocalStorage());

final settingsRepositoryImplProvider = Provider<SettingsRepositoryImpl>((ref) {
  final storage = ref.watch(_settingsStorageProvider);
  return SettingsRepositoryImpl(storage);
});

// ── Settings Notifier ─────────────────────────────────────────────────────────

/// Controller for app settings state.
///
/// Writes are persisted immediately after updating local state so the UI
/// reflects changes without waiting for a refresh.
class SettingsNotifier extends StateNotifier<AppSettingsModel> {
  SettingsNotifier(this._repository) : super(_repository.getSettings());

  final SettingsRepositoryImpl _repository;

  Future<void> updateThemeMode(ThemeModeSetting themeMode) async {
    state = state.copyWith(themeMode: themeMode);
    await _repository.saveSettings(state);
  }

  Future<void> updateAccentColor(String colorHex) async {
    state = state.copyWith(accentColorHex: colorHex);
    await _repository.saveSettings(state);
  }

  Future<void> updateLayoutMode(LayoutMode layoutMode) async {
    state = state.copyWith(layoutMode: layoutMode);
    await _repository.saveSettings(state);
  }

  Future<void> updateEditorMode(EditorMode editorMode) async {
    state = state.copyWith(editorMode: editorMode);
    await _repository.saveSettings(state);
  }

  Future<void> updateDefaultNoteType(NoteType defaultNoteType) async {
    state = state.copyWith(defaultNoteType: defaultNoteType);
    await _repository.saveSettings(state);
  }

  Future<void> toggleAutoSave(bool autoSave) async {
    state = state.copyWith(autoSaveEnabled: autoSave);
    await _repository.saveSettings(state);
  }

  Future<void> updateActiveCodeTheme(String codeTheme) async {
    state = state.copyWith(activeCodeTheme: codeTheme);
    await _repository.saveSettings(state);
  }
}

/// Provides the current [AppSettingsModel].
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettingsModel>((ref) {
  final repository = ref.watch(settingsRepositoryImplProvider);
  return SettingsNotifier(repository);
});

// ── User Role Notifier ────────────────────────────────────────────────────────

class UserRoleNotifier extends StateNotifier<UserRole> {
  UserRoleNotifier(this._repository) : super(_repository.getUserRole());

  final SettingsRepositoryImpl _repository;

  Future<void> updateRole(UserRole role) async {
    state = role;
    await _repository.saveUserRole(role);
  }
}

/// Provides the current [UserRole].
final userRoleProvider =
    StateNotifierProvider<UserRoleNotifier, UserRole>((ref) {
  final repository = ref.watch(settingsRepositoryImplProvider);
  return UserRoleNotifier(repository);
});
