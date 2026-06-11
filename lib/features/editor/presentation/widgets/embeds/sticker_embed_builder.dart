import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../notes/data/models/floating_sticker_model.dart';
import '../../controllers/floating_stickers_controller.dart';

class StickerEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'sticker';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final stickerName = embedContext.node.value.data as String;

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        if (!embedContext.readOnly) {
          _showStickerOptionsBottomSheet(context, stickerName, embedContext);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Hero(
              tag: 'sticker_hero_${embedContext.node.offset}_$stickerName',
              child: _buildStickerImage(stickerName),
            ),
          ),
        ),
      ),
    );
  }

  void _showStickerOptionsBottomSheet(
      BuildContext context, String stickerName, EmbedContext embedContext) {
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
            border: Border.all(
                color: isDark ? const Color(0xFF252234) : const Color(0xFFE9E6F5)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3D3557) : const Color(0xFFD1CBE8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Consumer(
                builder: (context, ref, child) {
                  return ListTile(
                    leading: const Icon(Icons.open_with_rounded, color: Colors.blueAccent),
                    title: const Text('Convert to Floating Sticker',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(ctx);
                      final offset = embedContext.node.offset;
                      embedContext.controller.replaceText(
                        offset,
                        1,
                        '',
                        TextSelection.collapsed(offset: offset),
                      );
                      final id = const Uuid().v4();
                      ref.read(floatingStickersProvider.notifier).addSticker(
                        FloatingStickerModel(
                          id: id,
                          name: stickerName,
                          x: 80.0,
                          y: 150.0,
                        ),
                      );
                    },
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Delete Sticker',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  final offset = embedContext.node.offset;
                  embedContext.controller.replaceText(
                    offset,
                    1,
                    '',
                    TextSelection.collapsed(offset: offset),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStickerImage(String name) {
    if (name.startsWith('data:image')) {
      final base64Str = name.split(',').last;
      try {
        return Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.contain,
        );
      } catch (e) {
        return const Icon(
          Icons.broken_image_rounded,
          size: 48,
          color: Colors.grey,
        );
      }
    }
    if (name.startsWith('/') ||
        name.contains(':\\') ||
        name.contains(':/') ||
        name.startsWith('content:')) {
      if (kIsWeb) {
        return Image.network(
          name,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.broken_image_rounded,
            size: 48,
            color: Colors.grey,
          ),
        );
      }
      return Image.file(
        File(name),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.broken_image_rounded,
          size: 48,
          color: Colors.grey,
        ),
      );
    }
    return Image.asset(
      'assets/images/stickers/$name.png',
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.sticky_note_2_outlined,
        size: 48,
        color: Colors.grey,
      ),
    );
  }
}
