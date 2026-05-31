import 'package:flutter/material.dart';
import '../../../../../models/models.dart';
import '../../../domain/entities/block_entity.dart';
import '../../../domain/entities/block_type.dart';
import '../panels/floating_toolbar.dart';
import '../panels/metadata_panel.dart';

import 'journal_layout.dart';
import 'scrapbook_layout.dart';
import 'petal_layout.dart';
import 'stardust_layout.dart';
import 'cards_layout.dart';

class AestheticLayout extends StatelessWidget {
  final EditorLayoutVariant variant;
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

  const AestheticLayout({
    super.key,
    required this.variant,
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

    Widget body;
    Color? backgroundColor;
    Decoration? decoration;

    switch (variant) {
      case EditorLayoutVariant.journal:
        backgroundColor = isDark ? const Color(0xFF131A0B) : const Color(0xFFF9FDF5);
        body = JournalLayout(layout: this);
        break;

      case EditorLayoutVariant.scrapbook:
        backgroundColor = isDark ? const Color(0xFF160A1A) : const Color(0xFFFFF8FF);
        body = ScrapbookLayout(layout: this);
        break;

      case EditorLayoutVariant.petal:
        backgroundColor = isDark ? const Color(0xFF1A0710) : const Color(0xFFFFF5F9);
        body = PetalLayout(layout: this);
        break;

      case EditorLayoutVariant.stardust:
        decoration = BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF07031A), const Color(0xFF110A2E)]
                : [const Color(0xFF150A38), const Color(0xFF2A1060)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
        body = StardustLayout(layout: this);
        break;

      case EditorLayoutVariant.cards:
      default:
        backgroundColor = isDark ? const Color(0xFF13111C) : const Color(0xFFF5F3FF);
        body = CardsLayout(layout: this);
        break;
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        decoration: decoration,
        child: SafeArea(
          child: Stack(
            children: [
              body,

              // Floating toolbar at bottom
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
      ),
    );
  }

  Widget buildAestheticHeader(
    BuildContext context,
    String title,
    IconData icon, {
    Color? darkThemeColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = darkThemeColor ?? (isDark ? Colors.white70 : Colors.black87);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: color),
            onPressed: () {
              onSave();
              Navigator.pop(context);
            },
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0,
                  color: color,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.tune_rounded, size: 18, color: color),
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
              ),
              IconButton(
                icon: Icon(Icons.picture_as_pdf_rounded, size: 18, color: color),
                onPressed: onPrintPdf,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
