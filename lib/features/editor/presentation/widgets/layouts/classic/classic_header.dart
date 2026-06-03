import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../../../../models/models.dart';
import '../../../../../folders/presentation/controllers/folders_controller.dart';
import '../../../../../notes/presentation/controllers/notes_controller.dart';
import '../../../../../../core/services/export_import_service.dart';
import '../../../../../../core/utils/quill_markdown_converter.dart';
import '../../../../domain/entities/block_entity.dart';
import '../../../../domain/entities/block_type.dart';
import '../../../../domain/usecases/convert_blocks_to_delta.dart';
import '../../panels/voice_recorder_bottom_sheet.dart';
import '../../preview_style_painter.dart';

class ClassicHeader extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final String noteId;
  final EditorMode editorMode;
  final QuillController? quillController;
  final List<BlockEntity> blocks;
  final TextEditingController titleController;
  final String? selectedFolderId;
  
  final bool isPinned;
  final ValueChanged<bool> onPinChanged;
  final bool isFavorite;
  final ValueChanged<bool> onFavoriteChanged;

  final bool isToolsTabSelected;
  final ValueChanged<bool> onToolsTabSelectedChanged;
  final bool isPreviewMode;
  final ValueChanged<bool> onPreviewModeChanged;

  final PreviewStyle previewStyle;
  final ValueChanged<PreviewStyle> onPreviewStyleChanged;
  
  final VoidCallback onSave;
  final VoidCallback onPrintPdf;
  final VoidCallback onEnterFullScreen;
  final VoidCallback onEnterFocusMode;
  final Function(BlockType, {String content, Map<String, dynamic> attributes}) onInsertBlock;

  const ClassicHeader({
    super.key,
    required this.noteId,
    required this.editorMode,
    this.quillController,
    required this.blocks,
    required this.titleController,
    required this.selectedFolderId,
    required this.isPinned,
    required this.onPinChanged,
    required this.isFavorite,
    required this.onFavoriteChanged,
    required this.isToolsTabSelected,
    required this.onToolsTabSelectedChanged,
    required this.isPreviewMode,
    required this.onPreviewModeChanged,
    required this.previewStyle,
    required this.onPreviewStyleChanged,
    required this.onSave,
    required this.onPrintPdf,
    required this.onEnterFullScreen,
    required this.onEnterFocusMode,
    required this.onInsertBlock,
  });

  @override
  ConsumerState<ClassicHeader> createState() => _ClassicHeaderState();

  @override
  Size get preferredSize => Size.fromHeight(isToolsTabSelected ? 168.0 : 112.0); // Will be dynamically adjusted in PreferredSize if needed
}

class _ClassicHeaderState extends ConsumerState<ClassicHeader> {
  String _getMarkdownData() {
    if (widget.editorMode == EditorMode.gentleNote && widget.quillController != null) {
      return QuillMarkdownConverter.deltaToMarkdown(
        jsonEncode(widget.quillController!.document.toDelta().toJson()),
      );
    } else {
      return QuillMarkdownConverter.deltaToMarkdown(
        ConvertBlocksToDelta.execute(widget.blocks),
      );
    }
  }

