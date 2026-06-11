/// Use case: Create a new note.
///
/// Encapsulates the business logic for creating a note, including validation.
/// Controllers call this use case, not the repository directly.
///
/// Following Single Responsibility Principle — this class does one thing only.
library;

import 'package:uuid/uuid.dart';
import '../../../../models/models.dart';
import '../repositories/i_notes_repository.dart';

class CreateNoteUseCase {
  const CreateNoteUseCase(this._repository);

  final INotesRepository _repository;

  /// Creates a new [NoteModel] with the given parameters and persists it.
  ///
  /// A new UUID is generated automatically. [createdAt] and [updatedAt]
  /// are set to the current time.
  ///
  /// Returns the newly created [NoteModel].
  Future<NoteModel> call({
    required String title,
    required String content,
    required NoteType noteType,
    String? folderId,
    String? templateId,
    List<String> tags = const [],
    List<AttachmentModel> attachments = const [],
    bool isPinned = false,
    bool isFavorite = false,
    String colorHex = '#FFFFFF',
  }) async {
    if (title.trim().isEmpty && content.trim().isEmpty) {
      throw ArgumentError('A note must have at least a title or content.');
    }

    final note = NoteModel(
      id: const Uuid().v4(),
      folderId: folderId,
      title: title.trim(),
      content: content,
      noteType: noteType,
      tags: tags,
      attachments: attachments,
      templateId: templateId,
      isPinned: isPinned,
      isFavorite: isFavorite,
      colorHex: colorHex,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repository.createNote(note);
    return note;
  }
}
