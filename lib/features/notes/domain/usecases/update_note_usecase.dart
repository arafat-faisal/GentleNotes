/// Use case: Update an existing note.
library;

import '../../../../models/models.dart';
import '../repositories/i_notes_repository.dart';

class UpdateNoteUseCase {
  const UpdateNoteUseCase(this._repository);

  final INotesRepository _repository;

  /// Saves the updated [note] and stamps the current time as [updatedAt].
  Future<NoteModel> call(NoteModel note) async {
    final updated = note.copyWith(updatedAt: DateTime.now());
    await _repository.updateNote(updated);
    return updated;
  }
}