  void _toggleVoiceRecording() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoiceRecorderBottomSheet(
        noteId: widget.noteId,
        onAttach: (filePath) {
          widget.onInsertBlock(BlockType.audio, content: filePath);
        },
      ),
    );
  }

  Future<void> _openDrawingCanvas() async {
    widget.onInsertBlock(BlockType.drawing);
  }

  Future<void> _handleExportMarkdown(BuildContext context) async {
    widget.onSave();
    final note = ref.read(notesProvider).firstWhere((n) => n.id == widget.noteId);
    final markdown = ExportImportService().exportNoteAsMarkdown(note);
    await Share.share(markdown, subject: '${note.title}.md');
  }

  Widget _buildToolIcon({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }

  PopupMenuItem<PreviewStyle> _previewStyleMenuItem(
      PreviewStyle style, IconData icon, String label) {
    final theme = Theme.of(context);
    return PopupMenuItem<PreviewStyle>(
      value: style,
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: widget.previewStyle == style ? theme.colorScheme.primary : null),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: widget.previewStyle == style ? FontWeight.bold : FontWeight.normal,
                  color: widget.previewStyle == style ? theme.colorScheme.primary : null)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.appBarTheme.backgroundColor != Colors.transparent
            ? theme.appBarTheme.backgroundColor
            : theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1 (Navigation & Core Utility)
            SizedBox(
              height: 56.0,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    color: theme.appBarTheme.iconTheme?.color ?? theme.colorScheme.onSurface,
                    onPressed: () {
                      widget.onSave();
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/home');
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: TextField(
                        controller: widget.titleController,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: theme.colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Note Title...',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.38),
                            fontSize: 18,
                          ),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          fillColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(widget.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                    color: widget.isPinned ? theme.colorScheme.primary : theme.colorScheme.primary,
                    tooltip: widget.isPinned ? 'Unpin Note' : 'Pin Note',
                    onPressed: () {
                      widget.onPinChanged(!widget.isPinned);
                      widget.onSave();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.fullscreen_rounded, color: theme.colorScheme.primary),
                    tooltip: 'Fullscreen Mode',
                    onPressed: widget.onEnterFullScreen,
                  ),
                  IconButton(
                    icon: Icon(
                      widget.isToolsTabSelected ? Icons.handyman_rounded : Icons.handyman_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    tooltip: 'Tools',
                    onPressed: () {
                      widget.onToolsTabSelectedChanged(!widget.isToolsTabSelected);
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      widget.isPreviewMode ? Icons.edit_note_rounded : Icons.preview_rounded,
                      color: widget.isPreviewMode ? const Color(0xFF10B981) : theme.colorScheme.primary,
                    ),
                    tooltip: widget.isPreviewMode ? 'Back to Editor' : 'Preview (Reader View)',
                    onPressed: () {
                      widget.onPreviewModeChanged(!widget.isPreviewMode);
                    },
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: theme.colorScheme.primary),
                    onSelected: (val) {
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
                                    if (mounted) {
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
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'save', child: Row(children: [Icon(Icons.save_outlined), SizedBox(width: 8), Text('Save Note')])),
                      const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share_outlined), SizedBox(width: 8), Text('Share Note')])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red), SizedBox(width: 8), Text('Delete Note', style: TextStyle(color: Colors.red))])),
                    ],
                  ),
                ],
              ),
            ),
            
            // Row 2 (Functional Tabs or Categorized Groups)
            if (widget.isToolsTabSelected)
              Container(
                height: 46.0,
                margin: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 8.0),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : theme.colorScheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : theme.colorScheme.primary.withOpacity(0.12),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.15 : 0.02),
                      blurRadius: 8.0,
                      offset: const Offset(0.0, 3.0),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final List<Widget> toolButtons = [
                            _buildToolIcon(
                              icon: Icons.mic_rounded,
                              color: theme.colorScheme.primary,
                              tooltip: 'Record Voice Note',
                              onTap: _toggleVoiceRecording,
                            ),
                            _buildToolIcon(
                              icon: Icons.draw_rounded,
                              color: theme.colorScheme.primary,
                              tooltip: 'Open Drawing Canvas',
                              onTap: _openDrawingCanvas,
                            ),
                            _buildToolIcon(
                              icon: Icons.calendar_month_rounded,
                              color: theme.colorScheme.primary,
                              tooltip: 'Calendar & Reminders',
                              onTap: () => context.push('/calendar'),
                            ),
                            _buildToolIcon(
                              icon: Icons.center_focus_strong_rounded,
                              color: theme.colorScheme.primary,
                              tooltip: 'Zen Writing Mode (Focus)',
                              onTap: widget.onEnterFocusMode,
                            ),
                            _buildToolIcon(
                              icon: Icons.article_outlined,
                              color: theme.colorScheme.primary,
                              tooltip: 'Export as Markdown (MD)',
                              onTap: () => _handleExportMarkdown(context),
                            ),
                            _buildToolIcon(
                              icon: Icons.picture_as_pdf_rounded,
                              color: theme.colorScheme.primary,
                              tooltip: 'Export as PDF',
                              onTap: widget.onPrintPdf,
                            ),
                            PopupMenuButton<PreviewStyle>(
                              tooltip: 'Preview Style',
                              icon: Icon(Icons.style_rounded, size: 20, color: theme.colorScheme.primary),
                              offset: const Offset(0, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: theme.dividerColor,
                                  width: 1,
                                ),
                              ),
                              onSelected: widget.onPreviewStyleChanged,
                              itemBuilder: (context) => [
                                _previewStyleMenuItem(PreviewStyle.plain, Icons.article_outlined, 'Plain'),
                                _previewStyleMenuItem(PreviewStyle.notebook, Icons.menu_book_outlined, 'Ruled Notebook'),
                                _previewStyleMenuItem(PreviewStyle.grid, Icons.grid_on_rounded, 'Graph Grid'),
                                _previewStyleMenuItem(PreviewStyle.leaf, Icons.eco_outlined, 'Aged Paper'),
                                _previewStyleMenuItem(PreviewStyle.spiral, Icons.view_agenda_outlined, 'Spiral Ruled'),
                                _previewStyleMenuItem(PreviewStyle.dark, Icons.nights_stay_outlined, 'Dark Parchment'),
                              ],
                            ),
                            _buildToolIcon(
                              icon: widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: widget.isFavorite ? const Color(0xFFF43F5E) : theme.colorScheme.primary,
                              tooltip: widget.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                              onTap: () {
                                widget.onFavoriteChanged(!widget.isFavorite);
                                widget.onSave();
                              },
                            ),
                          ];

                          if (constraints.maxWidth < 250) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: toolButtons.map((w) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: w,
                                )).toList(),
                              ),
                            );
                          }

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: toolButtons,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
