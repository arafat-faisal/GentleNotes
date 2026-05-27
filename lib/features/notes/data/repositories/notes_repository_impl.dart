/// Concrete implementation of [INotesRepository] backed by local Hive storage.
///
/// This class bridges the domain layer's [INotesRepository] contract with the
/// actual data layer ([NotesLocalDatasource]).
///
/// When cloud sync is added:
/// 1. Create a `CloudNotesRepository` that implements [INotesRepository].
/// 2. Create a `SyncedNotesRepository` that composes local + cloud sources.
/// 3. Update [notesRepositoryProvider] to inject the new implementation.
/// 4. Zero changes needed in the domain or presentation layers.
library notes_repository_impl;

import '../../../../models/models.dart';
import '../../domain/repositories/i_notes_repository.dart';
import '../datasources/notes_local_datasource.dart';

class NotesRepositoryImpl implements INotesRepository {
  const NotesRepositoryImpl(this._datasource);

  final NotesLocalDatasource _datasource;

  @override
  List<NoteModel> getAllNotes() => _datasource.getAllNotes();

  @override
  Future<void> createNote(NoteModel note) => _datasource.saveNote(note);

  @override
  Future<void> updateNote(NoteModel note) => _datasource.saveNote(note);

  @override
  Future<void> deleteNote(String id) => _datasource.deleteNote(id);

  @override
  Future<void> togglePin(String id) async {
    final notes = _datasource.getAllNotes();
    final note = notes.firstWhere((n) => n.id == id);
    final updated = note.copyWith(
      isPinned: !note.isPinned,
      updatedAt: DateTime.now(),
    );
    await _datasource.saveNote(updated);
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final notes = _datasource.getAllNotes();
    final note = notes.firstWhere((n) => n.id == id);
    final updated = note.copyWith(
      isFavorite: !note.isFavorite,
      updatedAt: DateTime.now(),
    );
    await _datasource.saveNote(updated);
  }
}
