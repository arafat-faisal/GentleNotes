import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../../../models/models.dart';
import '../../../../folders/presentation/controllers/folders_controller.dart';
import '../../../../notes/presentation/controllers/notes_controller.dart';
import '../../../../../core/services/export_import_service.dart';
import '../../../domain/entities/block_entity.dart';
import '../../../domain/entities/block_type.dart';
import '../editor_body_widget.dart';
import '../panels/floating_toolbar.dart';
import '../panels/metadata_panel.dart';

class ZenLayout extends ConsumerStatefulWidget {
  final String noteId;
  final EditorMode editorMode;
  final QuillController? quillController;
  final FocusNode? editorFocusNode;
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
    required this.editorMode,
    this.quillController,
    this.editorFocusNode,
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
  ConsumerState<ZenLayout> createState() => _ZenLayoutState();
}

class _ZenLayoutState extends ConsumerState<ZenLayout> {
  bool _chromeVisible = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
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
                  padding: const EdgeInsets.fromLTRB(32, 48, 32, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 48), // Space for header
                      TextField(
                        controller: widget.titleController,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          height: 1.2,
                          color: theme.colorScheme.onSurface.withOpacity(0.9),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Begin…',
                          hintStyle: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: EditorBodyWidget(
                          editorMode: widget.editorMode,
                          quillController: widget.quillController,
                          editorFocusNode: widget.editorFocusNode,
                          noteType: widget.noteType,
                          attachments: const [],
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
                    color: theme.scaffoldBackgroundColor.withOpacity(0.8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                          style: IconButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                          ),
                          onPressed: () {
                            widget.onSave();
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              context.go('/home');
                            }
                          },
                        ),
                        const Spacer(),
                        Text(
                          'Zen',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            fontSize: 12,
                            color: theme.colorScheme.primary.withOpacity(0.8),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                widget.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                size: 18,
                              ),
                              color: widget.isPinned ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.6),
                              onPressed: () {
                                widget.onPinChanged(!widget.isPinned);
                                widget.onSave();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.tune_rounded, size: 18),
                              style: IconButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary,
                              ),
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
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert_rounded, size: 18, color: theme.colorScheme.primary),
                              onSelected: (val) async {
                                if (val == 'save') widget.onSave();
                                if (val == 'share') {
                                  widget.onSave();
                                  final note = ref.read(notesProvider).firstWhere((n) => n.id == widget.noteId);
                                  final folders = ref.read(foldersProvider);
                                  final folder = folders.cast<FolderModel?>().firstWhere(
                                        (f) => f?.id == widget.selectedFolderId,
                                        orElse: () => null,
                                      );
                                  ExportImportService().shareNote(note, folderName: folder?.name);
                                }
                                if (val == 'delete') {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('Delete Note'),
                                        content: const Text('Are you sure you want to permanently delete this note?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              await ref.read(notesProvider.notifier).deleteNote(widget.noteId);
                                              if (context.mounted) {
                                                Navigator.pop(context);
                                                context.pop();
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'save',
                                  child: Row(
                                    children: [
                                      Icon(Icons.save_outlined),
                                      SizedBox(width: 8),
                                      Text('Save Note'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'share',
                                  child: Row(
                                    children: [
                                      Icon(Icons.share_outlined),
                                      SizedBox(width: 8),
                                      Text('Share Note'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete Note', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
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
                      quillController: widget.quillController,
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
