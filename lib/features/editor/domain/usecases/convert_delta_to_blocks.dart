import 'dart:convert';
import '../entities/block_entity.dart';
import '../entities/block_type.dart';

class ConvertDeltaToBlocks {
  static List<BlockEntity> execute(String content) {
    if (content.isEmpty) {
      return [BlockEntity.create(BlockType.text)];
    }

    if (content.startsWith('[') && content.endsWith(']')) {
      try {
        final List parsed = jsonDecode(content);
        final List<BlockEntity> blocks = [];

        for (final op in parsed) {
          if (op is Map && op.containsKey('insert')) {
            final insert = op['insert'];
            final attributes = op['attributes'] as Map<String, dynamic>? ?? {};

            if (insert is Map) {
              if (insert.containsKey('image')) {
                blocks.add(BlockEntity.create(BlockType.image, content: insert['image'].toString()));
              } else if (insert.containsKey('drawing')) {
                blocks.add(BlockEntity.create(BlockType.drawing, content: insert['drawing'].toString()));
              } else if (insert.containsKey('audio')) {
                blocks.add(BlockEntity.create(BlockType.audio, content: insert['audio'].toString()));
              }
            } else if (insert is String) {
              final text = insert;
              if (text == '\n') continue;

              BlockType type = BlockType.text;
              if (attributes.containsKey('header')) {
                type = BlockType.heading;
              } else if (attributes.containsKey('list')) {
                type = BlockType.checklist;
              } else if (attributes.containsKey('code-block')) {
                type = BlockType.code;
              }

              blocks.add(BlockEntity.create(
                type,
                content: text.trimRight(),
                attrs: attributes,
              ));
            }
          }
        }

        if (blocks.isEmpty) {
          blocks.add(BlockEntity.create(BlockType.text));
        }
        return blocks;
      } catch (_) {
        // Fallback to text splitting
      }
    }

    // Treat as raw text/markdown
    final lines = content.split('\n');
    final List<BlockEntity> blocks = [];
    for (var line in lines) {
      if (line.startsWith('#')) {
        blocks.add(BlockEntity.create(BlockType.heading, content: line));
      } else if (line.trim().startsWith('- [ ]') || line.trim().startsWith('- [x]')) {
        blocks.add(BlockEntity.create(BlockType.checklist, content: line));
      } else {
        blocks.add(BlockEntity.create(BlockType.text, content: line));
      }
    }
    return blocks;
  }
}
