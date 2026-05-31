import '../../domain/entities/block_entity.dart';

class EditorBlockState {
  final List<BlockEntity> blocks;
  final int selectedIndex;
  final bool isDirty;
  final List<List<BlockEntity>> undoStack;
  final List<List<BlockEntity>> redoStack;

  EditorBlockState({
    required this.blocks,
    this.selectedIndex = -1,
    this.isDirty = false,
    this.undoStack = const [],
    this.redoStack = const [],
  });

  EditorBlockState copyWith({
    List<BlockEntity>? blocks,
    int? selectedIndex,
    bool? isDirty,
    List<List<BlockEntity>>? undoStack,
    List<List<BlockEntity>>? redoStack,
  }) {
    return EditorBlockState(
      blocks: blocks ?? this.blocks,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      isDirty: isDirty ?? this.isDirty,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
    );
  }
}
