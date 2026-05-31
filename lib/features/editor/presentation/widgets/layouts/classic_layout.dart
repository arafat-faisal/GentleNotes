import 'dart:convert';
import 'dart:io' as io;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../models/models.dart';
import '../../../../folders/presentation/controllers/folders_controller.dart';
import '../../../../notes/presentation/controllers/notes_controller.dart';
import '../../../../../core/services/export_import_service.dart';
import '../../../../../core/widgets/gentle_scaffold.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../../../core/utils/quill_markdown_converter.dart';
import '../../../domain/entities/block_entity.dart';
import '../../../domain/entities/block_type.dart';
import '../../../domain/usecases/convert_blocks_to_delta.dart';
import '../editor_body_widget.dart';
import '../panels/floating_toolbar.dart';
import '../panels/voice_recorder_bottom_sheet.dart';
import '../blocks/drawing_canvas_screen.dart';
import '../markdown_widget.dart';
import '../preview_style_painter.dart';

class ClassicLayout extends ConsumerStatefulWidget {
  final String noteId;
  final EditorMode editorMode;
  final QuillController? quillController;
  final FocusNode? editorFocusNode;
  final List<AttachmentModel> attachments;
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
    required this.editorMode,
    this.quillController,
    this.editorFocusNode,
    required this.attachments,
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
  ConsumerState<ClassicLayout> createState() => _ClassicLayoutState();
}

class _ClassicLayoutState extends ConsumerState<ClassicLayout> {
  bool _isPreviewMode = false;
  bool _isToolsTabSelected = false;
  PreviewStyle _previewStyle = PreviewStyle.plain;
  bool _isFullScreen = false;
  bool _isFocusMode = false;

  Color? _previewBgColor;
  String? _previewBgImagePath;
  double _previewOverlayOpacity = 0.0;
  Color _previewOverlayColor = Colors.black;
  bool _showBgPicker = false;

