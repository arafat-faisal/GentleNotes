import 'dart:convert';
import '../entities/block_entity.dart';
import '../entities/block_type.dart';

class ConvertBlocksToDelta {
  static String execute(List<BlockEntity> blocks) {
    final List<Map<String, dynamic>> ops = [];

    for (final block in blocks) {
      if (block.type == BlockType.image) {
        ops.add({
          'insert': {'image': block.content},
        });
        ops.add({'insert': '\n'});
      } else if (block.type == BlockType.drawing) {
        ops.add({
          'insert': {'drawing': block.content},
        });
        ops.add({'insert': '\n'});
      } else if (block.type == BlockType.audio) {
        ops.add({
          'insert': {'audio': block.content},
        });
        ops.add({'insert': '\n'});
      } else if (block.type == BlockType.sticker) {
        ops.add({
          'insert': {'sticker': block.content},
        });
        ops.add({'insert': '\n'});
      } else {
        final text = block.content;
        final Map<String, dynamic> attrs = Map<String, dynamic>.from(block.attributes);

        if (block.type == BlockType.heading) {
          attrs['header'] = attrs['header'] ?? 1;
        } else if (block.type == BlockType.code) {
          attrs['code-block'] = true;
        } else if (block.type == BlockType.checklist) {
          attrs['list'] = attrs['list'] ?? 'unchecked';
        }

        ops.add({
          'insert': '$text\n',
          if (attrs.isNotEmpty) 'attributes': attrs,
        });
      }
    }

    return jsonEncode(ops);
  }
}
