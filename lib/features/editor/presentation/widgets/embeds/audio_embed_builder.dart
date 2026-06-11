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
    List<Map<String, String>> matchedTracks = [];
    String width = 'full';
    String layout = 'classic';
    String attachmentId = '';

    try {
      final parsed = jsonDecode(dataString) as Map<String, dynamic>;
      if (parsed.containsKey('audios')) {
        final audios = parsed['audios'] as List;
        matchedTracks = audios.map((item) {
          final m = Map<String, dynamic>.from(item as Map);
          return {
            'path': m['path']?.toString() ?? '',
            'name': m['name']?.toString() ?? 'Track',
          };
        }).toList();
      } else {
        attachmentId = parsed['id'] as String? ?? '';
        final attachments = getAttachments();
        final att = attachments.firstWhere(
          (a) => a.id == attachmentId,
          orElse: () => AttachmentModel(
            id: attachmentId,
            noteId: '',
            type: AttachmentType.audio,
            name: 'Voice Note',
            pathOrUrl: attachmentId,
            createdAt: DateTime.now(),
          ),
        );
        matchedTracks = [
          {'path': att.pathOrUrl, 'name': att.name}
        ];
      }
      width = parsed['width'] as String? ?? 'full';
      layout = parsed['layout'] as String? ?? 'classic';
    } catch (_) {
      // Fallback if data is raw ID string
      attachmentId = dataString;
      final attachments = getAttachments();
      final att = attachments.firstWhere(
        (a) => a.id == attachmentId,
        orElse: () => AttachmentModel(
          id: attachmentId,
          noteId: '',
          type: AttachmentType.audio,
          name: 'Voice Note',
          pathOrUrl: attachmentId,
          createdAt: DateTime.now(),
        ),
      );
      matchedTracks = [
        {'path': att.pathOrUrl, 'name': att.name}
      ];
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF252234) : const Color(0xFFE9E6F5);

    final playerWidget = InlineAudioPlayer(
      tracks: matchedTracks,
      layout: layout,
      onLayoutChanged: embedContext.readOnly
          ? null
          : (newLayout) {
              _updateAudioEmbed(embedContext, attachmentId, matchedTracks.isEmpty ? null : matchedTracks, width, newLayout);
            },
      onTracksChanged: embedContext.readOnly
          ? null
          : (newTracks) {
              _updateAudioTracks(embedContext, newTracks, width, layout);
            },
      onDelete: () => _deleteAudioNode(embedContext),
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
                      _showAudioOptionsBottomSheet(
                        context,
                        attachmentId,
                        matchedTracks.isEmpty ? null : matchedTracks,
                        width,
                        layout,
                        embedContext,
                      );
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
    String? attachmentId,
    List<Map<String, String>>? audios,
    String currentWidth,
    String currentLayout,
    EmbedContext embedContext,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF13111C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: isDark ? const Color(0xFF252234) : const Color(0xFFE9E6F5)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SingleChildScrollView(
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
                    _updateAudioEmbed(embedContext, attachmentId, audios, newWidth, currentLayout);
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Player Style',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.waves_rounded, color: Color(0xFF8B5CF6)),
                  title: const Text('Classic Waveform'),
                  trailing: currentLayout == 'classic' ? const Icon(Icons.check_rounded, color: Color(0xFF8B5CF6)) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _updateAudioEmbed(embedContext, attachmentId, audios, currentWidth, 'classic');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.lens_blur_rounded, color: Color(0xFF8B5CF6)),
                  title: const Text('Minimalist Pill'),
                  trailing: currentLayout == 'pill' ? const Icon(Icons.check_rounded, color: Color(0xFF8B5CF6)) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _updateAudioEmbed(embedContext, attachmentId, audios, currentWidth, 'pill');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.album_rounded, color: Color(0xFF8B5CF6)),
                  title: const Text('Retro Vinyl'),
                  trailing: currentLayout == 'vinyl' ? const Icon(Icons.check_rounded, color: Color(0xFF8B5CF6)) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _updateAudioEmbed(embedContext, attachmentId, audios, currentWidth, 'vinyl');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.album_outlined, color: Color(0xFF8B5CF6)),
                  title: const Text('Retro Cassette'),
                  trailing: currentLayout == 'cassette' ? const Icon(Icons.check_rounded, color: Color(0xFF8B5CF6)) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _updateAudioEmbed(embedContext, attachmentId, audios, currentWidth, 'cassette');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.folder_shared_rounded, color: Color(0xFF8B5CF6)),
                  title: const Text('Folder Playlist'),
                  trailing: currentLayout == 'playlist' ? const Icon(Icons.check_rounded, color: Color(0xFF8B5CF6)) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _updateAudioEmbed(embedContext, attachmentId, audios, currentWidth, 'playlist');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.grid_view_rounded, color: Color(0xFF8B5CF6)),
                  title: const Text('Track Grid'),
                  trailing: currentLayout == 'grid' ? const Icon(Icons.check_rounded, color: Color(0xFF8B5CF6)) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _updateAudioEmbed(embedContext, attachmentId, audios, currentWidth, 'grid');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.view_quilt_rounded, color: Color(0xFF8B5CF6)),
                  title: const Text('Collage Player'),
                  trailing: currentLayout == 'collage' ? const Icon(Icons.check_rounded, color: Color(0xFF8B5CF6)) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _updateAudioEmbed(embedContext, attachmentId, audios, currentWidth, 'collage');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.layers_rounded, color: Color(0xFF8B5CF6)),
                  title: const Text('Stacked Tape Deck'),
                  trailing: currentLayout == 'deck' ? const Icon(Icons.check_rounded, color: Color(0xFF8B5CF6)) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _updateAudioEmbed(embedContext, attachmentId, audios, currentWidth, 'deck');
                  },
                ),
                const Divider(),
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
          ),
        );
      },
    );
  }

  void _updateAudioEmbed(
    EmbedContext embedContext,
    String? attachmentId,
    List<Map<String, String>>? audios,
    String currentWidth,
    String newLayout,
  ) {
    final offset = embedContext.node.documentOffset;
    final dataMap = <String, dynamic>{
      'width': currentWidth,
      'layout': newLayout,
    };
    if (audios != null) {
      dataMap['audios'] = audios;
    } else if (attachmentId != null) {
      dataMap['id'] = attachmentId;
    }
    final updatedBlock = BlockEmbed.custom(CustomBlockEmbed('audio', jsonEncode(dataMap)));

    embedContext.controller.replaceText(
      offset,
      1,
      updatedBlock,
      TextSelection.collapsed(offset: offset),
    );
  }

  void _updateAudioTracks(
    EmbedContext embedContext,
    List<Map<String, String>> newTracks,
    String currentWidth,
    String currentLayout,
  ) {
    final offset = embedContext.node.documentOffset;
    final dataMap = {
      'audios': newTracks,
      'width': currentWidth,
      'layout': currentLayout,
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
    final offset = embedContext.node.documentOffset;
    embedContext.controller.replaceText(
      offset,
      1,
      '',
      TextSelection.collapsed(offset: offset),
    );
  }
}
