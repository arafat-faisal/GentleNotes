import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/block_entity.dart';
import '../../domain/entities/block_type.dart';
import '../controllers/editor_block_controller.dart';
import 'blocks/text_block.dart';
import 'blocks/heading_block.dart';
import 'blocks/checklist_block.dart';
import 'blocks/image_block.dart';
import 'blocks/audio_block.dart';
import 'blocks/code_block.dart';
import 'blocks/drawing_block.dart';
import 'blocks/hr_block.dart';
import 'blocks/sticker_block.dart';

class BlockRenderer extends ConsumerWidget {
  final BlockEntity block;
  final int index;
  final FocusNode focusNode;

  const BlockRenderer({
    super.key,
    required this.block,
    required this.index,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(editorBlockControllerProvider.notifier);

    switch (block.type) {
      case BlockType.text:
        return TextBlock(
          block: block,
          focusNode: focusNode,
          onChanged: (val) => controller.updateBlockContent(block.id, val),
          onSubmitted: () => controller.insertBlock(index, BlockType.text),
          onDelete: () => controller.removeBlock(block.id),
        );
      case BlockType.heading:
        return HeadingBlock(
          block: block,
          focusNode: focusNode,
          onChanged: (val) => controller.updateBlockContent(block.id, val),
          onSubmitted: () => controller.insertBlock(index, BlockType.text),
          onDelete: () => controller.removeBlock(block.id),
        );
      case BlockType.checklist:
        return ChecklistBlock(
          block: block,
          focusNode: focusNode,
          onChanged: (val) => controller.updateBlockContent(block.id, val),
          onAttributesChanged: (attrs) => controller.updateBlockAttributes(block.id, attrs),
          onSubmitted: () => controller.insertBlock(index, BlockType.checklist),
          onDelete: () => controller.removeBlock(block.id),
        );
      case BlockType.code:
        return CodeBlock(
          block: block,
          focusNode: focusNode,
          onChanged: (val) => controller.updateBlockContent(block.id, val),
          onAttributesChanged: (attrs) => controller.updateBlockAttributes(block.id, attrs),
          onSubmitted: () => controller.insertBlock(index, BlockType.text),
          onDelete: () => controller.removeBlock(block.id),
        );
      case BlockType.image:
        return ImageBlock(
          block: block,
          onRemoved: () => controller.removeBlock(block.id),
        );
      case BlockType.audio:
        return AudioBlock(
          block: block,
          onRemoved: () => controller.removeBlock(block.id),
        );
      case BlockType.drawing:
        return DrawingBlock(
          block: block,
          onSaved: (val) => controller.updateBlockContent(block.id, val),
          onRemoved: () => controller.removeBlock(block.id),
        );
      case BlockType.horizontalRule:
        return HrBlock(
          block: block,
          onRemoved: () => controller.removeBlock(block.id),
        );
      case BlockType.sticker:
        return StickerBlock(
          block: block,
          onRemoved: () => controller.removeBlock(block.id),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
