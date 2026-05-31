import '../entities/block_entity.dart';

abstract class IEditorRepository {
  Future<List<BlockEntity>> loadDocument(String id);
  Future<void> saveDocument(String id, List<BlockEntity> blocks);
}
