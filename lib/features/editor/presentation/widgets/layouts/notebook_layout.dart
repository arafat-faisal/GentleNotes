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

class NotebookLayout extends ConsumerWidget {
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

  const NotebookLayout({
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
    final accent = theme.colorScheme.primary;

    final sidebarBg = theme.cardColor;
    final mainBg = theme.scaffoldBackgroundColor;
    final borderCol = theme.dividerColor;

    final folders = ref.watch(foldersProvider);

    // Note: do NOT hide sections based on keyboard visibility — that causes
    // layout shifts which drop the editor FocusNode and immediately dismiss the keyboard.
    final screenWidth = MediaQuery.of(context).size.width;
    // Always show sidebar, but make it narrower on small screens.
    const showSidebar = true;
    final sidebarWidth = screenWidth < 400 ? 160.0 : (screenWidth < 600 ? 200.0 : 300.0);

    Widget sidebar = SizedBox(
      width: sidebarWidth,
      child: Container(
        color: sidebarBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Slim top bar ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderCol)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
                    onPressed: () {
                      onSave();
                      Navigator.pop(context);
                    },
                    style: IconButton.styleFrom(
                      foregroundColor: accent,
                      padding: const EdgeInsets.all(4),
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.save_outlined, size: 15),
                    onPressed: onSave,
                    style: IconButton.styleFrom(
                      foregroundColor: accent,
                      padding: const EdgeInsets.all(4),
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable metadata section ──────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title label
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                      child: Text('TITLE',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: accent,
                              letterSpacing: 0.8)),
                    ),
                    // Title field
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                      child: TextField(
                        controller: titleController,
                        maxLines: 3,
                        minLines: 1,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                          height: 1.3,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Untitled',
                          hintStyle: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),

                    Divider(height: 1, indent: 14, endIndent: 14, color: borderCol),
                    const SizedBox(height: 8),

                    // Folder label
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 2),
                      child: Text('FOLDER',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: accent,
                              letterSpacing: 0.8)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: selectedFolderId,
                          isExpanded: true,
                          isDense: true,
                          hint: Row(
                            children: [
                              Icon(Icons.folder_outlined, size: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text('No Folder',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                              ),
                            ],
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Row(children: [
                                Icon(Icons.folder_off_outlined, size: 12),
                                SizedBox(width: 4),
                                Flexible(child: Text('No Folder', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11))),
                              ]),
                            ),
                            ...folders.map((f) => DropdownMenuItem<String?>(
                                  value: f.id,
                                  child: Row(children: [
                                    Container(width: 7, height: 7, decoration: BoxDecoration(color: f.color, shape: BoxShape.circle)),
                                    const SizedBox(width: 6),
                                    Flexible(child: Text(f.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11))),
                                  ]),
                                )),
                          ],
                          onChanged: onFolderChanged,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Note Type label
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 2),
                      child: Text('TYPE',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: accent,
                              letterSpacing: 0.8)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<NoteType>(
                          value: noteType,
                          isExpanded: true,
                          isDense: true,
                          items: NoteType.values
                              .map((t) => DropdownMenuItem<NoteType>(
                                    value: t,
                                    child: Row(children: [
                                      Icon(t.icon, size: 12, color: accent),
                                      const SizedBox(width: 5),
                                      Flexible(child: Text(t.displayName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11))),
                                    ]),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              onNoteTypeChanged(val);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Divider(height: 1, indent: 14, endIndent: 14, color: borderCol),
                    const SizedBox(height: 8),

                    // Tags label
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 2),
                      child: Text('TAGS',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: accent,
                              letterSpacing: 0.8)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                      child: Row(
                        children: [
                          Icon(Icons.local_offer_outlined, size: 12, color: accent.withOpacity(0.7)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: TextField(
                              controller: tagController,
                              style: const TextStyle(fontSize: 11),
                              decoration: const InputDecoration(
                                hintText: 'tag1, tag2…',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    Divider(height: 1, indent: 14, endIndent: 14, color: borderCol),
                    const SizedBox(height: 4),

                    // Pin / Fave / Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 16),
                            color: isPinned ? accent : null,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                            onPressed: () => onPinChanged(!isPinned),
                          ),
                          IconButton(
                            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, size: 16),
                            color: isFavorite ? const Color(0xFFF43F5E) : null,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                            onPressed: () => onFavoriteChanged(!isFavorite),
                          ),
                          const Spacer(),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_horiz_rounded, size: 16, color: accent),
                            padding: const EdgeInsets.all(4),
                            onSelected: (val) async {
                              if (val == 'share') {
                                onSave();
                                final note = ref.read(notesProvider).firstWhere((n) => n.id == noteId);
                                final folders = ref.read(foldersProvider);
                                final folder = folders.cast<FolderModel?>().firstWhere(
                                      (f) => f?.id == selectedFolderId,
                                      orElse: () => null,
                                    );
                                ExportImportService().shareNote(note, folderName: folder?.name);
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
                                value: 'share',
                                child: Row(
                                  children: [
                                    Icon(Icons.share_outlined),
                                    SizedBox(width: 8),
                                    Text('Share'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'md',
                                child: Row(
                                  children: [
                                    Icon(Icons.article_outlined),
                                    SizedBox(width: 8),
                                    Text('Export MD'),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: mainBg,
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showSidebar) ...[
                  sidebar,
                  Container(width: 1, color: borderCol),
                ],
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 80.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title is always in the sidebar; no inline title needed.

                        Expanded(
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
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Floating format bar
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
