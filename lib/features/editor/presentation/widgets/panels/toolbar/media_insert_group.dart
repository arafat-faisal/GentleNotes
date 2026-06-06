import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../domain/entities/block_type.dart';
import '../voice_recorder_bottom_sheet.dart';
import '../stickers_sheet.dart';
import 'toolbar_button.dart';

class MediaInsertGroup extends StatelessWidget {
  final String noteId;
  final Function(BlockType type, {String content, Map<String, dynamic> attributes}) onInsertBlock;
  final bool showImage;
  final bool showDrawing;
  final bool showVoice;
  final bool showDivider;
  final bool showCode;
  final Color borderCol;
  final bool isInline;
  final Color accentColor;
  final bool isSpeechListening;
  final VoidCallback onSpeechToggle;

  const MediaInsertGroup({
    super.key,
    required this.noteId,
    required this.onInsertBlock,
    required this.showImage,
    required this.showDrawing,
    required this.showVoice,
    required this.showDivider,
    this.showCode = true,
    required this.borderCol,
    this.isInline = false,
    this.accentColor = Colors.blue,
    this.isSpeechListening = false,
    required this.onSpeechToggle,
  });

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final action = await showModalBottomSheet<dynamic>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF13111C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Insert Image',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF8B5CF6)),
                title: const Text('Choose Single Image'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF8B5CF6)),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.collections_outlined, color: Color(0xFF8B5CF6)),
                title: const Text('Create Photo Frame (Multiple Images)'),
                onTap: () => Navigator.pop(ctx, 'photo_frame'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (action == 'photo_frame') {
      final files = await picker.pickMultiImage();
      if (files.isNotEmpty) {
        final List<String> paths = files.map((f) => kIsWeb ? f.path : 'file://${f.path}').toList();
        onInsertBlock(
          BlockType.photoFrame,
          content: jsonEncode(paths),
          attributes: {'layout': 'grid'},
        );
      }
    } else if (action is ImageSource) {
      final file = await picker.pickImage(source: action);
      if (file != null) {
        onInsertBlock(BlockType.image, content: kIsWeb ? file.path : 'file://${file.path}');
      }
    }
  }

  Future<void> _createPhotoFrame(BuildContext context) async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage();
    if (files.isNotEmpty) {
      final List<String> paths = files.map((f) => kIsWeb ? f.path : 'file://${f.path}').toList();
      onInsertBlock(
        BlockType.photoFrame,
        content: jsonEncode(paths),
        attributes: {'layout': 'grid'},
      );
    }
  }

  void _recordAudio(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoiceRecorderBottomSheet(
        noteId: noteId,
        onAttach: (filePath) {
          onInsertBlock(BlockType.audio, content: filePath);
        },
      ),
    );
  }

  void _showStickersPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StickersSheet(
        onSelect: (stickerName) {
          onInsertBlock(BlockType.sticker, content: stickerName);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isInline) {
      final showDictation = showVoice; // match toolbar criteria

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showImage) ...[
            ToolbarActionButton(
              icon: Icons.image_outlined,
              tooltip: 'Insert Image',
              onTap: () => _pickImage(context),
              accentColor: accentColor,
            ),
            ToolbarActionButton(
              icon: Icons.collections_rounded,
              tooltip: 'Photo Frame / Folder',
              onTap: () => _createPhotoFrame(context),
              accentColor: accentColor,
            ),
            ToolbarActionButton(
              icon: Icons.sticky_note_2_outlined,
              tooltip: 'Insert Sticker',
              onTap: () => _showStickersPicker(context),
              accentColor: accentColor,
            ),
          ],
          if (showDivider)
            ToolbarActionButton(
              icon: Icons.horizontal_rule_rounded,
              tooltip: 'Divider',
              onTap: () => onInsertBlock(BlockType.horizontalRule),
              accentColor: accentColor,
            ),
          if (showCode)
            ToolbarActionButton(
              icon: Icons.code_rounded,
              tooltip: 'Code Block',
              onTap: () => onInsertBlock(BlockType.code),
              accentColor: accentColor,
            ),
          if (showVoice)
            ToolbarActionButton(
              icon: Icons.mic_outlined,
              tooltip: 'Voice Note',
              onTap: () => _recordAudio(context),
              accentColor: accentColor,
            ),
          if (showDictation)
            ToolbarActionButton(
              icon: isSpeechListening ? Icons.mic_rounded : Icons.mic_none_outlined,
              tooltip: 'Dictation (STT)',
              onTap: onSpeechToggle,
              isActive: isSpeechListening,
              accentColor: accentColor,
            ),
          if (showDrawing)
            ToolbarActionButton(
              icon: Icons.draw_outlined,
              tooltip: 'Drawing',
              onTap: () => onInsertBlock(BlockType.drawing),
              accentColor: accentColor,
            ),
        ],
      );
    }

    return PopupMenuButton<String>(
      icon: Icon(Icons.add_box_outlined, size: 20, color: theme.colorScheme.primary),
      tooltip: 'Insert Options',
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderCol, width: 1),
      ),
      onSelected: (value) {
        if (value == 'image') _pickImage(context);
        if (value == 'photo_frame') _createPhotoFrame(context);
        if (value == 'sticker') _showStickersPicker(context);
        if (value == 'drawing') onInsertBlock(BlockType.drawing);
        if (value == 'voice') _recordAudio(context);
        if (value == 'divider') onInsertBlock(BlockType.horizontalRule);
        if (value == 'code') onInsertBlock(BlockType.code);
      },
      itemBuilder: (context) => [
        if (showImage) ...[
          const PopupMenuItem(
            value: 'image',
            child: Row(
              children: [
                Icon(Icons.image_outlined, size: 18),
                SizedBox(width: 8),
                Text('Insert Image'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'photo_frame',
            child: Row(
              children: [
                Icon(Icons.collections_rounded, size: 18),
                SizedBox(width: 8),
                Text('Photo Frame / Folder'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'sticker',
            child: Row(
              children: [
                Icon(Icons.sticky_note_2_outlined, size: 18),
                SizedBox(width: 8),
                Text('Insert Sticker'),
              ],
            ),
          ),
        ],
        if (showDrawing)
          const PopupMenuItem(
            value: 'drawing',
            child: Row(
              children: [
                Icon(Icons.draw_outlined, size: 18),
                SizedBox(width: 8),
                Text('Sketch Canvas'),
              ],
            ),
          ),
        if (showVoice)
          const PopupMenuItem(
            value: 'voice',
            child: Row(
              children: [
                Icon(Icons.mic_none_rounded, size: 18),
                SizedBox(width: 8),
                Text('Voice Recording'),
              ],
            ),
          ),
        if (showDivider)
          const PopupMenuItem(
            value: 'divider',
            child: Row(
              children: [
                Icon(Icons.horizontal_rule_rounded, size: 18),
                SizedBox(width: 8),
                Text('Divider'),
              ],
            ),
          ),
        if (showCode)
          const PopupMenuItem(
            value: 'code',
            child: Row(
              children: [
                Icon(Icons.code_rounded, size: 18),
                SizedBox(width: 8),
                Text('Code Snippet'),
              ],
            ),
          ),
      ],
    );
  }
}
