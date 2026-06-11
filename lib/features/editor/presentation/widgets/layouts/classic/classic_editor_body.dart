import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../settings/presentation/controllers/settings_controller.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../models/models.dart';
import '../../../../domain/entities/block_entity.dart';
import '../../../../domain/entities/block_type.dart';
import '../../editor_body_widget.dart';
import '../../preview_style_painter.dart';

class ClassicEditorBody extends ConsumerStatefulWidget {
  final String noteId;
  final EditorMode editorMode;
  final QuillController? quillController;
  final FocusNode? editorFocusNode;
  final List<AttachmentModel> attachments;
  final NoteType noteType;
  final List<BlockEntity> blocks;
  final Map<String, FocusNode> focusNodes;
  final ScrollController scrollController;
  final bool isPreviewMode;
  final ValueChanged<bool> onPreviewModeChanged;
  final PreviewStyle previewStyle;
  final TextEditingController titleController;
  
  // Background selection settings
  final Color? previewBgColor;
  final ValueChanged<Color?> onPreviewBgColorChanged;
  final String? previewBgImagePath;
  final ValueChanged<String?> onPreviewBgImagePathChanged;
  final double previewOverlayOpacity;
  final Color previewOverlayColor;
  
  // Fullscreen / Focus Mode
  final bool isFullScreen;
  final ValueChanged<bool> onFullScreenChanged;
  final bool isFocusMode;
  final ValueChanged<bool> onFocusModeChanged;

  final bool isPinned;
  final ValueChanged<bool> onPinChanged;
  final bool isFavorite;
  final ValueChanged<bool> onFavoriteChanged;

  final VoidCallback onSave;
  final Function(BlockType, {String content, Map<String, dynamic> attributes}) onInsertBlock;
  final ValueChanged<NoteType> onNoteTypeChanged;

  const ClassicEditorBody({
    super.key,
    required this.noteId,
    required this.editorMode,
    this.quillController,
    this.editorFocusNode,
    required this.attachments,
    required this.noteType,
    required this.blocks,
    required this.focusNodes,
    required this.scrollController,
    required this.isPreviewMode,
    required this.onPreviewModeChanged,
    required this.previewStyle,
    required this.titleController,
    required this.previewBgColor,
    required this.onPreviewBgColorChanged,
    required this.previewBgImagePath,
    required this.onPreviewBgImagePathChanged,
    required this.previewOverlayOpacity,
    required this.previewOverlayColor,
    required this.isFullScreen,
    required this.onFullScreenChanged,
    required this.isFocusMode,
    required this.onFocusModeChanged,
    required this.isPinned,
    required this.onPinChanged,
    required this.isFavorite,
    required this.onFavoriteChanged,
    required this.onSave,
    required this.onInsertBlock,
    required this.onNoteTypeChanged,
  });

  @override
  ConsumerState<ClassicEditorBody> createState() => _ClassicEditorBodyState();
}

class _ClassicEditorBodyState extends ConsumerState<ClassicEditorBody> {
  bool _showBgPicker = false;

  String get _currentFontFamily {
    return widget.noteType == NoteType.mixed
        ? 'Georgia'
        : (widget.noteType == NoteType.code ? 'Courier' : 'Inter');
  }

  ThemeData _getCustomTheme(ThemeData theme, AppSettingsModel settings) {
    final family = settings.editorFontFamily;
    final size = settings.editorFontSize;
    final height = settings.editorLineHeight;

    final resolvedFamily = family == 'System' ? _currentFontFamily : family;
    TextStyle baseBodyStyle = (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
      fontSize: size,
      height: height,
    );

    TextStyle resolvedBodyStyle;
    switch (resolvedFamily) {
      case 'Inter':
        resolvedBodyStyle = GoogleFonts.inter(textStyle: baseBodyStyle);
        break;
      case 'Outfit':
        resolvedBodyStyle = GoogleFonts.outfit(textStyle: baseBodyStyle);
        break;
      case 'Roboto Mono':
        resolvedBodyStyle = GoogleFonts.robotoMono(textStyle: baseBodyStyle);
        break;
      case 'Lora':
        resolvedBodyStyle = GoogleFonts.lora(textStyle: baseBodyStyle);
        break;
      case 'Lexend':
        resolvedBodyStyle = GoogleFonts.lexend(textStyle: baseBodyStyle);
        break;
      case 'Georgia':
        resolvedBodyStyle = baseBodyStyle.copyWith(fontFamily: 'Georgia');
        break;
      case 'Courier':
      case 'Courier New':
        resolvedBodyStyle = baseBodyStyle.copyWith(fontFamily: 'Courier');
        break;
      default:
        resolvedBodyStyle = baseBodyStyle.copyWith(fontFamily: resolvedFamily);
    }

    return theme.copyWith(
      textTheme: theme.textTheme.copyWith(
        bodyLarge: resolvedBodyStyle,
      ),
    );
  }

