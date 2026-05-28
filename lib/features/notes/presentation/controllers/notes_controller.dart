/// Riverpod controllers and providers for the Notes feature.
///
/// This file is the single source of truth for note-related state in the
/// presentation layer. It wires together:
/// - [HiveLocalStorage] → [NotesLocalDatasource] → [NotesRepositoryImpl]
/// - All Riverpod providers consumed by screens and widgets
///
/// Controllers must NOT contain any UI code (no BuildContext, no widgets).
library notes_controller;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/storage/hive_local_storage.dart';
import '../../../../core/services/storage/i_local_storage.dart';
import '../../../../models/models.dart';
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

// ── Derived Providers ─────────────────────────────────────────────────────────

/// Returns a filtered + sorted list of notes based on active filter state.
final filteredNotesProvider = Provider<List<NoteModel>>((ref) {
  final notes = ref.watch(notesProvider);
  final search = ref.watch(searchQueryProvider).toLowerCase();
  final folderId = ref.watch(selectedFolderFilterProvider);
  final tag = ref.watch(selectedTagFilterProvider);
  final type = ref.watch(selectedTypeFilterProvider);
  final favoriteOnly = ref.watch(filterFavoriteProvider);
  final pinnedOnly = ref.watch(filterPinnedProvider);

  return notes.where((note) {
    if (search.isNotEmpty) {
      final titleMatch = note.title.toLowerCase().contains(search);
      final contentMatch = note.plainText.toLowerCase().contains(search);
      final tagMatch = note.tags.any((t) => t.toLowerCase().contains(search));
      if (!titleMatch && !contentMatch && !tagMatch) return false;
    }
    if (folderId != null && note.folderId != folderId) return false;
    if (tag != null && !note.tags.contains(tag)) return false;
    if (type != null && note.noteType != type) return false;
    if (favoriteOnly && !note.isFavorite) return false;
    if (pinnedOnly && !note.isPinned) return false;
    return true;
  }).toList();
});

/// Returns only pinned notes.
final pinnedNotesProvider = Provider<List<NoteModel>>((ref) {
  return ref.watch(notesProvider).where((n) => n.isPinned).toList();
});

/// Returns the [AppConstants.recentNotesLimit] most recently updated notes.
final recentNotesProvider = Provider<List<NoteModel>>((ref) {
  return ref.watch(notesProvider).take(AppConstants.recentNotesLimit).toList();
});
