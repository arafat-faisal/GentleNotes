import 'package:flutter/material.dart';
import '../../../../domain/entities/block_type.dart';

class BlockInsertGroup extends StatelessWidget {
  final Function(BlockType type, {String content, Map<String, dynamic> attributes}) onInsertBlock;
  final bool showHeading;
  final bool showChecklist;
  final bool showCode;

  const BlockInsertGroup({
    super.key,
    required this.onInsertBlock,
    required this.showHeading,
    required this.showChecklist,
    required this.showCode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHeading)
          IconButton(
            icon: const Icon(Icons.title_rounded, size: 20),
            onPressed: () => onInsertBlock(BlockType.heading, attributes: {'header': 1}),
            tooltip: 'Heading 1',
          ),
        if (showChecklist)
          IconButton(
            icon: const Icon(Icons.format_list_bulleted_rounded, size: 20),
            onPressed: () => onInsertBlock(BlockType.checklist),
            tooltip: 'To-do List',
          ),
        if (showCode)
          IconButton(
            icon: const Icon(Icons.code_rounded, size: 20),
            onPressed: () => onInsertBlock(BlockType.code),
            tooltip: 'Code Snippet',
          ),
      ],
    );
  }
}
