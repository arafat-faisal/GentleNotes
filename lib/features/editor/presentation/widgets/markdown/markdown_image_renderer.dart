import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../../../../models/models.dart';
import 'markdown_renderer.dart';

class MarkdownImageRenderer extends StatelessWidget {
  final MarkdownCustomBlock block;
  final List<AttachmentModel> attachments;

  const MarkdownImageRenderer({
    super.key,
    required this.block,
    required this.attachments,
  });

  @override
  Widget build(BuildContext context) {
    var uriStr = block.text;

    if (uriStr.startsWith('attachment://')) {
      final attachmentId = uriStr.replaceFirst('attachment://', '');
      final attachment = attachments.cast<AttachmentModel?>().firstWhere(
            (a) => a?.id == attachmentId,
            orElse: () => null,
          );
      if (attachment != null) {
        uriStr = attachment.pathOrUrl;
      }
    }

    final altTextRaw = block.altText ?? '';
    String size = 'medium';
    String align = 'center';

    if (altTextRaw.contains('|')) {
      final parts = altTextRaw.split('|');
      for (var part in parts.skip(1)) {
        final trimmed = part.trim();
        if (trimmed.startsWith('size=')) {
          size = trimmed.substring('size='.length).trim();
        } else if (trimmed.startsWith('align=')) {
          align = trimmed.substring('align='.length).trim();
        }
      }
    }

    double? width;
    double? height;
    if (size == 'small') {
      width = 200;
      height = 150;
    } else if (size == 'large') {
      width = double.infinity;
    } else {
      width = 400;
      height = 300;
    }

    Alignment alignment = Alignment.center;
    if (align == 'left') {
      alignment = Alignment.centerLeft;
    } else if (align == 'right') {
      alignment = Alignment.centerRight;
    }

    Widget imageWidget;

    if (uriStr.startsWith('data:image')) {
      try {
        final base64Str = uriStr.split(',').last;
        final bytes = base64Decode(base64Str);
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey);
            },
          ),
        );
      } catch (e) {
        imageWidget = const Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey);
      }
    } else if (uriStr.startsWith('file://')) {
      final filePath = uriStr.replaceFirst('file://', '');
      if (kIsWeb) {
        imageWidget = const Text('[Local Image (Unavailable on Web)]');
      } else {
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            io.File(filePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey);
            },
          ),
        );
      }
    } else {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          uriStr,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey);
          },
        ),
      );
    }

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          width: width,
          height: size == 'large' ? null : height,
          constraints: size == 'large' ? const BoxConstraints(maxHeight: 450) : null,
          child: imageWidget,
        ),
      ),
    );
  }
}
