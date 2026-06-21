/// Abstract interface for local persistence.
///
/// Any concrete implementation (Hive, SQLite, Drift, in-memory for tests)
/// must satisfy this contract. This enables:
/// - Easy unit testing via mock implementations
/// - Future migration to a different storage backend without touching UI code
/// - Clear separation between "what we need" (domain) and "how we do it" (data)
library;

import '../../../models/models.dart';
import '../../../features/planner/domain/entities/planner_item_entity.dart';
import '../../../features/pdf_viewer/data/models/pdf_annotation_model.dart';
import '../../../features/pdf_viewer/data/models/pdf_bookmark_model.dart';

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

  // ── Planner ────────────────────────────────────────────────────────────────

  List<PlannerItemEntity> getPlannerItems();
  Future<void> savePlannerItem(PlannerItemEntity item);
  Future<void> deletePlannerItem(String id);

  // ── PDF Viewer Annotations & Bookmarks ──────────────────────────────────────
  List<PdfAnnotationModel> getPdfAnnotations(String pdfPath);
  Future<void> savePdfAnnotation(PdfAnnotationModel annotation);
  Future<void> deletePdfAnnotation(String id);

  List<PdfBookmarkModel> getPdfBookmarks(String pdfPath);
  Future<void> savePdfBookmark(PdfBookmarkModel bookmark);
  Future<void> deletePdfBookmark(String id);
}

