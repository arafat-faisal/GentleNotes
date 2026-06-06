import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/block_entity.dart';
import '../../domain/entities/block_type.dart';
import 'editor_block_state.dart';
import 'editor_core_controller.dart';
import 'editor_history_controller.dart';
import 'editor_selection_controller.dart';

class EditorBlockController extends EditorCoreController {
  late final EditorHistoryController _historyController;
  late final EditorSelectionController _selectionController;

  EditorBlockController() {
    _historyController = EditorHistoryController(this);
    _selectionController = EditorSelectionController(this);
  }

  void insertBlock(
    int index,
    BlockType type, {
    String content = '',
    Map<String, dynamic>? data,
    Map<String, dynamic> attributes = const {},
  }) {
    _historyController.saveToUndoStack();
    final newBlock = BlockEntity.create(
      type,
      content: content,
      data: data,
      attrs: attributes,
    );
    insertBlockDirectly(index + 1, newBlock);

    if (type != BlockType.text && type != BlockType.heading) {
      final trailingText = BlockEntity.create(BlockType.text);
      insertBlockDirectly(index + 2, trailingText);
    }
  }

  void replaceBlock(String id, BlockEntity newBlock) {
    _historyController.saveToUndoStack();
    super.replaceBlockDirectly(id, newBlock);
  }

  void updateBlockData(String id, Map<String, dynamic> data) {
    _historyController.saveToUndoStack();
    super.updateBlockData(id, data);
  }

  void removeBlock(String id) {
    if (state.blocks.length <= 1) return;
    _historyController.saveToUndoStack();
    removeBlockDirectly(id);
  }

  void reorderBlocks(int oldIndex, int newIndex) {
    _historyController.saveToUndoStack();
    reorderBlocksDirectly(oldIndex, newIndex);
  }

  void undo() {
    _historyController.undo();
  }

  void redo() {
    _historyController.redo();
  }

  void selectBlock(int index) {
    _selectionController.selectBlock(index);
  }

  void clearSelection() {
    _selectionController.clearSelection();
  }
}

final editorBlockControllerProvider = StateNotifierProvider.autoDispose<EditorBlockController, EditorBlockState>((ref) {
  return EditorBlockController();
});
