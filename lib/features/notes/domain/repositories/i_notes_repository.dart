/// Abstract repository contract for notes.
///
/// The domain layer depends on this interface, not on any concrete
/// implementation. This is the Dependency Inversion Principle in action.
///
/// Implementations live in the data layer:
/// - [NotesRepositoryImpl] — backed by [HiveLocalStorage]
/// - Future: CloudNotesRepository — backed by Firebase/Supabase
library i_notes_repository;

import '../../../../models/models.dart';

/// Contract that all note repositories must fulfill.
abstract class INotesRepository {
  /// Returns all notes, sorted by most recently updated first.
  List<NoteModel> getAllNotes();

  /// Persists a new note. Throws if a note with the same ID already exists.
  Future<void> createNote(NoteModel note);

  /// Updates an existing note. Throws if the note does not exist.
  Future<void> updateNote(NoteModel note);

  /// Deletes the note with the given [id].
  /// Does nothing if the note does not exist.
  Future<void> deleteNote(String id);

  /// Toggles the pinned state of the note with the given [id].
  Future<void> togglePin(String id);

  /// Toggles the favorite state of the note with the given [id].
  Future<void> toggleFavorite(String id);
}
