import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/export_import_service.dart';
import '../../../../models/models.dart';
import '../../../folders/presentation/controllers/folders_controller.dart';
import '../../../notes/presentation/controllers/notes_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import 'folder_form_dialog.dart';

/// Delegate for all home screen interactions and user action callbacks.
/// 
/// Implementing the Strategy Pattern, this class isolates visual presentation templates
/// from routing, file picking, and DB write modifications. All layouts delegate actions
/// to this centralized provider.
class HomeActionDelegate {
  const HomeActionDelegate();

  /// Navigates to the note editor for editing an existing note.
  void onNoteTap(BuildContext context, String noteId) {
    context.push('/notes/edit/$noteId');
  }

  /// Navigates to a folder's detail screen.
  void onFolderTap(BuildContext context, String folderId) {
    context.go('/folders/$folderId');
  }

  /// Initiates creation of a new note, optionally with a pre-selected folder or template.
  void onCreateNote(BuildContext context, {String? folderId, String? templateId}) {
    final queryParams = <String, String>{};
    if (folderId != null) queryParams['folderId'] = folderId;
    if (templateId != null) queryParams['templateId'] = templateId;
    
    final uri = Uri(
      path: '/notes/create',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    context.push(uri.toString());
  }

  /// Navigates to global Settings screen.
  void onSettingsTap(BuildContext context) {
    context.go('/settings');
  }

  /// Navigates to templates gallery screen.
  void onTemplatesTap(BuildContext context) {
    context.go('/templates');
  }

  /// Navigates to Calendar workspace screen.
  void onCalendarTap(BuildContext context) {
    context.go('/calendar');
  }

  /// Navigates to Daily Planner workspace screen.
  void onPlannerTap(BuildContext context) {
    context.go('/planner');
  }

  /// Navigates to Goals Dashboard.
  void onGoalsTap(BuildContext context) {
    context.go('/goals');
  }

  /// Prompts a file selector dialog to load an external JSON backup file.
  Future<void> onImportBackup(BuildContext context, WidgetRef ref) async {
    final success = await ExportImportService().pickAndImportFile();
    if (!context.mounted) return;
    if (success) {
      ref.read(foldersProvider.notifier).loadFolders();
      ref.read(notesProvider.notifier).loadNotes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Import completed successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to import file or cancelled.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// Displays the interactive dialog to create a new folder card.
  void onFolderCreate(BuildContext context) {
    FolderFormDialog.show(context);
  }

  /// Toggles the folder layout mode setting between Grid and List view configurations.
  void onToggleFolderLayoutMode(WidgetRef ref, LayoutMode currentMode) {
    final newMode = currentMode == LayoutMode.grid ? LayoutMode.list : LayoutMode.grid;
    ref.read(settingsProvider.notifier).updateLayoutMode(newMode);
  }

  /// Programmatically swaps the current home dashboard layout preset.
  void onUpdateHomeLayout(WidgetRef ref, HomeLayoutPreset preset) {
    ref.read(settingsProvider.notifier).updateHomeLayout(preset);
  }

  /// Resets all search queries, folder filters, tag filters, and metadata toggles.
  void onResetAllFilters(WidgetRef ref) {
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(selectedFolderFilterProvider.notifier).state = null;
    ref.read(selectedTagFilterProvider.notifier).state = null;
    ref.read(selectedTypeFilterProvider.notifier).state = null;
    ref.read(filterFavoriteProvider.notifier).state = false;
    ref.read(filterPinnedProvider.notifier).state = false;
  }

  /// Selects a specific folder filter to focus the note stream.
  void onSelectFolderFilter(WidgetRef ref, String? folderId) {
    ref.read(selectedFolderFilterProvider.notifier).state = folderId;
  }

  /// Selects a specific tag filter to focus the note stream.
  void onSelectTagFilter(WidgetRef ref, String? tag) {
    ref.read(selectedTagFilterProvider.notifier).state = tag;
  }

  /// Toggles the favorite notes filter constraint.
  void onToggleFavoriteFilter(WidgetRef ref, bool favoriteOnly) {
    ref.read(filterFavoriteProvider.notifier).state = !favoriteOnly;
  }

  /// Toggles the pinned notes filter constraint.
  void onTogglePinnedFilter(WidgetRef ref, bool pinnedOnly) {
    ref.read(filterPinnedProvider.notifier).state = !pinnedOnly;
  }

  /// Toggles the pinned state of a note.
  Future<void> onNotePinToggle(WidgetRef ref, String noteId) async {
    await ref.read(notesProvider.notifier).togglePin(noteId);
  }

  /// Toggles the favorite state of a note.
  Future<void> onNoteFavoriteToggle(WidgetRef ref, String noteId) async {
    await ref.read(notesProvider.notifier).toggleFavorite(noteId);
  }

  /// Permanently deletes a single note.
  Future<void> onNoteDelete(WidgetRef ref, String noteId) async {
    await ref.read(notesProvider.notifier).deleteNote(noteId);
  }

  /// Moves a note into a specific folder destination.
  Future<void> onNoteMoveToFolder(WidgetRef ref, String noteId, String? folderId) async {
    final note = ref.read(notesProvider).cast<NoteModel?>().firstWhere(
          (n) => n?.id == noteId,
          orElse: () => null,
        );
    if (note != null) {
      await ref.read(notesProvider.notifier).updateNote(note.copyWith(
        folderId: folderId,
        clearFolder: folderId == null,
      ));
    }
  }
}

/// Global provider to access the HomeActionDelegate instance.
final homeActionDelegateProvider = Provider<HomeActionDelegate>((ref) {
  return const HomeActionDelegate();
});
