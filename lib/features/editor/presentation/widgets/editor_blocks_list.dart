import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/block_entity.dart';
import '../controllers/editor_block_controller.dart';
import 'block_renderer.dart';

class EditorBlocksList extends ConsumerWidget {
  final List<BlockEntity> blocks;
  final Map<String, FocusNode> focusNodes;
  final ScrollController scrollController;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final bool isReorderable;
  final bool readOnly;

  const EditorBlocksList({
    super.key,
    required this.blocks,
    required this.focusNodes,
    required this.scrollController,
    this.shrinkWrap = false,
    this.physics,
    this.isReorderable = true,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(editorBlockControllerProvider.notifier);

    if (!isReorderable) {
      return ListView.builder(
        controller: scrollController,
        shrinkWrap: shrinkWrap,
        physics: physics,
        itemCount: blocks.length,
        itemBuilder: (context, index) {
          final block = blocks[index];
          FocusNode? node = focusNodes[block.id];
          if (node == null) {
            node = FocusNode();
            focusNodes[block.id] = node;
          }

          return Padding(
            key: ValueKey(block.id),
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: BlockRenderer(
              block: block,
              index: index,
              focusNode: node,
              readOnly: readOnly,
            ),
          );
        },
      );
    }

    return ReorderableListView.builder(
      scrollController: scrollController,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: blocks.length,
      onReorder: (oldIndex, newIndex) {
        controller.reorderBlocks(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final block = blocks[index];
        FocusNode? node = focusNodes[block.id];
        if (node == null) {
          node = FocusNode();
          focusNodes[block.id] = node;
        }

        return Padding(
          key: ValueKey(block.id),
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reorder drag handle
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0, right: 4.0, left: 4.0),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      size: 16,
                      color: Theme.of(context).hintColor.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              // Main Block content
              Expanded(
                child: BlockRenderer(
                  block: block,
                  index: index,
                  focusNode: node,
                  readOnly: readOnly,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