  EdgeInsets styleContentPadding(PreviewStyle style) {
    switch (style) {
      case PreviewStyle.notebook:
      case PreviewStyle.spiral:
        return const EdgeInsets.fromLTRB(40, 24, 20, 24);
      case PreviewStyle.plain:
      case PreviewStyle.grid:
      case PreviewStyle.leaf:
      case PreviewStyle.dark:
        return const EdgeInsets.all(20);
    }
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
            final isSelected = widget.previewBgColor == (c == Colors.transparent ? null : c);
            return GestureDetector(
              onTap: () {
                widget.onPreviewBgColorChanged(c == Colors.transparent ? null : c);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);

    if (widget.isFullScreen) {
      return _buildFullScreenBody(theme, isDark);
    }

    if (widget.isFocusMode) {
      return _buildFocusModeBody(theme, isDark);
    }

    final customTheme = _getCustomTheme(theme, settings);
    final bgColor = widget.previewBgColor ?? (isDark ? const Color(0xFF0F0B1E) : Colors.white);

    return Stack(
      children: [
        if (widget.previewBgImagePath != null)
          Positioned.fill(
            child: widget.previewBgImagePath!.startsWith('data:image')
                ? Image.memory(
                    base64Decode(widget.previewBgImagePath!.split(',').last),
                    fit: BoxFit.cover,
                  )
                : (kIsWeb
                    ? Image.network(widget.previewBgImagePath!, fit: BoxFit.cover)
                    : Image.file(io.File(widget.previewBgImagePath!), fit: BoxFit.cover)),
          )
        else
          Positioned.fill(child: ColoredBox(color: bgColor)),
        if (widget.previewOverlayOpacity > 0.0)
          Positioned.fill(
            child: ColoredBox(
                color: widget.previewOverlayColor.withValues(alpha: widget.previewOverlayOpacity)),
          ),
        if (widget.previewStyle != PreviewStyle.plain)
          Positioned.fill(
            child: CustomPaint(painter: PreviewStylePainter(widget.previewStyle)),
          ),
        Theme(
          data: customTheme,
          child: Padding(
            padding: styleContentPadding(widget.previewStyle),
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
              readOnly: widget.isPreviewMode,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullScreenBody(ThemeData theme, bool isDark) {
    final bgColor = widget.previewBgColor ?? (isDark ? const Color(0xFF0D0B18) : Colors.white);
    final settings = ref.watch(settingsProvider);

    final customTheme = _getCustomTheme(theme, settings);

    return Scaffold(
      backgroundColor: widget.previewBgImagePath != null ? Colors.transparent : bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            if (widget.previewBgImagePath != null)
              Positioned.fill(
                child: widget.previewBgImagePath!.startsWith('data:image')
                    ? Image.memory(
                        base64Decode(widget.previewBgImagePath!.split(',').last),
                        fit: BoxFit.cover,
                      )
                    : (kIsWeb
                        ? Image.network(widget.previewBgImagePath!, fit: BoxFit.cover)
                        : Image.file(io.File(widget.previewBgImagePath!), fit: BoxFit.cover)),
              ),
            if (widget.previewOverlayOpacity > 0.0)
              Positioned.fill(
                child: ColoredBox(
                    color: widget.previewOverlayColor.withValues(alpha: widget.previewOverlayOpacity)),
              ),
            if (widget.previewStyle != PreviewStyle.plain)
              Positioned.fill(
                child: CustomPaint(painter: PreviewStylePainter(widget.previewStyle)),
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
                  child: Theme(
                    data: customTheme,
                    child: Padding(
                      padding: styleContentPadding(widget.previewStyle),
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
                        readOnly: widget.isPreviewMode,
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
                      widget.isPreviewMode ? Icons.edit_note_rounded : Icons.preview_rounded,
                      size: 20,
                      color: widget.isPreviewMode ? const Color(0xFF10B981) : theme.colorScheme.primary,
                    ),
                    tooltip: widget.isPreviewMode ? 'Back to Editor' : 'Preview (Reader View)',
                    onPressed: () {
                      widget.onPreviewModeChanged(!widget.isPreviewMode);
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
                      padding: const EdgeInsets.all(6),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.palette_outlined, size: 20,
                        color: (widget.previewBgColor != null || widget.previewBgImagePath != null)
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    tooltip: 'Background',
                    onPressed: () => setState(() => _showBgPicker = !_showBgPicker),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
                      padding: const EdgeInsets.all(6),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.fullscreen_exit_rounded, size: 22),
                    tooltip: 'Exit Fullscreen',
                    onPressed: () {
                      widget.onFullScreenChanged(false);
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
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
    final settings = ref.watch(settingsProvider);
    final customTheme = _getCustomTheme(theme, settings);

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
                      widget.onFocusModeChanged(false);
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
                            onPressed: () => widget.onInsertBlock(BlockType.drawing),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF8B5CF6)),
                            tooltip: 'Calendar & Reminders',
                            onPressed: () => context.push('/calendar'),
                          ),
                          TextButton.icon(
                            onPressed: () => widget.onFocusModeChanged(false),
                            icon: const Icon(Icons.grid_view_rounded, size: 16),
                            label: const Text('Standard Mode'),
                            style: TextButton.styleFrom(
                              foregroundColor: isDark ? const Color(0xFF6B5F8A) : const Color(0xFFAA9ECC),
                              textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            icon: Icon(widget.isFullScreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded),
                            tooltip: widget.isFullScreen ? 'Exit Fullscreen' : 'Fullscreen',
                            onPressed: () {
                              widget.onFullScreenChanged(!widget.isFullScreen);
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
                    readOnly: widget.isPreviewMode,
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
