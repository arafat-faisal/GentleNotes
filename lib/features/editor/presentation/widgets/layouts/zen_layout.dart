import 'package:flutter/material.dart';
import '../../../../../models/models.dart';
import '../../../domain/entities/block_entity.dart';
import '../../../domain/entities/block_type.dart';
import '../editor_blocks_list.dart';
import '../panels/floating_toolbar.dart';
import '../panels/metadata_panel.dart';

class ZenLayout extends StatefulWidget {
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

  const ZenLayout({
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
  State<ZenLayout> createState() => _ZenLayoutState();
}

class _ZenLayoutState extends State<ZenLayout> {
  bool _chromeVisible = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF07050E) : const Color(0xFFFBFBFC),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _chromeVisible = !_chromeVisible;
            });
          },
          child: Stack(
            children: [
              // Editor Content Area (always interactive)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 60), // Space for header
                      TextField(
                        controller: widget.titleController,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Zen Writing...',
                          hintStyle: TextStyle(
                            color: theme.hintColor.withOpacity(0.15),
                            fontWeight: FontWeight.w700,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: EditorBlocksList(
                          blocks: widget.blocks,
                          focusNodes: widget.focusNodes,
                          scrollController: widget.scrollController,
                        ),
                      ),
                      const SizedBox(height: 80), // Space for toolbar
                    ],
                  ),
                ),
              ),

              // Animated Top Header Chrome
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top: _chromeVisible ? 0 : -80,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _chromeVisible ? 1.0 : 0.0,
                  child: Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    color: isDark ? const Color(0xFF07050E).withOpacity(0.8) : const Color(0xFFFBFBFC).withOpacity(0.8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                          onPressed: () {
                            widget.onSave();
                            Navigator.pop(context);
                          },
                        ),
                        const Text(
                          'Zen Mode',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            fontSize: 12,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.tune_rounded, size: 18),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (ctx) => SingleChildScrollView(
                                    padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                                    child: MetadataPanel(
                                      selectedFolderId: widget.selectedFolderId,
                                      onFolderChanged: widget.onFolderChanged,
                                      noteType: widget.noteType,
                                      onNoteTypeChanged: widget.onNoteTypeChanged,
                                      isPinned: widget.isPinned,
                                      onPinChanged: widget.onPinChanged,
                                      isFavorite: widget.isFavorite,
                                      onFavoriteChanged: widget.onFavoriteChanged,
                                      colorHex: widget.colorHex,
                                      onColorChanged: widget.onColorChanged,
                                      tagController: widget.tagController,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.done_rounded, size: 18),
                              onPressed: widget.onSave,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Animated Bottom Formatting Toolbar Chrome
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                bottom: _chromeVisible ? 16 : -100,
                left: 16,
                right: 16,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _chromeVisible ? 1.0 : 0.0,
                  child: Center(
                    child: FloatingToolbar(
                      noteId: widget.noteId,
                      onInsertBlock: widget.onInsertBlock,
                      onUndo: widget.onUndo,
                      onRedo: widget.onRedo,
                      canUndo: widget.canUndo,
                      canRedo: widget.canRedo,
                      isSpeechListening: widget.isSpeechListening,
                      onSpeechToggle: widget.onSpeechToggle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
