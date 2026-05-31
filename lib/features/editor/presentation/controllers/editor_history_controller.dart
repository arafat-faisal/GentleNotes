import '../../domain/entities/block_entity.dart';
import 'editor_core_controller.dart';

class EditorHistoryController {
  final EditorCoreController coreController;

  EditorHistoryController(this.coreController);

  void saveToUndoStack() {
    final state = coreController.state;
    final newUndoStack = List<List<BlockEntity>>.from(state.undoStack);
    if (newUndoStack.length > 20) newUndoStack.removeAt(0); // History limit
    newUndoStack.add(state.blocks);
    coreController.updateStateDirectly(state.copyWith(undoStack: newUndoStack));
  }

  void undo() {
    final state = coreController.state;
    if (state.undoStack.isEmpty) return;
    final previousBlocks = state.undoStack.last;
    final newUndoStack = List<List<BlockEntity>>.from(state.undoStack)..removeLast();
    final newRedoStack = List<List<BlockEntity>>.from(state.redoStack)..add(state.blocks);
    coreController.updateStateDirectly(state.copyWith(
      blocks: previousBlocks,
      undoStack: newUndoStack,
      redoStack: newRedoStack,
      isDirty: true,
    ));
  }

  void redo() {
    final state = coreController.state;
    if (state.redoStack.isEmpty) return;
    final nextBlocks = state.redoStack.last;
    final newRedoStack = List<List<BlockEntity>>.from(state.redoStack)..removeLast();
    final newUndoStack = List<List<BlockEntity>>.from(state.undoStack)..add(state.blocks);
    coreController.updateStateDirectly(state.copyWith(
      blocks: nextBlocks,
      undoStack: newUndoStack,
      redoStack: newRedoStack,
      isDirty: true,
    ));
  }
}
