import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../../../models/models.dart';
import '../inline_audio_player.dart';

class AudioEmbedBuilder extends EmbedBuilder {
  final List<AttachmentModel> Function() getAttachments;

  AudioEmbedBuilder({required this.getAttachments});

  @override
  String get key => 'audio';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final dataString = embedContext.node.value.data as String;
    String attachmentId = '';
    String width = 'full';

    try {
      final parsed = jsonDecode(dataString) as Map<String, dynamic>;
      attachmentId = parsed['id'] as String? ?? '';
      width = parsed['width'] as String? ?? 'full';
    } catch (_) {
      // Fallback if data is raw ID string
      attachmentId = dataString;
    }

    final attachments = getAttachments();
    final attachment = attachments.firstWhere(
      (a) => a.id == attachmentId,
      orElse: () => AttachmentModel(
        id: attachmentId,
        noteId: '',
        type: AttachmentType.audio,
        name: 'Voice Note',
        pathOrUrl: '',
        createdAt: DateTime.now(),
      ),
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF252234) : const Color(0xFFE9E6F5);

    final playerWidget = InlineAudioPlayer(
      filePath: attachment.pathOrUrl,
      name: attachment.name,
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      alignment: width == 'compact' ? Alignment.centerLeft : Alignment.center,
      child: FractionallySizedBox(
        widthFactor: width == 'compact' ? 0.7 : 1.0,
        child: Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(right: embedContext.readOnly ? 0 : 40),
                child: playerWidget,
              ),
              if (!embedContext.readOnly)
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      _showAudioOptionsBottomSheet(context, attachmentId, width, embedContext);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAudioOptionsBottomSheet(
    BuildContext context,
    String attachmentId,
    String currentWidth,
    EmbedContext embedContext,
  ) {
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
                leading: const Icon(Icons.aspect_ratio_rounded, color: Color(0xFF8B5CF6)),
                title: Text(currentWidth == 'compact' ? 'Expand to Full Width' : 'Shrink to Compact Layout'),
                onTap: () {
                  Navigator.pop(ctx);
                  final newWidth = currentWidth == 'compact' ? 'full' : 'compact';
                  _updateAudioWidth(embedContext, attachmentId, newWidth);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Delete Voice Note', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteAudioNode(embedContext);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _updateAudioWidth(EmbedContext embedContext, String attachmentId, String newWidth) {
    final offset = embedContext.node.offset;
    final dataMap = {
      'id': attachmentId,
      'width': newWidth,
    };
    final updatedBlock = BlockEmbed.custom(CustomBlockEmbed('audio', jsonEncode(dataMap)));

    embedContext.controller.replaceText(
      offset,
      1,
      updatedBlock,
      TextSelection.collapsed(offset: offset),
    );
  }

  void _deleteAudioNode(EmbedContext embedContext) {
    final offset = embedContext.node.offset;
    embedContext.controller.replaceText(
      offset,
      1,
      '',
      TextSelection.collapsed(offset: offset),
    );
  }
}
