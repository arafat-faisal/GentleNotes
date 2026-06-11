import 'dart:convert';
import '../../../../core/utils/logger.dart';
import '../entities/block_entity.dart';
import '../entities/block_type.dart';

class ConvertBlocksToDelta {
  static String execute(List<BlockEntity> blocks) {
    AppLogger.info('ConvertBlocksToDelta: execute invoked. Blocks count: ${blocks.length}');
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
          'insert': {
            'audio': {
              'audios': block.data['audios'] ?? <Map<String, dynamic>>[],
              'layout': block.attributes['layout'] ?? 'classic',
            }
          },
        });
        ops.add({'insert': '\n'});
      } else if (block.type == BlockType.sticker) {
        ops.add({
          'insert': {'sticker': block.content},
        });
        ops.add({'insert': '\n'});
      } else if (block.type == BlockType.photoFrame) {
        ops.add({
          'insert': {
            'photo-frame': {
              'images': block.data['images'] ?? <String>[],
              'layout': block.attributes['layout'] ?? 'grid',
            }
          },
        });
        ops.add({'insert': '\n'});
      } else if (block.type == BlockType.pdf) {
        ops.add({
          'insert': {
            'pdf': {
              'path': block.content,
              'name': block.attributes['name'] ?? 'PDF Document',
              'pages': block.data['pages'] ?? <int>[],
              'crops': block.data['crops'] ?? <String, dynamic>{},
            }
          },
        });
        ops.add({'insert': '\n'});
      } else if (block.type == BlockType.horizontalRule) {
        ops.add({
          'insert': {'horizontal-rule': ''},
        });
        ops.add({'insert': '\n'});
      } else if (block.type == BlockType.code) {
        final text = block.content;
        final lang = block.attributes['language'] ?? block.attributes['code-block'];
        final codeBlockVal = lang is String && lang.isNotEmpty ? lang : true;
        final lines = text.split('\n');
        for (final line in lines) {
          ops.add({
            'insert': '$line\n',
            'attributes': {'code-block': codeBlockVal},
          });
        }
      } else {
        final text = block.content;
        final Map<String, dynamic> attrs = Map<String, dynamic>.from(block.attributes);

        if (block.type == BlockType.heading) {
          attrs['header'] = attrs['header'] ?? 1;
        } else if (block.type == BlockType.checklist) {
          attrs['list'] = attrs['list'] ?? 'unchecked';
        }

        ops.add({
          'insert': '$text\n',
          if (attrs.isNotEmpty) 'attributes': attrs,
        });
      }
    }

    final result = jsonEncode(ops);
    AppLogger.info('ConvertBlocksToDelta: Converted into Delta JSON. Length: ${result.length}');
    return result;
  }
}
