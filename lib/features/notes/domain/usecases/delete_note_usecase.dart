/// Use case: Delete a note by ID.
library;

import '../repositories/i_notes_repository.dart';

class DeleteNoteUseCase {
  const DeleteNoteUseCase(this._repository);

  final INotesRepository _repository;

  /// Deletes the note with the given [noteId].
  Future<void> call(String noteId) async {
    await _repository.deleteNote(noteId);
  }
}
