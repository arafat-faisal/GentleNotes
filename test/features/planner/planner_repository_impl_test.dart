import 'package:flutter_test/flutter_test.dart';
import 'package:gentle_notes/core/services/storage/i_local_storage.dart';
import 'package:gentle_notes/features/planner/data/datasources/planner_local_datasource.dart';
import 'package:gentle_notes/features/planner/data/repositories/planner_repository_impl.dart';
import 'package:gentle_notes/features/planner/domain/entities/planner_enums.dart';
import 'package:gentle_notes/features/planner/domain/entities/planner_item_entity.dart';
import 'package:gentle_notes/models/models.dart';
import 'package:gentle_notes/features/pdf_viewer/data/models/pdf_annotation_model.dart';
import 'package:gentle_notes/features/pdf_viewer/data/models/pdf_bookmark_model.dart';

class FakeLocalStorage implements ILocalStorage {
  final Map<String, PlannerItemEntity> _plannerItems = {};

  @override
  List<PlannerItemEntity> getPlannerItems() => _plannerItems.values.toList();

  @override
  Future<void> savePlannerItem(PlannerItemEntity item) async {
    _plannerItems[item.id] = item;
  }

  @override
  Future<void> deletePlannerItem(String id) async {
    _plannerItems.remove(id);
  }

  // ── Unimplemented ILocalStorage requirements ───────────────────────────────
  @override
  Future<void> init() async {}
  
  @override
  AppSettingsModel getSettings() => AppSettingsModel(
        themeMode: ThemeModeSetting.system,
        accentColorHex: '#6366F1',
        layoutMode: LayoutMode.grid,
        editorMode: EditorMode.gentleNote,
        defaultNoteType: NoteType.mixed,
        autoSaveEnabled: true,
        activeCodeTheme: 'vs-dark',
      );
  @override
  Future<void> saveSettings(AppSettingsModel settings) async {}
  @override
  UserRole getUserRole() => UserRole.freeUser;
  @override
  Future<void> saveUserRole(UserRole role) async {}

  @override
  List<FolderModel> getFolders() => [];
  @override
  Future<void> saveFolder(FolderModel folder) async {}
  @override
  Future<void> deleteFolder(String id) async {}
  @override
  List<NoteModel> getNotes() => [];
  @override
  Future<void> saveNote(NoteModel note) async {}
  @override
  Future<void> deleteNote(String id) async {}
  @override
  List<NoteTemplateModel> getTemplates() => [];
  @override
  Future<void> saveTemplate(NoteTemplateModel template) async {}
  @override
  Future<void> deleteTemplate(String id) async {}

  @override
  List<PdfAnnotationModel> getPdfAnnotations(String pdfPath) => [];
  @override
  Future<void> savePdfAnnotation(PdfAnnotationModel annotation) async {}
  @override
  Future<void> deletePdfAnnotation(String id) async {}

  @override
  List<PdfBookmarkModel> getPdfBookmarks(String pdfPath) => [];
  @override
  Future<void> savePdfBookmark(PdfBookmarkModel bookmark) async {}
  @override
  Future<void> deletePdfBookmark(String id) async {}
}

void main() {
  group('PlannerRepositoryImpl Tests', () {
    late FakeLocalStorage fakeStorage;
    late PlannerLocalDatasource datasource;
    late PlannerRepositoryImpl repository;

    final now = DateTime.now();
    final item1 = PlannerItemEntity(
      id: 'id-1',
      title: 'Item One',
      type: PlannerItemType.task,
      date: DateTime(2026, 6, 10),
      startTime: 500,
      createdAt: now,
      updatedAt: now,
    );
    final item2 = PlannerItemEntity(
      id: 'id-2',
      title: 'Item Two',
      type: PlannerItemType.meeting,
      date: DateTime(2026, 6, 11),
      startTime: 600,
      createdAt: now,
      updatedAt: now,
    );

    setUp(() {
      fakeStorage = FakeLocalStorage();
      datasource = PlannerLocalDatasource(fakeStorage);
      repository = PlannerRepositoryImpl(datasource);
    });

    test('getAll should return all planner items', () async {
      await repository.create(item1);
      await repository.create(item2);

      final items = repository.getAll();
      expect(items.length, 2);
      expect(items.map((e) => e.id), containsAll(['id-1', 'id-2']));
    });

    test('getById should return specific item or null', () async {
      await repository.create(item1);

      expect(repository.getById('id-1'), isNotNull);
      expect(repository.getById('id-1')!.title, 'Item One');
      expect(repository.getById('non-existent'), isNull);
    });

    test('getByDateRange should filter items', () async {
      await repository.create(item1);
      await repository.create(item2);

      final filtered = repository.getByDateRange(
        DateTime(2026, 6, 11),
        DateTime(2026, 6, 12),
      );
      expect(filtered.length, 1);
      expect(filtered.first.id, 'id-2');
    });

    test('markCompleted should toggle status between completed and upcoming', () async {
      await repository.create(item1);
      expect(repository.getById('id-1')!.status, PlannerStatus.upcoming);

      // Toggle to completed
      await repository.markCompleted('id-1');
      expect(repository.getById('id-1')!.status, PlannerStatus.completed);

      // Toggle back to upcoming (undo completion)
      await repository.markCompleted('id-1');
      expect(repository.getById('id-1')!.status, PlannerStatus.upcoming);
    });

    test('delete should remove the item', () async {
      await repository.create(item1);
      expect(repository.getById('id-1'), isNotNull);

      await repository.delete('id-1');
      expect(repository.getById('id-1'), isNull);
    });
  });
}
