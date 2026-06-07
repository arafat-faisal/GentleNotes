import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../blocks/pdf_block.dart';
import '../../../domain/entities/block_entity.dart';
import '../../../domain/entities/block_type.dart';

class PdfEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'pdf';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final rawData = embedContext.node.value.data as String;
    Map<String, dynamic> parsed = {};
    try {
      parsed = jsonDecode(rawData);
    } catch (_) {}

    final path = parsed['path'] ?? '';
    final name = parsed['name'] ?? 'PDF Document';
    final pages = List<int>.from(parsed['pages'] ?? []);
    final crops = Map<String, dynamic>.from(parsed['crops'] ?? {});
    final layout = parsed['layout'] ?? 'grid';

    int getDocOffset() => embedContext.node.documentOffset;

    final block = BlockEntity(
      id: 'embed_${getDocOffset()}',
      type: BlockType.pdf,
      content: path,
      data: {
        'path': path,
        'pages': pages,
        'crops': crops,
      },
      attributes: {
        'name': name,
        'layout': layout,
      },
    );

    return PdfBlock(
      block: block,
      readOnly: embedContext.readOnly,
      onRemoved: () {
        final offset = getDocOffset();
        embedContext.controller.replaceText(
          offset,
          1,
          '',
          TextSelection.collapsed(offset: offset),
        );
      },
      onUpdate: (newPages, newCrops, newLayout) {
        final offset = getDocOffset();
        final blockData = {
          'path': path,
          'name': name,
          'pages': newPages,
          'crops': newCrops,
          'layout': newLayout,
        };
        embedContext.controller.replaceText(
          offset,
          1,
          BlockEmbed('pdf', jsonEncode(blockData)),
          TextSelection.collapsed(offset: offset + 1),
        );
      },
    );
  }
}
