import '../../domain/entities/block_entity.dart';
import '../../domain/repositories/i_editor_repository.dart';
import '../../domain/usecases/convert_delta_to_blocks.dart';
import '../../domain/usecases/convert_blocks_to_delta.dart';
import '../../../../core/services/storage/i_local_storage.dart';

class EditorRepositoryImpl implements IEditorRepository {
  final ILocalStorage _storage;

  EditorRepositoryImpl(this._storage);

  @override
  Future<List<BlockEntity>> loadDocument(String id) async {
    final notes = _storage.getNotes();
    try {
      final note = notes.firstWhere((n) => n.id == id);
      return ConvertDeltaToBlocks.execute(note.content);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveDocument(String id, List<BlockEntity> blocks) async {
    final notes = _storage.getNotes();
    try {
      final note = notes.firstWhere((n) => n.id == id);
      final updatedContent = ConvertBlocksToDelta.execute(blocks);
      final updatedNote = note.copyWith(
        content: updatedContent,
        updatedAt: DateTime.now(),
      );
      await _storage.saveNote(updatedNote);
    } catch (_) {
      // Note not found or storage error
    }
  }
}
