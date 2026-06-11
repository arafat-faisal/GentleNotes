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
import '../panels/share_note_bottom_sheet.dart';

class MinimalLayout extends ConsumerWidget {
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

  const MinimalLayout({
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final folders = ref.watch(foldersProvider);
    final folder = folders.cast<FolderModel?>().firstWhere((f) => f?.id == selectedFolderId, orElse: () => null);
    final folderColor = folder?.color ?? theme.colorScheme.secondary;

    Widget metaChip({required IconData icon, required String label, required Color color}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Slim top bar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                        onPressed: () {
                          onSave();
                          Navigator.pop(context);
                        },
                        style: IconButton.styleFrom(foregroundColor: accent),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 18),
                        color: isPinned ? theme.colorScheme.secondary : accent,
                        onPressed: () => onPinChanged(!isPinned),
                      ),
                      IconButton(
                        icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, size: 18),
                        color: isFavorite ? const Color(0xFFF43F5E) : accent,
                        onPressed: () => onFavoriteChanged(!isFavorite),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded, size: 18, color: accent),
                        onSelected: (val) async {
                          if (val == 'save') onSave();
                          if (val == 'share') {
                            onSave();
                            final note = ref.read(notesProvider).firstWhere((n) => n.id == noteId);
                            final folders = ref.read(foldersProvider);
                            final folder = folders.cast<FolderModel?>().firstWhere(
                                  (f) => f?.id == selectedFolderId,
                                  orElse: () => null,
                                );
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => ShareNoteBottomSheet(
                                note: note,
                                folderName: folder?.name,
                              ),
                            );
                          }
                          if (val == 'md') {
                            onSave();
                            final note = ref.read(notesProvider).firstWhere((n) => n.id == noteId);
                            final markdown = ExportImportService().exportNoteAsMarkdown(note);
                            await Share.share(markdown, subject: '${note.title}.md');
                          }
                          if (val == 'pdf') onPrintPdf();
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
                                        await ref.read(notesProvider.notifier).deleteNote(noteId);
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
                            value: 'md',
                            child: Row(
                              children: [
                                Icon(Icons.article_outlined),
                                SizedBox(width: 8),
                                Text('Export Markdown'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'pdf',
                            child: Row(
                              children: [
                                Icon(Icons.picture_as_pdf_outlined),
                                SizedBox(width: 8),
                                Text('Export PDF'),
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
                ),

                // ── Large inline title ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                  child: TextField(
                    controller: titleController,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      height: 1.2,
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Untitled Note',
                      hintStyle: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),

                // ── Meta chips (folder, type) ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        metaChip(
                          icon: Icons.folder_outlined,
                          label: folder?.name ?? 'No Folder',
                          color: folderColor,
                        ),
                        const SizedBox(width: 8),
                        metaChip(
                          icon: noteType.icon,
                          label: noteType.displayName,
                          color: accent,
                        ),
                      ],
                    ),
                  ),
                ),

                Divider(
                  height: 16,
                  indent: 24,
                  endIndent: 24,
                  color: theme.dividerColor,
                ),

                // ── Editor body ────────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
                    child: EditorBodyWidget(
                      editorMode: editorMode,
                      quillController: quillController,
                      editorFocusNode: editorFocusNode,
                      noteType: noteType,
                      attachments: const [],
                      blocks: blocks,
                      focusNodes: focusNodes,
                      scrollController: scrollController,
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
                  quillController: quillController,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
