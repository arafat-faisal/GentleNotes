import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
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
    } else if (kIsWeb) {
      imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
      );
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

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        _showImageOptionsBottomSheet(context, imageUrl, embedContext);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Hero(
              tag: imageUrl,
              child: imageWidget,
            ),
          ),
        ),
      ),
    );
  }

  void _showImageOptionsBottomSheet(BuildContext context, String imageUrl, EmbedContext embedContext) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF13111C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: isDark ? const Color(0xFF252234) : const Color(0xFFE9E6F5)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3D3557) : const Color(0xFFD1CBE8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.fullscreen_rounded, color: Color(0xFF8B5CF6)),
                title: const Text('View Fullscreen', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _openFullscreenViewer(context, imageUrl);
                },
              ),
              if (!embedContext.readOnly) ...[
                ListTile(
                  leading: const Icon(Icons.collections_rounded, color: Color(0xFF8B5CF6)),
                  title: const Text('Convert to Photo Frame', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(ctx);
                    final offset = embedContext.node.offset;
                    final blockData = {
                      'images': [imageUrl],
                      'layout': 'grid',
                    };
                    embedContext.controller.replaceText(
                      offset,
                      1,
                      BlockEmbed('photo-frame', jsonEncode(blockData)),
                      TextSelection.collapsed(offset: offset + 1),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  title: const Text('Delete Image', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteImageNode(embedContext);
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _openFullscreenViewer(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  maxScale: 4.0,
                  child: Center(
                    child: Hero(
                      tag: imageUrl,
                      child: _buildImageViewer(imageUrl),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageViewer(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      final base64Str = imageUrl.split(',').last;
      return Image.memory(base64Decode(base64Str));
    } else if (kIsWeb) {
      return Image.network(imageUrl);
    } else if (imageUrl.startsWith('file://')) {
      final path = imageUrl.replaceFirst('file://', '');
      return Image.file(io.File(path));
    } else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(imageUrl);
    } else {
      return Image.file(io.File(imageUrl));
    }
  }

  void _deleteImageNode(EmbedContext embedContext) {
    final offset = embedContext.node.offset;
    embedContext.controller.replaceText(
      offset,
      1,
      '',
      TextSelection.collapsed(offset: offset),
    );
  }
}
