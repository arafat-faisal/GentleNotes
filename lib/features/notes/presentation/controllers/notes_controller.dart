/// Riverpod controllers and providers for the Notes feature.
///
/// This file is the single source of truth for note-related state in the
/// presentation layer. It wires together:
/// - [HiveLocalStorage] → [NotesLocalDatasource] → [NotesRepositoryImpl]
/// - All Riverpod providers consumed by screens and widgets
///
/// Controllers must NOT contain any UI code (no BuildContext, no widgets).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/storage/hive_local_storage.dart';
import '../../../../core/services/storage/i_local_storage.dart';
import '../../../../models/models.dart';
import '../../../folders/presentation/controllers/folders_controller.dart';
import '../../data/datasources/notes_local_datasource.dart';
import '../../data/repositories/notes_repository_impl.dart';
import '../../domain/repositories/i_notes_repository.dart';

// ── Dependency Injection Chain ───────────────────────────────────────────────

/// Provides the shared [ILocalStorage] singleton.
final storageProvider = Provider<ILocalStorage>((ref) => HiveLocalStorage());

/// Provides the [NotesLocalDatasource], injecting the storage backend.
final notesDatasourceProvider = Provider<NotesLocalDatasource>((ref) {
  final storage = ref.watch(storageProvider);
  return NotesLocalDatasource(storage);
});

/// Provides the [INotesRepository] implementation.
final notesRepositoryProvider = Provider<INotesRepository>((ref) {
  final datasource = ref.watch(notesDatasourceProvider);
  return NotesRepositoryImpl(datasource);
});

// ── State Notifier ────────────────────────────────────────────────────────────

/// Controller for all note CRUD operations.
///
/// Screens call methods on this notifier (via [notesProvider.notifier]).
/// They never interact with the repository or storage directly.
class NotesController extends StateNotifier<List<NoteModel>> {
  NotesController(this._repository) : super([]) {
    loadNotes();
  }

  final INotesRepository _repository;

  /// Loads all notes from the repository and updates state.
  void loadNotes() {
    state = _repository.getAllNotes();
  }

  /// Creates and persists a new note.
  Future<void> addNote(NoteModel note) async {
    await _repository.createNote(note);
    loadNotes();
  }

  /// Updates an existing note (content, title, tags, etc.).
  Future<void> updateNote(NoteModel note) async {
    await _repository.updateNote(note);
    loadNotes();
  }

  /// Permanently deletes a note by [id].
  Future<void> deleteNote(String id) async {
    await _repository.deleteNote(id);
    loadNotes();
  }

  /// Toggles the pinned state of a note.
  Future<void> togglePin(String id) async {
    await _repository.togglePin(id);
    loadNotes();
  }

  /// Toggles the favorite state of a note.
  Future<void> toggleFavorite(String id) async {
    await _repository.toggleFavorite(id);
    loadNotes();
  }

  /// Deletes multiple notes in batch.
  Future<void> deleteMultipleNotes(List<String> ids) async {
    for (final id in ids) {
      await _repository.deleteNote(id);
    }
    loadNotes();
  }

  /// Updates folder for multiple notes in batch.
  Future<void> moveNotesToFolder(List<String> ids, String? folderId) async {
    for (final id in ids) {
      final note = state.cast<NoteModel?>().firstWhere(
            (n) => n?.id == id,
            orElse: () => null,
          );
      if (note != null) {
        await _repository.updateNote(note.copyWith(
          folderId: folderId,
          clearFolder: folderId == null,
        ));
      }
    }
    loadNotes();
  }
}

/// Main provider for the complete list of notes.
final notesProvider =
    StateNotifierProvider<NotesController, List<NoteModel>>((ref) {
  final repository = ref.watch(notesRepositoryProvider);
  return NotesController(repository);
});

// ── Search & Filter State Providers ──────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedFolderFilterProvider = StateProvider<String?>((ref) => null);
final selectedTagFilterProvider = StateProvider<String?>((ref) => null);
final selectedTypeFilterProvider = StateProvider<NoteType?>((ref) => null);
final filterFavoriteProvider = StateProvider<bool>((ref) => false);
final filterPinnedProvider = StateProvider<bool>((ref) => false);

/// State provider to track selected note IDs for batch editing.
final selectedNoteIdsProvider = StateProvider<List<String>>((ref) => []);

// ── Derived Providers ─────────────────────────────────────────────────────────

Set<String> _getDescendantFolderIds(String parentId, List<FolderModel> folders) {
  final result = <String>{};
  void helper(String id) {
    for (var f in folders) {
      if (f.parentFolderId == id) {
        if (result.add(f.id)) {
          helper(f.id);
        }
      }
    }
  }
  helper(parentId);
  return result;
}

