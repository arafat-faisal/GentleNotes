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

  Future<void> updateEditorFontFamily(String family) async {
    state = state.copyWith(editorFontFamily: family);
    await _repository.saveSettings(state);
  }

  Future<void> updateEditorFontSize(double size) async {
    state = state.copyWith(editorFontSize: size);
    await _repository.saveSettings(state);
  }

  Future<void> updateEditorLineHeight(double height) async {
    state = state.copyWith(editorLineHeight: height);
    await _repository.saveSettings(state);
  }

  Future<void> updateEditorLayout(EditorLayoutVariant variant) async {
    state = state.copyWith(editorLayout: variant);
    await _repository.saveSettings(state);
  }

  Future<void> updateThemePreset(AppThemePreset preset) async {
    state = state.copyWith(themePreset: preset);
    await _repository.saveSettings(state);
  }

  Future<void> updateUserMode(AppUserMode mode) async {
    await selectProfile(mode.name);
  }

  Future<void> selectProfile(String profileId) async {
    AppUserMode userMode = AppUserMode.custom;
    if (profileId == 'normal') userMode = AppUserMode.normal;
    else if (profileId == 'coder') userMode = AppUserMode.coder;
    else if (profileId == 'student') userMode = AppUserMode.student;
    else if (profileId == 'researcher') userMode = AppUserMode.researcher;

    state = state.copyWith(
      activeProfileId: profileId,
      userMode: userMode,
    );

    final allowedL = state.allowedLayouts;
    if (!allowedL.contains(state.editorLayout) && allowedL.isNotEmpty) {
      state = state.copyWith(
        editorLayout: allowedL.contains(state.profileDefaultLayout)
            ? state.profileDefaultLayout
            : allowedL.first,
      );
    }
    final allowedT = state.allowedThemes;
    if (!allowedT.contains(state.themePreset) && allowedT.isNotEmpty) {
      state = state.copyWith(
        themePreset: allowedT.contains(state.profileDefaultTheme)
            ? state.profileDefaultTheme
            : allowedT.first,
      );
    }
    await _repository.saveSettings(state);
  }

  Future<void> saveCustomProfile(CustomWorkspaceProfile profile) async {
    final list = List<CustomWorkspaceProfile>.from(state.customProfiles);
    final index = list.indexWhere((p) => p.id == profile.id);
    if (index >= 0) {
      list[index] = profile;
    } else {
      list.add(profile);
    }
    state = state.copyWith(customProfiles: list);
    await _repository.saveSettings(state);
  }

  Future<void> deleteCustomProfile(String profileId) async {
    final list = List<CustomWorkspaceProfile>.from(state.customProfiles);
    list.removeWhere((p) => p.id == profileId);
    state = state.copyWith(customProfiles: list);
    
    if (state.activeProfileId == profileId) {
      await selectProfile('normal');
    } else {
      await _repository.saveSettings(state);
    }
  }

  Future<void> updateIsAdvancedMode(bool value) async {
    state = state.copyWith(isAdvancedMode: value);
    if (!value) {
      final allowedL = state.allowedLayouts;
      if (!allowedL.contains(state.editorLayout)) {
        state = state.copyWith(
          editorLayout: allowedL.contains(state.profileDefaultLayout)
              ? state.profileDefaultLayout
              : (allowedL.isNotEmpty ? allowedL.first : EditorLayoutVariant.classic),
        );
      }
      final allowedT = state.allowedThemes;
      if (!allowedT.contains(state.themePreset)) {
        state = state.copyWith(
          themePreset: allowedT.contains(state.profileDefaultTheme)
              ? state.profileDefaultTheme
              : (allowedT.isNotEmpty ? allowedT.first : AppThemePreset.none),
        );
      }
    }
    await _repository.saveSettings(state);
  }

  Future<void> updateCustomEnabledLayouts(List<EditorLayoutVariant> layouts) async {
    state = state.copyWith(customEnabledLayouts: layouts);
    if (state.userMode == AppUserMode.custom && !layouts.contains(state.editorLayout)) {
      state = state.copyWith(editorLayout: layouts.isNotEmpty ? layouts.first : EditorLayoutVariant.classic);
    }
    await _repository.saveSettings(state);
  }

  Future<void> updateCustomEnabledThemes(List<AppThemePreset> themes) async {
    state = state.copyWith(customEnabledThemes: themes);
    if (state.userMode == AppUserMode.custom && !themes.contains(state.themePreset)) {
      state = state.copyWith(themePreset: themes.isNotEmpty ? themes.first : AppThemePreset.none);
    }
    await _repository.saveSettings(state);
  }

  Future<void> updateCustomEnabledTools(List<String> tools) async {
    state = state.copyWith(customEnabledTools: tools);
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
