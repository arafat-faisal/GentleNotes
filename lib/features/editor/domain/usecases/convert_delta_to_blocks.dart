import 'dart:convert';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/quill_markdown_converter.dart';
import '../entities/block_entity.dart';
import '../entities/block_type.dart';

class ConvertDeltaToBlocks {
  static List<BlockEntity> execute(String content) {
    AppLogger.info('ConvertDeltaToBlocks: execute invoked. Content length: ${content.length}');
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) {
      return [BlockEntity.create(BlockType.text)];
    }

    List<dynamic>? parsedOps;

    if (trimmedContent.startsWith('[') && trimmedContent.endsWith(']')) {
      try {
        parsedOps = jsonDecode(trimmedContent) as List<dynamic>;
      } catch (e, stack) {
        AppLogger.warning('ConvertDeltaToBlocks: Failed to parse Delta JSON, attempting markdown conversion instead', e, stack);
      }
    }

    if (parsedOps == null) {
      // Treat as raw text/markdown
      AppLogger.info('ConvertDeltaToBlocks: Content is not valid Delta JSON. Parsing as raw markdown using QuillMarkdownConverter.');
      try {
        parsedOps = QuillMarkdownConverter.markdownToDeltaOps(content);
      } catch (e, stack) {
        AppLogger.error('ConvertDeltaToBlocks: Markdown parsing failed too', e, stack);
      }
    }

    if (parsedOps != null) {
      final List<BlockEntity> blocks = [];
      List<String> currentBlockSegments = [];

      for (final op in parsedOps) {
        if (op is Map && op.containsKey('insert')) {
          final insert = op['insert'];
          final attributes = op['attributes'] as Map<String, dynamic>? ?? {};

          if (insert is Map) {
            // Flush current text block if any
            if (currentBlockSegments.isNotEmpty) {
              final text = currentBlockSegments.join('');
              currentBlockSegments = [];
              if (text.trimRight().isNotEmpty) {
                blocks.add(BlockEntity.create(BlockType.text, content: text.trimRight()));
              }
            }

            if (insert.containsKey('image')) {
              blocks.add(BlockEntity.create(BlockType.image, content: insert['image'].toString()));
            } else if (insert.containsKey('photo-frame')) {
              dynamic pf = insert['photo-frame'];
              if (pf is String) {
                try {
                  pf = jsonDecode(pf);
                } catch (_) {}
              }
              if (pf is Map) {
                final images = List<String>.from(pf['images'] ?? <String>[]);
                final layout = pf['layout'] ?? 'grid';
                blocks.add(BlockEntity.create(
                  BlockType.photoFrame,
                  data: {'images': images},
                  attrs: {'layout': layout},
                ));
              }
            } else if (insert.containsKey('pdf')) {
              dynamic pdf = insert['pdf'];
              if (pdf is String) {
                try {
                  pdf = jsonDecode(pdf);
                } catch (_) {}
              }
              if (pdf is Map) {
                final path = pdf['path']?.toString() ?? '';
                final name = pdf['name']?.toString() ?? 'PDF Document';
                final pages = List<int>.from(pdf['pages'] ?? <int>[]);
                final crops = Map<String, dynamic>.from(pdf['crops'] ?? <String, dynamic>{});
                blocks.add(BlockEntity.create(
                  BlockType.pdf,
                  content: path,
                  data: {
                    'path': path,
                    'pages': pages,
                    'crops': crops,
                  },
                  attrs: {
                    'name': name,
                  },
                ));
              }
            } else if (insert.containsKey('drawing')) {
              blocks.add(BlockEntity.create(BlockType.drawing, content: insert['drawing'].toString()));
            } else if (insert.containsKey('audio')) {
              final rawAudio = insert['audio'];
              if (rawAudio is Map) {
                final audios = List<Map<String, dynamic>>.from(
                  (rawAudio['audios'] as List?)?.map((item) => Map<String, dynamic>.from(item as Map)) ?? []
                );
                final layout = rawAudio['layout'] ?? 'classic';
                blocks.add(BlockEntity.create(
                  BlockType.audio,
                  data: {'audios': audios},
                  attrs: {'layout': layout},
                ));
              } else {
                blocks.add(BlockEntity.create(BlockType.audio, content: rawAudio.toString()));
              }
            } else if (insert.containsKey('sticker')) {
              blocks.add(BlockEntity.create(BlockType.sticker, content: insert['sticker'].toString()));
            } else if (insert.containsKey('horizontal-rule') || insert.containsKey('divider')) {
              blocks.add(BlockEntity.create(BlockType.horizontalRule));
            }
          } else if (insert is String) {
            final text = insert;
            int start = 0;
            while (start < text.length) {
              final newlineIndex = text.indexOf('\n', start);
              if (newlineIndex == -1) {
                currentBlockSegments.add(text.substring(start));
                break;
              } else {
                if (newlineIndex > start) {
                  currentBlockSegments.add(text.substring(start, newlineIndex));
                }
                
                final blockText = currentBlockSegments.join('');
                currentBlockSegments = [];
                
                final isLastCharInOp = (newlineIndex == text.length - 1);
                final blockAttrs = isLastCharInOp ? attributes : const <String, dynamic>{};
                
                BlockType type = BlockType.text;
                if (blockAttrs.containsKey('header')) {
                  type = BlockType.heading;
                } else if (blockAttrs.containsKey('list')) {
                  type = BlockType.checklist;
                } else if (blockAttrs.containsKey('code-block')) {
                  type = BlockType.code;
                }
                
                if (blockText.isNotEmpty || type != BlockType.text) {
                  final Map<String, dynamic> customAttrs = Map<String, dynamic>.from(blockAttrs);
                  if (type == BlockType.code && blockAttrs['code-block'] is String) {
                    customAttrs['language'] = blockAttrs['code-block'];
                  }
                  blocks.add(BlockEntity.create(
                    type,
                    content: blockText.trimRight(),
                    attrs: customAttrs,
                  ));
                }
                
                start = newlineIndex + 1;
              }
            }
          }
        }
      }

      // Add any remaining text
      if (currentBlockSegments.isNotEmpty) {
        final text = currentBlockSegments.join('');
        if (text.trimRight().isNotEmpty) {
          blocks.add(BlockEntity.create(BlockType.text, content: text.trimRight()));
        }
      }

      if (blocks.isEmpty) {
        blocks.add(BlockEntity.create(BlockType.text));
      }

      final List<BlockEntity> groupedBlocks = [];
      BlockEntity? activeCodeBlock;

      for (final block in blocks) {
        if (block.type == BlockType.code) {
          if (activeCodeBlock == null) {
            activeCodeBlock = block;
          } else {
            final newContent = '${activeCodeBlock.content}\n${block.content}';
            activeCodeBlock = activeCodeBlock.copyWith(content: newContent);
          }
        } else {
          if (activeCodeBlock != null) {
            groupedBlocks.add(activeCodeBlock);
            activeCodeBlock = null;
          }
          groupedBlocks.add(block);
        }
      }
      if (activeCodeBlock != null) {
        groupedBlocks.add(activeCodeBlock);
      }

      AppLogger.info('ConvertDeltaToBlocks: Successfully parsed Delta/Markdown. Grouped blocks count: ${groupedBlocks.length}');
      return groupedBlocks;
    }

    // Absolutely last-ditch fallback
    AppLogger.info('ConvertDeltaToBlocks: Using line split fallback');
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