  String? _activeToolbarGroup;
  String? _activeColorMode;
  bool _showCustomColorPicker = false;
  double _customHue = 0.0;
  double _customSaturation = 1.0;
  double _customLightness = 0.5;
  Color _customSelectedColor = const Color(0xFFEF4444);
  final List<Color> _userSavedColors = [];

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
    return PopupMenuItem<PreviewStyle>(
      value: style,
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: _previewStyle == style ? const Color(0xFF8B5CF6) : null),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: _previewStyle == style ? FontWeight.bold : FontWeight.normal,
                  color: _previewStyle == style ? const Color(0xFF8B5CF6) : null)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildCustomAppBar(ThemeData theme, bool isDark) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double appBarContentHeight = _isToolsTabSelected ? 112.0 : 56.0;
    return PreferredSize(
      preferredSize: Size.fromHeight(appBarContentHeight + statusBarHeight),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF10121F) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF2E2845) : const Color(0xFFE8E4F5),
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
                    // Back arrow
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
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
                    // Title Text Field
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: TextField(
                          controller: widget.titleController,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Note Title...',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
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
                    // Primary minimalist action icons
                    IconButton(
                      icon: Icon(widget.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                      color: widget.isPinned ? theme.colorScheme.secondary : const Color(0xFF8B5CF6),
                      tooltip: widget.isPinned ? 'Unpin Note' : 'Pin Note',
                      onPressed: () {
                        widget.onPinChanged(!widget.isPinned);
                        widget.onSave();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.fullscreen_rounded, color: Color(0xFF8B5CF6)),
                      tooltip: 'Fullscreen Mode',
                      onPressed: () {
                        setState(() {
                          _isFullScreen = true;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        _isToolsTabSelected ? Icons.handyman_rounded : Icons.handyman_outlined,
                        color: const Color(0xFF8B5CF6),
                      ),
                      tooltip: 'Tools',
                      onPressed: () {
                        setState(() {
                          _isToolsTabSelected = !_isToolsTabSelected;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        _isPreviewMode ? Icons.edit_note_rounded : Icons.preview_rounded,
                        color: _isPreviewMode ? const Color(0xFF10B981) : const Color(0xFF8B5CF6),
                      ),
                      tooltip: _isPreviewMode ? 'Back to Editor' : 'Preview (Reader View)',
                      onPressed: () {
                        setState(() {
                          _isPreviewMode = !_isPreviewMode;
                        });
                      },
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF8B5CF6)),
                      onSelected: (val) {
                        if (val == 'save') widget.onSave();
                        if (val == 'share') {
                          // share note
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
              if (_isToolsTabSelected)
                Container(
                  height: 46.0,
                  margin: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 8.0),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFF8B5CF6).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFF8B5CF6).withOpacity(0.12),
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
                                color: const Color(0xFF8B5CF6),
                                tooltip: 'Record Voice Note',
                                onTap: _toggleVoiceRecording,
                              ),
                              _buildToolIcon(
                                icon: Icons.draw_rounded,
                                color: const Color(0xFF8B5CF6),
                                tooltip: 'Open Drawing Canvas',
                                onTap: _openDrawingCanvas,
                              ),
                              _buildToolIcon(
                                icon: Icons.calendar_month_rounded,
                                color: const Color(0xFF8B5CF6),
                                tooltip: 'Calendar & Reminders',
                                onTap: () => context.push('/calendar'),
                              ),
                              _buildToolIcon(
                                icon: Icons.center_focus_strong_rounded,
                                color: const Color(0xFF8B5CF6),
                                tooltip: 'Zen Writing Mode (Focus)',
                                onTap: () {
                                  setState(() {
                                    _isFocusMode = true;
                                  });
                                },
                              ),
                              _buildToolIcon(
                                icon: Icons.article_outlined,
                                color: const Color(0xFF8B5CF6),
                                tooltip: 'Export as Markdown (MD)',
                                onTap: () => _handleExportMarkdown(context),
                              ),
                              _buildToolIcon(
                                icon: Icons.picture_as_pdf_rounded,
                                color: const Color(0xFF8B5CF6),
                                tooltip: 'Export as PDF',
                                onTap: widget.onPrintPdf,
                              ),
                              PopupMenuButton<PreviewStyle>(
                                tooltip: 'Preview Style',
                                icon: const Icon(Icons.style_rounded, size: 20, color: Color(0xFF8B5CF6)),
                                offset: const Offset(0, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: isDark ? const Color(0xFF2E2845) : const Color(0xFFE8E4F5),
                                    width: 1,
                                  ),
                                ),
                                onSelected: (style) {
                                  setState(() {
                                    _previewStyle = style;
                                  });
                                },
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
                                color: widget.isFavorite ? const Color(0xFFF43F5E) : const Color(0xFF8B5CF6),
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
      ),
    );
  }

  Widget _buildBgColorPicker(ThemeData theme) {
    final colors = [
      Colors.transparent,
      const Color(0xFFFDF6E3),
      const Color(0xFFEAF4FC),
      const Color(0xFFEBF7EB),
      const Color(0xFFFDF0F0),
      const Color(0xFF1E1A30),
      const Color(0xFF0F172A),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Editor Theme Background', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: colors.map((c) {
            final isSelected = _previewBgColor == (c == Colors.transparent ? null : c);
            return GestureDetector(
              onTap: () {
                setState(() {
                  _previewBgColor = c == Colors.transparent ? null : c;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: c == Colors.transparent ? theme.scaffoldBackgroundColor : c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? theme.colorScheme.primary : Colors.grey.shade400,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: c == Colors.transparent
                    ? const Icon(Icons.block, size: 12, color: Colors.grey)
                    : (isSelected ? const Icon(Icons.check, size: 12, color: Colors.white) : null),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String get _currentFontFamily {
    return widget.noteType == NoteType.mixed
        ? 'Georgia'
        : (widget.noteType == NoteType.code ? 'Courier' : 'Inter');
  }

  double get _currentFontHeight {
    return widget.noteType == NoteType.mixed ? 1.75 : 1.5;
  }

  Widget _buildEditorBody(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final customTheme = theme.copyWith(
      textTheme: theme.textTheme.copyWith(
        bodyLarge: theme.textTheme.bodyLarge?.copyWith(
          fontFamily: _currentFontFamily,
          height: _currentFontHeight,
        ),
      ),
    );

    if (_isPreviewMode) {
      final bgColor = _previewBgColor ?? (isDark ? const Color(0xFF0F0B1E) : Colors.white);
      final markdown = QuillMarkdownConverter.deltaToMarkdown(ConvertBlocksToDelta.execute(widget.blocks));
      return Stack(
        children: [
          if (_previewBgImagePath != null)
            Positioned.fill(
              child: _previewBgImagePath!.startsWith('data:image')
                  ? Image.memory(
                      base64Decode(_previewBgImagePath!.split(',').last),
                      fit: BoxFit.cover,
                    )
                  : Image.file(io.File(_previewBgImagePath!), fit: BoxFit.cover),
            )
          else
            Positioned.fill(child: ColoredBox(color: bgColor)),
          if (_previewOverlayOpacity > 0.0)
            Positioned.fill(
              child: ColoredBox(color: _previewOverlayColor.withOpacity(_previewOverlayOpacity)),
            ),
          if (_previewStyle != PreviewStyle.plain)
            Positioned.fill(
              child: CustomPaint(painter: PreviewStylePainter(_previewStyle)),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: styleContentPadding(_previewStyle),
                  child: MarkdownWidget(
                    data: markdown,
                    attachments: widget.attachments,
                    fontFamily: _currentFontFamily,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Stack(
      children: [
        if (_previewStyle != PreviewStyle.plain)
          Positioned.fill(
            child: CustomPaint(painter: PreviewStylePainter(_previewStyle)),
          ),
        Theme(
          data: customTheme,
          child: Padding(
            padding: styleContentPadding(_previewStyle),
            child: EditorBodyWidget(
              editorMode: widget.editorMode,
              quillController: widget.quillController,
              editorFocusNode: widget.editorFocusNode,
              noteType: widget.noteType,
              attachments: widget.attachments,
              blocks: widget.blocks,
              focusNodes: widget.focusNodes,
              scrollController: widget.scrollController,
              isReorderable: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullScreenBody(ThemeData theme, bool isDark) {
    final bgColor = _previewBgColor ?? (isDark ? const Color(0xFF0D0B18) : Colors.white);
    final isMarkdownPreview = _isPreviewMode;

    final customTheme = theme.copyWith(
      textTheme: theme.textTheme.copyWith(
        bodyLarge: theme.textTheme.bodyLarge?.copyWith(
          fontFamily: _currentFontFamily,
          height: _currentFontHeight,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: _previewBgImagePath != null ? Colors.transparent : bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            if (_previewBgImagePath != null)
              Positioned.fill(
                child: _previewBgImagePath!.startsWith('data:image')
                    ? Image.memory(
                        base64Decode(_previewBgImagePath!.split(',').last),
                        fit: BoxFit.cover,
                      )
                    : Image.file(io.File(_previewBgImagePath!), fit: BoxFit.cover),
              ),
            if (_previewOverlayOpacity > 0.0)
              Positioned.fill(
                child: ColoredBox(
                    color: _previewOverlayColor.withOpacity(_previewOverlayOpacity)),
              ),
            if (_previewStyle != PreviewStyle.plain)
              Positioned.fill(
                child: CustomPaint(painter: PreviewStylePainter(_previewStyle)),
              ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 100, 8),
                  child: Text(
                    widget.titleController.text.isEmpty ? 'Untitled Note' : widget.titleController.text,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                      fontFamily: 'Outfit',
                    ),
                  ),
                ),
                Divider(height: 1,
                    color: isDark ? const Color(0xFF1E1A30) : const Color(0xFFE9E6F5)),
                Expanded(
                  child: isMarkdownPreview
                      ? Stack(
                          children: [
                            if (_previewStyle != PreviewStyle.plain)
                              Positioned.fill(
                                child: CustomPaint(painter: PreviewStylePainter(_previewStyle)),
                              ),
                            Padding(
                              padding: styleContentPadding(_previewStyle),
                              child: MarkdownWidget(
                                data: QuillMarkdownConverter.deltaToMarkdown(ConvertBlocksToDelta.execute(widget.blocks)),
                                attachments: widget.attachments,
                                fontFamily: _currentFontFamily,
                              ),
                            ),
                          ],
                        )
                      : Theme(
                          data: customTheme,
                          child: Padding(
                            padding: styleContentPadding(_previewStyle),
                            child: EditorBodyWidget(
                              editorMode: widget.editorMode,
                              quillController: widget.quillController,
                              editorFocusNode: widget.editorFocusNode,
                              noteType: widget.noteType,
                              attachments: widget.attachments,
                              blocks: widget.blocks,
                              focusNodes: widget.focusNodes,
                              scrollController: widget.scrollController,
                              isReorderable: false,
                            ),
                          ),
                        ),
                ),
              ],
            ),

            Positioned(
              top: 8, right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _isPreviewMode ? Icons.edit_note_rounded : Icons.preview_rounded,
                      size: 20,
                      color: _isPreviewMode ? const Color(0xFF10B981) : theme.colorScheme.primary,
                    ),
                    tooltip: _isPreviewMode ? 'Back to Editor' : 'Preview (Reader View)',
                    onPressed: () {
                      setState(() {
                        _isPreviewMode = !_isPreviewMode;
                      });
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.85),
                      padding: const EdgeInsets.all(6),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.palette_outlined, size: 20,
                        color: (_previewBgColor != null || _previewBgImagePath != null)
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.5)),
                    tooltip: 'Background',
                    onPressed: () => setState(() => _showBgPicker = !_showBgPicker),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.85),
                      padding: const EdgeInsets.all(6),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.fullscreen_exit_rounded, size: 22),
                    tooltip: 'Exit Fullscreen',
                    onPressed: () {
                      setState(() {
                        _isFullScreen = false;
                      });
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.85),
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.all(6),
                    ),
                  ),
                ],
              ),
            ),
            if (_showBgPicker)
              Positioned(
                bottom: 80, right: 16,
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildBgColorPicker(theme),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusModeBody(ThemeData theme, bool isDark) {
    final customTheme = theme.copyWith(
      textTheme: theme.textTheme.copyWith(
        bodyLarge: theme.textTheme.bodyLarge?.copyWith(
          fontFamily: _currentFontFamily,
          height: _currentFontHeight,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090B16) : const Color(0xFFF8F6FF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    onPressed: () {
                      widget.onSave();
                      setState(() {
                        _isFocusMode = false;
                      });
                    },
                    style: IconButton.styleFrom(
                      foregroundColor: isDark ? const Color(0xFF8B5CF6) : const Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.draw_rounded, color: Color(0xFF8B5CF6)),
                            tooltip: 'Open Drawing Canvas',
                            onPressed: _openDrawingCanvas,
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF8B5CF6)),
                            tooltip: 'Calendar & Reminders',
                            onPressed: () => context.push('/calendar'),
                          ),
                          TextButton.icon(
                            onPressed: () => setState(() => _isFocusMode = false),
                            icon: const Icon(Icons.grid_view_rounded, size: 16),
                            label: const Text('Standard Mode'),
                            style: TextButton.styleFrom(
                              foregroundColor: isDark ? const Color(0xFF6B5F8A) : const Color(0xFFAA9ECC),
                              textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            icon: Icon(_isFullScreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded),
                            tooltip: _isFullScreen ? 'Exit Fullscreen' : 'Fullscreen',
                            onPressed: () {
                              setState(() {
                                _isFullScreen = !_isFullScreen;
                              });
                            },
                            style: IconButton.styleFrom(
                              foregroundColor: isDark ? const Color(0xFF8B5CF6) : const Color(0xFF7C3AED),
                            ),
                          ),
                          IconButton(
                            icon: Icon(widget.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                            color: widget.isPinned ? theme.colorScheme.secondary : null,
                            tooltip: widget.isPinned ? 'Unpin Note' : 'Pin Note',
                            onPressed: () => widget.onPinChanged(!widget.isPinned),
                          ),
                          IconButton(
                            icon: Icon(widget.isFavorite ? Icons.favorite : Icons.favorite_border),
                            color: widget.isFavorite ? const Color(0xFFF43F5E) : null,
                            tooltip: widget.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                            onPressed: () => widget.onFavoriteChanged(!widget.isFavorite),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
              child: TextField(
                controller: widget.titleController,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
                decoration: InputDecoration(
                  hintText: 'Untitled Note',
                  hintStyle: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF3D3557) : const Color(0xFFD1CBE8),
                    letterSpacing: -0.5,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Divider(
                color: isDark ? const Color(0xFF252234) : const Color(0xFFE9E6F5),
                height: 16,
              ),
            ),
            Expanded(
              child: Theme(
                data: customTheme,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 4, 28, 0),
                  child: EditorBodyWidget(
                    editorMode: widget.editorMode,
                    quillController: widget.quillController,
                    editorFocusNode: widget.editorFocusNode,
                    noteType: widget.noteType,
                    attachments: widget.attachments,
                    blocks: widget.blocks,
                    focusNodes: widget.focusNodes,
                    scrollController: widget.scrollController,
                    isReorderable: false,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final folders = ref.watch(foldersProvider);

    if (_isFullScreen) {
      return _buildFullScreenBody(theme, isDark);
    }

    if (_isFocusMode) {
      return _buildFocusModeBody(theme, isDark);
    }

    final colors = [
      '#FFFFFF',
      '#FEE2E2',
      '#FEF3C7',
      '#ECFDF5',
      '#E0F2FE',
      '#F3E8FF',
      '#FDF4FF',
    ];

    // Resolve base background color matching accent color settings
    final bgColor = widget.colorHex == '#FFFFFF'
        ? (isDark ? const Color(0xFF0F0B1E) : Colors.white)
        : Color(int.parse('FF${widget.colorHex.replaceAll('#', '')}', radix: 16)).withOpacity(isDark ? 0.15 : 0.8);

    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final showFolderOptions = !isKeyboardOpen;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildCustomAppBar(theme, isDark),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                if (showFolderOptions)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                value: widget.selectedFolderId,
                                hint: const Row(
                                  children: [
                                    Icon(Icons.folder_outlined, size: 18),
                                    SizedBox(width: 6),
                                    Text('Select Folder', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Row(
                                      children: [
                                        Icon(Icons.folder_off_outlined, size: 16),
                                        SizedBox(width: 6),
                                        Text('No Folder', style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  ...folders.map((f) => DropdownMenuItem<String?>(
                                        value: f.id,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(color: f.color, shape: BoxShape.circle),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(f.name, style: const TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                      )),
                                ],
                                onChanged: widget.onFolderChanged,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<NoteType>(
                                value: widget.noteType,
                                items: NoteType.values
                                    .map((t) => DropdownMenuItem<NoteType>(
                                          value: t,
                                          child: Row(
                                            children: [
                                              Icon(t.icon, size: 16, color: theme.colorScheme.primary),
                                              const SizedBox(width: 6),
                                              Text(t.displayName, style: const TextStyle(fontSize: 12)),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    widget.onNoteTypeChanged(val);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: colors.map((colHex) {
                                final isSelected = widget.colorHex == colHex;
                                final color = colHex == '#FFFFFF'
                                    ? Colors.grey.shade300
                                    : Color(int.parse('FF${colHex.replaceAll('#', '')}', radix: 16));
                                return GestureDetector(
                                  onTap: () => widget.onColorChanged(colHex),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: colHex == '#FFFFFF' ? Colors.white : color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? theme.colorScheme.onSurface : Colors.grey.shade400,
                                        width: isSelected ? 1.5 : 0.5,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (showFolderOptions)
                  const Divider(height: 1),

                // Blocks Editor / Preview view
                Expanded(
                  child: _buildEditorBody(context),
                ),

                // Tags bar at the bottom
                if (!isKeyboardOpen) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), // extra padding for bottom bar
                    child: Row(
                      children: [
                        Icon(Icons.local_offer_outlined, size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: widget.tagController,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Enter tags (comma separated)...',
                              hintStyle: TextStyle(color: theme.hintColor.withOpacity(0.3)),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else
                  const SizedBox(height: 80),
              ],
            ),

            // Floating format bar at the bottom
            if (!_isPreviewMode)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
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
          ],
        ),
      ),
    );
  }
}
