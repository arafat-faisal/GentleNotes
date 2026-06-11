/// Concrete implementation of the settings repository backed by local storage.
library;

import '../../../../core/services/storage/i_local_storage.dart';
import '../../../../models/models.dart';

/// Handles persistence of [AppSettingsModel] and [UserRole].
class SettingsRepositoryImpl {
  const SettingsRepositoryImpl(this._storage);

  final ILocalStorage _storage;

  AppSettingsModel getSettings() => _storage.getSettings();
  Future<void> saveSettings(AppSettingsModel settings) => _storage.saveSettings(settings);

  UserRole getUserRole() => _storage.getUserRole();
  Future<void> saveUserRole(UserRole role) => _storage.saveUserRole(role);
}
