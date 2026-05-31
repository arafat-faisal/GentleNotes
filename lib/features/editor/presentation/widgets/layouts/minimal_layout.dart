import 'package:flutter/material.dart';
import '../../../../../models/models.dart';
import '../../../domain/entities/block_entity.dart';
import '../../../domain/entities/block_type.dart';
import '../editor_blocks_list.dart';
import '../panels/floating_toolbar.dart';
import '../panels/metadata_panel.dart';

class MinimalLayout extends StatelessWidget {
  final String noteId;
  final TextEditingController titleController;
  final TextEditingController tagController;
  final String? selectedFolderId;
  final ValueChanged<String?> onFolderChanged;
  final NoteType noteType;
  final ValueChanged<NoteType> onNoteTypeChanged;
  final bool isPinned;
  final ValueChanged<bool> onPinChanged;
  final bool isFavorite;
  final ValueChanged<bool> onFavoriteChanged;
  final String colorHex;
  final ValueChanged<String> onColorChanged;
  final List<BlockEntity> blocks;
  final Map<String, FocusNode> focusNodes;
  final ScrollController scrollController;
  final VoidCallback onSave;
  final VoidCallback onPrintPdf;
  final bool isSpeechListening;
  final VoidCallback onSpeechToggle;
  final Function(BlockType, {String content, Map<String, dynamic> attributes}) onInsertBlock;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool canUndo;
  final bool canRedo;

  const MinimalLayout({
    super.key,
    required this.noteId,
    required this.titleController,
    required this.tagController,
    required this.selectedFolderId,
    required this.onFolderChanged,
    required this.noteType,
    required this.onNoteTypeChanged,
    required this.isPinned,
    required this.onPinChanged,
    required this.isFavorite,
    required this.onFavoriteChanged,
    required this.colorHex,
    required this.onColorChanged,
    required this.blocks,
    required this.focusNodes,
    required this.scrollController,
    required this.onSave,
    required this.onPrintPdf,
    required this.isSpeechListening,
    required this.onSpeechToggle,
    required this.onInsertBlock,
    required this.onUndo,
    required this.onRedo,
    required this.canUndo,
    required this.canRedo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C091A) : Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Minimal Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                        onPressed: () {
                          onSave();
                          Navigator.pop(context);
                        },
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.tune_rounded, size: 20),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (ctx) => SingleChildScrollView(
                                  padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                                  child: MetadataPanel(
                                    selectedFolderId: selectedFolderId,
                                    onFolderChanged: onFolderChanged,
                                    noteType: noteType,
                                    onNoteTypeChanged: onNoteTypeChanged,
                                    isPinned: isPinned,
                                    onPinChanged: onPinChanged,
                                    isFavorite: isFavorite,
                                    onFavoriteChanged: onFavoriteChanged,
                                    colorHex: colorHex,
                                    onColorChanged: onColorChanged,
                                    tagController: tagController,
                                  ),
                                ),
                              );
                            },
                            tooltip: 'Preferences',
                          ),
                          IconButton(
                            icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                            onPressed: onPrintPdf,
                            tooltip: 'Export PDF',
                          ),
                          IconButton(
                            icon: const Icon(Icons.done_all_rounded, size: 20),
                            onPressed: onSave,
                            tooltip: 'Save',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Title + Content Area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: titleController,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Untitled',
                            hintStyle: TextStyle(
                              color: theme.hintColor.withOpacity(0.2),
                              fontWeight: FontWeight.bold,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: EditorBlocksList(
                            blocks: blocks,
                            focusNodes: focusNodes,
                            scrollController: scrollController,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Bottom format bar
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Center(
                child: FloatingToolbar(
                  noteId: noteId,
                  onInsertBlock: onInsertBlock,
                  onUndo: onUndo,
                  onRedo: onRedo,
                  canUndo: canUndo,
                  canRedo: canRedo,
                  isSpeechListening: isSpeechListening,
                  onSpeechToggle: onSpeechToggle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
