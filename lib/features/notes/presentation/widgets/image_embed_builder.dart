import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class ImageEmbedBuilder extends EmbedBuilder {
  @override
  String get key => BlockEmbed.imageType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final imageUrl = embedContext.node.value.data as String;

    Widget imageWidget;
    if (imageUrl.startsWith('data:image')) {
      final base64Str = imageUrl.split(',').last;
      try {
        imageWidget = Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.contain,
        );
      } catch (e) {
        imageWidget = const Icon(Icons.broken_image, size: 50, color: Colors.grey);
      }
    } else if (imageUrl.startsWith('file://')) {
      final path = imageUrl.replaceFirst('file://', '');
      imageWidget = Image.file(
        io.File(path),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
      );
    } else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
      );
    } else {
      // Fallback for raw file path
      imageWidget = Image.file(
        io.File(imageUrl),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageWidget,
        ),
      ),
    );
  }
}
