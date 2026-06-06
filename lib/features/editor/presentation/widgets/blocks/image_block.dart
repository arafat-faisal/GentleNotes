import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../domain/entities/block_entity.dart';

class ImageBlock extends StatelessWidget {
  final BlockEntity block;
  final VoidCallback onRemoved;
  final VoidCallback onConvertToFrame;
  final bool readOnly;

  const ImageBlock({
    super.key,
    required this.block,
    required this.onRemoved,
    required this.onConvertToFrame,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = block.content;
    if (imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    Widget imageWidget;
    if (imageUrl.startsWith('data:image')) {
      final base64Str = imageUrl.split(',').last;
      try {
        imageWidget = Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.cover,
        );
      } catch (e) {
        imageWidget = const _BrokenImagePlaceholder();
      }
    } else if (kIsWeb) {
      imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const _BrokenImagePlaceholder(),
      );
    } else if (imageUrl.startsWith('file://')) {
      final path = imageUrl.replaceFirst('file://', '');
      imageWidget = Image.file(
        io.File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const _BrokenImagePlaceholder(),
      );
    } else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const _BrokenImagePlaceholder(),
      );
    } else {
      imageWidget = Image.file(
        io.File(imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const _BrokenImagePlaceholder(),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isDark ? const Color(0xFF252234) : const Color(0xFFE9E6F5),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () => _openFullscreenViewer(context, imageUrl),
                  child: Hero(
                    tag: 'image_hero_${block.id}',
                    child: imageWidget,
                  ),
                ),
                if (!readOnly)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: 'Convert to Photo Frame',
                          child: Material(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: onConvertToFrame,
                              child: const Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Icon(
                                  Icons.collections_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: 'Delete Image',
                          child: Material(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: onRemoved,
                              child: const Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
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
                      tag: 'image_hero_${block.id}',
                      child: _buildFullscreenImage(imageUrl),
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

  Widget _buildFullscreenImage(String imageUrl) {
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
}

class _BrokenImagePlaceholder extends StatelessWidget {
  const _BrokenImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      color: Colors.grey.withOpacity(0.1),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'Unable to load image',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
