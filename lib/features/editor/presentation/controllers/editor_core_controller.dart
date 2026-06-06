import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/block_entity.dart';
import '../../domain/entities/block_type.dart';
import 'editor_block_state.dart';

class EditorCoreController extends StateNotifier<EditorBlockState> {
  EditorCoreController() : super(EditorBlockState(blocks: [BlockEntity.create(BlockType.text)]));

  void initializeWithBlocks(List<BlockEntity> blocks) {
    state = EditorBlockState(
      blocks: blocks.isEmpty ? [BlockEntity.create(BlockType.text)] : blocks,
      selectedIndex: -1,
      isDirty: false,
      undoStack: [],
      redoStack: [],
    );
  }

  void updateBlockContent(String id, String newContent) {
    final updatedBlocks = state.blocks.map((block) {
      if (block.id == id) {
        return block.copyWith(content: newContent);
      }
      return block;
    }).toList();
    _updateBlocksState(updatedBlocks);
  }

  void updateBlockAttributes(String id, Map<String, dynamic> attributes) {
    final updatedBlocks = state.blocks.map((block) {
      if (block.id == id) {
        return block.copyWith(attributes: attributes);
      }
      return block;
    }).toList();
    _updateBlocksState(updatedBlocks);
  }

  void updateBlockData(String id, Map<String, dynamic> data) {
    final updatedBlocks = state.blocks.map((block) {
      if (block.id == id) {
        return block.copyWith(data: data);
      }
      return block;
    }).toList();
    _updateBlocksState(updatedBlocks);
  }

  void insertBlockDirectly(int index, BlockEntity block) {
    final currentBlocks = List<BlockEntity>.from(state.blocks);
    currentBlocks.insert(index, block);
    state = state.copyWith(
      blocks: currentBlocks,
      selectedIndex: index,
      isDirty: true,
      redoStack: [],
    );
  }

  void replaceBlockDirectly(String id, BlockEntity newBlock) {
    final index = state.blocks.indexWhere((block) => block.id == id);
    if (index != -1) {
      final currentBlocks = List<BlockEntity>.from(state.blocks);
      currentBlocks[index] = newBlock;
      state = state.copyWith(
        blocks: currentBlocks,
        isDirty: true,
      );
    }
  }

  void removeBlockDirectly(String id) {
    if (state.blocks.length <= 1) return;
    final currentBlocks = state.blocks.where((block) => block.id != id).toList();
    state = state.copyWith(
      blocks: currentBlocks,
      selectedIndex: -1,
      isDirty: true,
      redoStack: [],
    );
  }

  void reorderBlocksDirectly(int oldIndex, int newIndex) {
    final currentBlocks = List<BlockEntity>.from(state.blocks);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = currentBlocks.removeAt(oldIndex);
    currentBlocks.insert(newIndex, item);
    state = state.copyWith(
      blocks: currentBlocks,
      isDirty: true,
      redoStack: [],
    );
  }

  void markClean() {
    state = state.copyWith(isDirty: false);
  }

  void updateStateDirectly(EditorBlockState newState) {
    state = newState;
  }

  void _updateBlocksState(List<BlockEntity> updatedBlocks) {
    state = state.copyWith(
      blocks: updatedBlocks,
      isDirty: true,
    );
  }
}
