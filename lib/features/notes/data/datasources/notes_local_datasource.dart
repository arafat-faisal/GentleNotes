/// Local data source for notes operations.
///
/// This class is the lowest-level data accessor for notes within the data
/// layer. It wraps [HiveLocalStorage] and translates raw storage calls into
/// typed [NoteModel] operations.
///
/// Responsibilities:
/// - Read/write notes via the storage interface
/// - No business logic lives here — filtering and validation belong in use cases
library notes_local_datasource;

import '../../../../core/services/storage/i_local_storage.dart';
import '../../../../models/models.dart';

class NotesLocalDatasource {
  const NotesLocalDatasource(this._storage);

  /// The storage backend (injected via constructor for testability).
  final ILocalStorage _storage;

  List<NoteModel> getAllNotes() => _storage.getNotes();

  Future<void> saveNote(NoteModel note) => _storage.saveNote(note);

  Future<void> deleteNote(String id) => _storage.deleteNote(id);
}
