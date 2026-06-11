import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../panels/voice_recorder_bottom_sheet.dart';

class AudioPlaylistManagerDialog extends StatefulWidget {
  final String noteId;
  final List<Map<String, dynamic>> tracks;
  final Function(List<Map<String, dynamic>> updatedTracks) onUpdate;

  const AudioPlaylistManagerDialog({
    super.key,
    required this.noteId,
    required this.tracks,
    required this.onUpdate,
  });

  @override
  State<AudioPlaylistManagerDialog> createState() => _AudioPlaylistManagerDialogState();
}

class _AudioPlaylistManagerDialogState extends State<AudioPlaylistManagerDialog> {
  late List<Map<String, dynamic>> _tracks;

  @override
  void initState() {
    super.initState();
    _tracks = List<Map<String, dynamic>>.from(
      widget.tracks.map((t) => Map<String, dynamic>.from(t)),
    );
  }

  void _triggerUpdate() {
    widget.onUpdate(_tracks);
    if (mounted) setState(() {});
  }

  void _deleteTrack(int index) {
    if (_tracks.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete the last track. Delete the entire block instead.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    _tracks.removeAt(index);
    _triggerUpdate();
  }

  Future<void> _addAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        withData: kIsWeb,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        String path = '';
        if (kIsWeb) {
          final bytes = file.bytes;
          if (bytes != null) {
            final base64Str = base64Encode(bytes);
            path = 'data:audio/mp3;base64,$base64Str';
          }
        } else {
          path = file.path?.replaceAll(r'\', '/') ?? '';
        }

        if (path.isNotEmpty) {
          final name = file.name;
          _tracks.add({
            'path': path,
            'name': name,
          });
          _triggerUpdate();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _recordNewAudio() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoiceRecorderBottomSheet(
        noteId: widget.noteId,
        onAttach: (filePath) {
          final name = filePath.startsWith('data:')
              ? 'Voice Note ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}.webm'
              : filePath.split('/').last;
          _tracks.add({
            'path': filePath,
            'name': name,
          });
          _triggerUpdate();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF13111C) : Colors.white,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Manage Voice Playlist',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Drag handles to reorder tracks. Click track names to rename.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                itemCount: _tracks.length,
                onReorderItem: (oldIndex, newIndex) {
                  setState(() {
                    final item = _tracks.removeAt(oldIndex);
                    _tracks.insert(newIndex, item);
                  });
                  _triggerUpdate();
                },
                itemBuilder: (context, index) {
                  final track = _tracks[index];
                  final path = track['path']?.toString() ?? '';
                  final name = track['name']?.toString() ?? 'Untitled Track';

                  return Card(
                    key: ValueKey('reorder_${path}_$index'),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: isDark ? const Color(0xFF1C192A) : Colors.grey.shade50,
                    elevation: 0,
                    child: ListTile(
                      dense: true,
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.drag_handle_rounded, color: Colors.grey),
                          const SizedBox(width: 8),
                          Icon(Icons.mic_rounded, color: theme.colorScheme.primary, size: 18),
                        ],
                      ),
                      title: TextFormField(
                        initialValue: name,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                        ),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        onChanged: (newVal) {
                          _tracks[index]['name'] = newVal;
                          widget.onUpdate(_tracks);
                        },
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        onPressed: () => _deleteTrack(index),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _addAudioFile,
                    icon: const Icon(Icons.audio_file_outlined, size: 16),
                    label: const Text('Add File', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _recordNewAudio,
                    icon: const Icon(Icons.mic_rounded, size: 16),
                    label: const Text('Record Track', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
