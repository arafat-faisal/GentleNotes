import '../entities/block_entity.dart';
import '../entities/block_type.dart';

class ExportBlocksToMarkdown {
  static String execute(List<BlockEntity> blocks) {
    final buffer = StringBuffer();
    for (final block in blocks) {
      switch (block.type) {
        case BlockType.heading:
          final level = block.attributes['header'] ?? 1;
          buffer.writeln('${"#" * level} ${block.content}');
          break;
        case BlockType.checklist:
          final listType = block.attributes['list'];
          final prefix = listType == 'checked' ? '- [x] ' : '- [ ] ';
          buffer.writeln('$prefix${block.content}');
          break;
        case BlockType.code:
          final lang = block.attributes['language'] ?? '';
          buffer.writeln('```$lang');
          buffer.writeln(block.content);
          buffer.writeln('```');
          break;
        case BlockType.image:
          buffer.writeln('![image](${block.content})');
          break;
        case BlockType.drawing:
          buffer.writeln('![drawing](${block.content})');
          break;
        case BlockType.audio:
          buffer.writeln('[Audio Attachment](${block.content})');
          break;
        case BlockType.pdf:
          final name = block.attributes['name'] ?? 'PDF Document';
          buffer.writeln('[$name](${block.content})');
          break;
        case BlockType.horizontalRule:
          buffer.writeln('---');
          break;
        case BlockType.text:
        default:
          buffer.writeln(block.content);
          break;
      }
      buffer.writeln(); // spacing
    }
    return buffer.toString();
  }
}
