/// Use case: Retrieve and filter notes.
///
/// Encapsulates all filtering logic so it lives in the domain layer,
/// not scattered across UI controllers.
library get_notes_usecase;

import '../../../../models/models.dart';
import '../repositories/i_notes_repository.dart';

/// Parameters for filtering a list of notes.
class GetNotesParams {
  const GetNotesParams({
    this.searchQuery = '',
    this.folderId,
    this.tag,
    this.noteType,
    this.favoritesOnly = false,
    this.pinnedOnly = false,
  });

  final String searchQuery;
  final String? folderId;
  final String? tag;
  final NoteType? noteType;
  final bool favoritesOnly;
  final bool pinnedOnly;

  /// Returns true when no filters are active.
  bool get isEmpty =>
      searchQuery.isEmpty &&
      folderId == null &&
      tag == null &&
      noteType == null &&
      !favoritesOnly &&
      !pinnedOnly;
}

class GetNotesUseCase {
  const GetNotesUseCase(this._repository);

  final INotesRepository _repository;

  /// Returns all notes that match the given [params].
  ///
  /// When [params] is empty (default), all notes are returned sorted by
  /// most recently updated first.
  List<NoteModel> call([GetNotesParams params = const GetNotesParams()]) {
    var notes = _repository.getAllNotes();

    if (params.isEmpty) return notes;

    return notes.where((note) {
      // Search query — matches title, content, or tags
      if (params.searchQuery.isNotEmpty) {
        final q = params.searchQuery.toLowerCase();
        final titleMatch = note.title.toLowerCase().contains(q);
        final contentMatch = note.content.toLowerCase().contains(q);
        final tagMatch = note.tags.any((t) => t.toLowerCase().contains(q));
        if (!titleMatch && !contentMatch && !tagMatch) return false;
      }

      // Folder filter
      if (params.folderId != null && note.folderId != params.folderId) {
        return false;
      }

      // Tag filter
      if (params.tag != null && !note.tags.contains(params.tag)) {
        return false;
      }

      // Note type filter
      if (params.noteType != null && note.noteType != params.noteType) {
        return false;
      }

      // Favorites only
      if (params.favoritesOnly && !note.isFavorite) return false;

      // Pinned only
      if (params.pinnedOnly && !note.isPinned) return false;

      return true;
    }).toList();
  }
}
