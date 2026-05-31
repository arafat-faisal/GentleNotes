import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../domain/entities/block_type.dart';
import 'voice_recorder_bottom_sheet.dart';

class FloatingToolbar extends StatelessWidget {
  final String noteId;
  final Function(BlockType type, {String content, Map<String, dynamic> attributes}) onInsertBlock;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool canUndo;
  final bool canRedo;
  final bool isSpeechListening;
  final VoidCallback onSpeechToggle;

  const FloatingToolbar({
    super.key,
    required this.noteId,
    required this.onInsertBlock,
    required this.onUndo,
    required this.onRedo,
    required this.canUndo,
    required this.canRedo,
    required this.isSpeechListening,
    required this.onSpeechToggle,
  });

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
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
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF8B5CF6)),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (source != null) {
      final file = await picker.pickImage(source: source);
      if (file != null) {
        onInsertBlock(BlockType.image, content: 'file://${file.path}');
      }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final barBg = isDark ? const Color(0xFF1E1A30).withOpacity(0.9) : Colors.white.withOpacity(0.9);
    final borderCol = isDark ? const Color(0xFF2E2845) : const Color(0xFFE3DCF5);

    return Material(
      color: Colors.transparent,
      elevation: 6,
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: barBg,
            border: Border.all(color: borderCol, width: 1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Undo / Redo
                IconButton(
                  icon: Icon(Icons.undo_rounded, size: 20, color: canUndo ? theme.colorScheme.primary : theme.disabledColor),
                  onPressed: canUndo ? onUndo : null,
                  tooltip: 'Undo',
                ),
                IconButton(
                  icon: Icon(Icons.redo_rounded, size: 20, color: canRedo ? theme.colorScheme.primary : theme.disabledColor),
                  onPressed: canRedo ? onRedo : null,
                  tooltip: 'Redo',
                ),
                const VerticalDivider(width: 16, indent: 12, endIndent: 12),

                // Block types
                IconButton(
                  icon: const Icon(Icons.title_rounded, size: 20),
                  onPressed: () => onInsertBlock(BlockType.heading, attributes: {'header': 1}),
                  tooltip: 'Heading 1',
                ),
                IconButton(
                  icon: const Icon(Icons.format_list_bulleted_rounded, size: 20),
                  onPressed: () => onInsertBlock(BlockType.checklist),
                  tooltip: 'To-do List',
                ),
                IconButton(
                  icon: const Icon(Icons.code_rounded, size: 20),
                  onPressed: () => onInsertBlock(BlockType.code),
                  tooltip: 'Code Snippet',
                ),
                IconButton(
                  icon: const Icon(Icons.image_outlined, size: 20),
                  onPressed: () => _pickImage(context),
                  tooltip: 'Insert Image',
                ),
                IconButton(
                  icon: const Icon(Icons.draw_outlined, size: 20),
                  onPressed: () => onInsertBlock(BlockType.drawing),
                  tooltip: 'Sketch Canvas',
                ),
                IconButton(
                  icon: const Icon(Icons.mic_none_rounded, size: 20),
                  onPressed: () => _recordAudio(context),
                  tooltip: 'Voice Recording',
                ),
                IconButton(
                  icon: const Icon(Icons.horizontal_rule_rounded, size: 20),
                  onPressed: () => onInsertBlock(BlockType.horizontalRule),
                  tooltip: 'Divider',
                ),

                const VerticalDivider(width: 16, indent: 12, endIndent: 12),

                // Speech Dictation
                IconButton(
                  icon: Icon(
                    isSpeechListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    size: 20,
                    color: isSpeechListening ? Colors.red : null,
                  ),
                  onPressed: onSpeechToggle,
                  tooltip: 'Dictation (Voice typing)',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
