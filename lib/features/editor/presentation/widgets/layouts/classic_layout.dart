import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../models/models.dart';
import '../../../domain/entities/block_entity.dart';
import '../../../domain/entities/block_type.dart';
import '../../../../../core/widgets/gentle_scaffold.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../editor_blocks_list.dart';
import '../panels/floating_toolbar.dart';
import '../panels/metadata_panel.dart';

class ClassicLayout extends ConsumerWidget {
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

  const ClassicLayout({
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = ResponsiveHelper.isMobile(context);

    // Resolve base background color matching accent color settings
    final bgColor = colorHex == '#FFFFFF'
        ? (isDark ? const Color(0xFF0F0B1E) : Colors.white)
        : Color(int.parse('FF${colorHex.replaceAll('#', '')}', radix: 16)).withOpacity(isDark ? 0.15 : 0.8);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            onSave();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          noteId.startsWith('new_') ? 'New Note' : 'Edit Note',
          style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: onPrintPdf,
            tooltip: 'Export PDF',
          ),
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: onSave,
            tooltip: 'Save',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Main Editor column
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        // Title Field
                        TextField(
                          controller: titleController,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Untitled Note',
                            hintStyle: TextStyle(color: theme.hintColor.withOpacity(0.3)),
                            border: InputBorder.none,
                          ),
                        ),
                        const Divider(height: 1),
                        const SizedBox(height: 8),

                        // Blocks Editor Scrollable List
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
                // Sidebar panel for metadata on large screens (desktop/tablet)
                if (!isMobile)
                  Container(
                    width: 320,
                    margin: const EdgeInsets.only(right: 16, bottom: 80, top: 8),
                    child: SingleChildScrollView(
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
                  ),
              ],
            ),

            // Drawer trigger button or Floating Sheet trigger for mobile
            if (isMobile)
              Positioned(
                bottom: 80,
                right: 16,
                child: FloatingActionButton.small(
                  backgroundColor: theme.colorScheme.primary,
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
                  child: const Icon(Icons.settings_outlined, color: Colors.white),
                ),
              ),

            // Floating format bar at the bottom
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
