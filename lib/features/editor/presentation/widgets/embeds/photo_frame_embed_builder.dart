import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../blocks/photo_frame_block.dart';
import '../../../domain/entities/block_entity.dart';
import '../../../domain/entities/block_type.dart';

class PhotoFrameEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'photo-frame';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final rawData = embedContext.node.value.data as String;
    Map<String, dynamic> parsed = {};
    try {
      parsed = jsonDecode(rawData);
    } catch (_) {}

    final images = List<String>.from(parsed['images'] ?? []);
    final layout = parsed['layout'] ?? 'grid';

    // Use documentOffset (absolute position in the document) to correctly
    // target the embed. node.offset is relative to the parent Line and is
    // always 0 for block embeds, which would cause replaceText to modify the
    // beginning of the document instead of the embed's actual position.
    int getDocOffset() => embedContext.node.documentOffset;

    final block = BlockEntity(
      id: 'embed_${getDocOffset()}',
      type: BlockType.photoFrame,
      data: {'images': images},
      attributes: {'layout': layout},
    );

    return PhotoFrameBlock(
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
      onUpdate: (newImages, newLayout) {
        final offset = getDocOffset();
        final blockData = {
          'images': newImages,
          'layout': newLayout,
        };
        embedContext.controller.replaceText(
          offset,
          1,
          BlockEmbed('photo-frame', jsonEncode(blockData)),
          TextSelection.collapsed(offset: offset + 1),
        );
      },
    );
  }
}

