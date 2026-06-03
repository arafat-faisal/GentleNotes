import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import '../../../../../models/models.dart';
import '../../../../folders/presentation/controllers/folders_controller.dart';
import '../../../../notes/presentation/controllers/notes_controller.dart';
import '../../../../../core/services/export_import_service.dart';
import '../editor_body_widget.dart';
import 'aesthetic_layouts.dart';

class CardsLayout extends ConsumerWidget {
  final AestheticLayout layout;
  const CardsLayout({super.key, required this.layout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    final bg = isDark ? const Color(0xFF0F0B1E) : const Color(0xFFF9F7FF);
    final cardBg = isDark ? const Color(0xFF151026) : Colors.white;
    final border = isDark ? const Color(0xFF2E2845) : const Color(0xFFE9E6F5);

    final folders = ref.watch(foldersProvider);
    final folder = folders.cast<FolderModel?>().firstWhere(
          (f) => f?.id == layout.selectedFolderId,
          orElse: () => null,
        );
    final coverColor = folder?.color ?? accent;

    Color headerColor;
    try {
      final hex = layout.colorHex.replaceAll('#', '');
      headerColor = hex.toUpperCase() == 'FFFFFF'
          ? coverColor
          : Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      headerColor = coverColor;
    }


    return Container(
      color: bg,
      child: Column(
        children: [
          // ── Color cover card ──
          Container(
            color: headerColor,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      onPressed: () {
                        layout.onSave();
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          context.go('/home');
                        }
                      },
                      style: IconButton.styleFrom(foregroundColor: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        layout.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        size: 18,
                      ),
                      color: Colors.white,
                      onPressed: () {
                        layout.onPinChanged(!layout.isPinned);
                        layout.onSave();
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        layout.isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                      ),
                      color: Colors.white,
                      onPressed: () {
                        layout.onFavoriteChanged(!layout.isFavorite);
                        layout.onSave();
                      },
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 18, color: Colors.white),
                      onSelected: (val) async {
                        if (val == 'save') layout.onSave();
                        if (val == 'share') {
                          layout.onSave();
                          final note = ref.read(notesProvider).firstWhere((n) => n.id == layout.noteId);
                          ExportImportService().shareNote(note, folderName: folder?.name);
                        }
                        if (val == 'md') {
                          layout.onSave();
                          final note = ref.read(notesProvider).firstWhere((n) => n.id == layout.noteId);
                          final markdown = ExportImportService().exportNoteAsMarkdown(note);
                          await Share.share(markdown, subject: '${note.title}.md');
                        }
                        if (val == 'pdf') layout.onPrintPdf();
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
                                      await ref.read(notesProvider.notifier).deleteNote(layout.noteId);
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: TextField(
                    controller: layout.titleController,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                      height: 1.2,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Untitled Note',
                      hintStyle: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white54,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Meta chips row ──
          Container(
            color: cardBg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Color picker chips
                  ...['#FFFFFF', '#FEE2E2', '#FEF3C7', '#ECFDF5', '#E0F2FE', '#F3E8FF', '#FDF4FF'].map((c) {
                    final isSelected = layout.colorHex == c;
                    final col = c == '#FFFFFF'
                        ? Colors.grey.shade300
                        : Color(int.parse('FF${c.replaceAll('#', '')}', radix: 16));
                    return GestureDetector(
                      onTap: () => layout.onColorChanged(c),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: col,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? theme.colorScheme.onSurface : Colors.grey.shade400,
                            width: isSelected ? 2 : 0.5,
                          ),
                        ),
                      ),
                    );
                  }),
                  Container(
                    width: 1,
                    height: 18,
                    color: border,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<NoteType>(
                      value: layout.noteType,
                      isDense: true,
                      items: NoteType.values
                          .map((t) => DropdownMenuItem<NoteType>(
                                value: t,
                                child: Row(
                                  children: [
                                    Icon(t.icon, size: 13, color: accent),
                                    const SizedBox(width: 4),
                                    Text(t.displayName, style: const TextStyle(fontSize: 11)),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          layout.onNoteTypeChanged(val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: border),

          // ── Main editor card ──
          Expanded(
            child: Container(
              color: cardBg,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), // 80 padding for FloatingToolbar
              child: EditorBodyWidget(
                editorMode: layout.editorMode,
                quillController: layout.quillController,
                editorFocusNode: layout.editorFocusNode,
                noteType: layout.noteType,
                attachments: layout.attachments,
                blocks: layout.blocks,
                focusNodes: layout.focusNodes,
                scrollController: layout.scrollController,
              ),
            ),
          ),

          // Tags bar — always visible; hiding it based on keyboard causes layout shifts that drop focus.
          ...[
            Container(height: 1, color: border),
            Container(
              color: cardBg,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 80), // extra padding so it aligns nicely with toolbar spacing
              child: Row(
                children: [
                  Icon(Icons.local_offer_outlined, size: 16, color: accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: layout.tagController,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Add tags...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
