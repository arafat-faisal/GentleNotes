import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/local_storage.dart';
import '../../../models/models.dart';

class NotesNotifier extends StateNotifier<List<NoteModel>> {
  final LocalStorage _storage;

  NotesNotifier(this._storage) : super([]) {
    loadNotes();
  }

  void loadNotes() {
    state = _storage.getNotes();
  }

  Future<void> addNote(NoteModel note) async {
    await _storage.saveNote(note);
    loadNotes();
  }

  Future<void> updateNote(NoteModel note) async {
    await _storage.saveNote(note);
    loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await _storage.deleteNote(id);
    loadNotes();
  }

  Future<void> togglePin(String id) async {
    final note = state.firstWhere((n) => n.id == id);
    final updated = note.copyWith(isPinned: !note.isPinned, updatedAt: DateTime.now());
    await _storage.saveNote(updated);
    loadNotes();
  }

  Future<void> toggleFavorite(String id) async {
    final note = state.firstWhere((n) => n.id == id);
    final updated = note.copyWith(isFavorite: !note.isFavorite, updatedAt: DateTime.now());
    await _storage.saveNote(updated);
    loadNotes();
  }
}

// Storage injection
final notesStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage();
});

// All notes provider
final notesProvider = StateNotifierProvider<NotesNotifier, List<NoteModel>>((ref) {
  final storage = ref.watch(notesStorageProvider);
  return NotesNotifier(storage);
});

// Search & Filter state providers
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedFolderFilterProvider = StateProvider<String?>((ref) => null);
final selectedTagFilterProvider = StateProvider<String?>((ref) => null);
final selectedTypeFilterProvider = StateProvider<NoteType?>((ref) => null);
final filterFavoriteProvider = StateProvider<bool>((ref) => false);
final filterPinnedProvider = StateProvider<bool>((ref) => false);

// Filtered notes provider
final filteredNotesProvider = Provider<List<NoteModel>>((ref) {
  final notes = ref.watch(notesProvider);
  final search = ref.watch(searchQueryProvider).toLowerCase();
  final folderId = ref.watch(selectedFolderFilterProvider);
  final tag = ref.watch(selectedTagFilterProvider);
  final type = ref.watch(selectedTypeFilterProvider);
  final favoriteOnly = ref.watch(filterFavoriteProvider);
  final pinnedOnly = ref.watch(filterPinnedProvider);

  return notes.where((note) {
    // Search query match
    if (search.isNotEmpty) {
      final titleMatch = note.title.toLowerCase().contains(search);
      final contentMatch = note.content.toLowerCase().contains(search);
      final tagMatch = note.tags.any((t) => t.toLowerCase().contains(search));
      if (!titleMatch && !contentMatch && !tagMatch) {
        return false;
      }
    }

    // Folder match
    if (folderId != null && note.folderId != folderId) {
      return false;
    }

    // Tag match
    if (tag != null && !note.tags.contains(tag)) {
      return false;
    }

    // Type match
    if (type != null && note.noteType != type) {
      return false;
    }

    // Favorite filter
    if (favoriteOnly && !note.isFavorite) {
      return false;
    }

    // Pinned filter
    if (pinnedOnly && !note.isPinned) {
      return false;
    }

    return true;
  }).toList();
});

// Pinned notes provider
final pinnedNotesProvider = Provider<List<NoteModel>>((ref) {
  final notes = ref.watch(notesProvider);
  return notes.where((n) => n.isPinned).toList();
});

// Recent notes provider (non-pinned, limited to 5)
final recentNotesProvider = Provider<List<NoteModel>>((ref) {
  final notes = ref.watch(notesProvider);
  // Pinned are already prominent elsewhere, so filter them or keep them sorted.
  // We'll return the 5 most recently updated notes.
  return notes.take(5).toList();
});