bool _folderOrAncestorMatches(String folderId, String search, List<FolderModel> folders) {
  FolderModel? findFolder(String id) {
    for (var f in folders) {
      if (f.id == id) return f;
    }
    return null;
  }
  var current = findFolder(folderId);
  while (current != null) {
    if (current.name.toLowerCase().contains(search)) {
      return true;
    }
    if (current.parentFolderId == null) break;
    current = findFolder(current.parentFolderId!);
  }
  return false;
}

/// 1. Raw Notes Provider: Alias for the base notes state list.
final rawNotesProvider = Provider<List<NoteModel>>((ref) {
  return ref.watch(notesProvider);
});

/// 2. Folder Filtered Provider: Filters notes based on selected folder (including nested descendant folders).
final folderFilteredProvider = Provider<List<NoteModel>>((ref) {
  final notes = ref.watch(rawNotesProvider);
  final folders = ref.watch(foldersProvider);
  final folderId = ref.watch(selectedFolderFilterProvider);

  if (folderId == null) return notes;

  final eligibleFolderIds = <String>{};
  eligibleFolderIds.add(folderId);
  eligibleFolderIds.addAll(_getDescendantFolderIds(folderId, folders));

  return notes.where((note) => note.folderId != null && eligibleFolderIds.contains(note.folderId)).toList();
});

/// 3. Metadata Filtered Provider: Filters notes by tags, note type, favorites, and pinned states.
final metadataFilteredProvider = Provider<List<NoteModel>>((ref) {
  final notes = ref.watch(folderFilteredProvider);
  final tag = ref.watch(selectedTagFilterProvider);
  final type = ref.watch(selectedTypeFilterProvider);
  final favoriteOnly = ref.watch(filterFavoriteProvider);
  final pinnedOnly = ref.watch(filterPinnedProvider);

  if (tag == null && type == null && !favoriteOnly && !pinnedOnly) return notes;

  return notes.where((note) {
    if (tag != null && !note.tags.contains(tag)) return false;
    if (type != null && note.noteType != type) return false;
    if (favoriteOnly && !note.isFavorite) return false;
    if (pinnedOnly && !note.isPinned) return false;
    return true;
  }).toList();
});

/// 4. Search Filtered Provider: Implements a tokenized relevance search index scoring algorithm.
final searchFilteredProvider = Provider<List<NoteModel>>((ref) {
  final notes = ref.watch(metadataFilteredProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final folders = ref.watch(foldersProvider);

  if (query.isEmpty) return notes;

  // Split query by whitespace to support multi-token search queries
  final tokens = query.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  if (tokens.isEmpty) return notes;

  final scoredNotes = <MapEntry<NoteModel, int>>[];

  for (final note in notes) {
    int score = 0;
    for (final token in tokens) {
      // Title match: +10 points
      if (note.title.toLowerCase().contains(token)) {
        score += 10;
      }
      // Tag match: +5 points
      if (note.tags.any((t) => t.toLowerCase().contains(token))) {
        score += 5;
      }
      // Folder or Ancestor name match: +3 points
      if (note.folderId != null && _folderOrAncestorMatches(note.folderId!, token, folders)) {
        score += 3;
      }
      // Content PlainText match: +2 points
      if (note.plainText.toLowerCase().contains(token)) {
        score += 2;
      }
    }

    if (score > 0) {
      scoredNotes.add(MapEntry(note, score));
    }
  }

  // Sort notes by relevance score descending
  scoredNotes.sort((a, b) => b.value.compareTo(a.value));
  return scoredNotes.map((e) => e.key).toList();
});

/// Final centralized filtered provider pointing to the end of the pipeline.
/// Replaces the old monolithic filteredNotesProvider so that existing visual templates compile cleanly.
final filteredNotesProvider = Provider<List<NoteModel>>((ref) {
  final notes = ref.watch(searchFilteredProvider);
  final pinned = notes.where((n) => n.isPinned).toList();
  final unpinned = notes.where((n) => !n.isPinned).toList();
  return [...pinned, ...unpinned];
});

/// Returns only pinned notes.
final pinnedNotesProvider = Provider<List<NoteModel>>((ref) {
  return ref.watch(notesProvider).where((n) => n.isPinned).toList();
});

/// Returns the [AppConstants.recentNotesLimit] most recently updated notes.
final recentNotesProvider = Provider<List<NoteModel>>((ref) {
  return ref.watch(notesProvider).take(AppConstants.recentNotesLimit).toList();
});
