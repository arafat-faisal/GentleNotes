/// Abstract interface for local persistence.
///
/// Any concrete implementation (Hive, SQLite, Drift, in-memory for tests)
/// must satisfy this contract. This enables:
/// - Easy unit testing via mock implementations
/// - Future migration to a different storage backend without touching UI code
/// - Clear separation between "what we need" (domain) and "how we do it" (data)
library i_local_storage;

import '../../../models/models.dart';

abstract class ILocalStorage {
  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Initializes the storage backend. Must be called before any other method.
  Future<void> init();

  // ── Settings ───────────────────────────────────────────────────────────────

  AppSettingsModel getSettings();
  Future<void> saveSettings(AppSettingsModel settings);

  // ── User Role ──────────────────────────────────────────────────────────────

  UserRole getUserRole();
  Future<void> saveUserRole(UserRole role);

  // ── Folders ────────────────────────────────────────────────────────────────

  List<FolderModel> getFolders();
  Future<void> saveFolder(FolderModel folder);
  Future<void> deleteFolder(String id);

  // ── Notes ──────────────────────────────────────────────────────────────────

  List<NoteModel> getNotes();
  Future<void> saveNote(NoteModel note);
  Future<void> deleteNote(String id);

  // ── Templates ──────────────────────────────────────────────────────────────

  List<NoteTemplateModel> getTemplates();
  Future<void> saveTemplate(NoteTemplateModel template);
  Future<void> deleteTemplate(String id);
}
