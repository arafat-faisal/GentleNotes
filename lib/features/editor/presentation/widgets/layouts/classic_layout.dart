import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../../../core/models/models.dart';
import '../../../domain/entities/block_entity.dart';
import '../../../domain/entities/block_type.dart';
import '../panels/floating_toolbar.dart';
import 'classic/classic_bottom_bar.dart';
import 'classic/classic_editor_body.dart';
import 'classic/classic_header.dart';
import 'classic/classic_metadata_bar.dart';
import 'classic/classic_side_panel.dart';
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
  final double _previewOverlayOpacity = 0.0;
  final Color _previewOverlayColor = Colors.black;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isFullScreen || _isFocusMode) {
      return ClassicEditorBody(
        noteId: widget.noteId,
        editorMode: widget.editorMode,
        quillController: widget.quillController,
        editorFocusNode: widget.editorFocusNode,
        attachments: widget.attachments,
        noteType: widget.noteType,
        blocks: widget.blocks,
        focusNodes: widget.focusNodes,
        scrollController: widget.scrollController,
        isPreviewMode: _isPreviewMode,
        onPreviewModeChanged: (val) => setState(() => _isPreviewMode = val),
        previewStyle: _previewStyle,
        titleController: widget.titleController,
        previewBgColor: _previewBgColor,
        onPreviewBgColorChanged: (val) => setState(() => _previewBgColor = val),
        previewBgImagePath: _previewBgImagePath,
        onPreviewBgImagePathChanged: (val) => setState(() => _previewBgImagePath = val),
        previewOverlayOpacity: _previewOverlayOpacity,
        previewOverlayColor: _previewOverlayColor,
        isFullScreen: _isFullScreen,
        onFullScreenChanged: (val) => setState(() => _isFullScreen = val),
        isFocusMode: _isFocusMode,
        onFocusModeChanged: (val) => setState(() => _isFocusMode = val),
        isPinned: widget.isPinned,
        onPinChanged: widget.onPinChanged,
        isFavorite: widget.isFavorite,
        onFavoriteChanged: widget.onFavoriteChanged,
        onSave: widget.onSave,
        onInsertBlock: widget.onInsertBlock,
        onNoteTypeChanged: widget.onNoteTypeChanged,
      );
    }

    final bgColor = widget.colorHex == '#FFFFFF'
        ? (isDark ? const Color(0xFF0F0B1E) : Colors.white)
        : Color(int.parse('FF${widget.colorHex.replaceAll('#', '')}', radix: 16)).withValues(alpha: isDark ? 0.15 : 0.8);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: ClassicHeader(
        noteId: widget.noteId,
        editorMode: widget.editorMode,
        quillController: widget.quillController,
        blocks: widget.blocks,
        titleController: widget.titleController,
        selectedFolderId: widget.selectedFolderId,
        isPinned: widget.isPinned,
        onPinChanged: widget.onPinChanged,
        isFavorite: widget.isFavorite,
        onFavoriteChanged: widget.onFavoriteChanged,
        isToolsTabSelected: _isToolsTabSelected,
        onToolsTabSelectedChanged: (val) => setState(() => _isToolsTabSelected = val),
        isPreviewMode: _isPreviewMode,
        onPreviewModeChanged: (val) => setState(() => _isPreviewMode = val),
        previewStyle: _previewStyle,
        onPreviewStyleChanged: (val) => setState(() => _previewStyle = val),
        onSave: widget.onSave,
        onPrintPdf: widget.onPrintPdf,
        onEnterFullScreen: () => setState(() => _isFullScreen = true),
        onEnterFocusMode: () => setState(() => _isFocusMode = true),
        onInsertBlock: widget.onInsertBlock,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                ClassicMetadataBar(
                  selectedFolderId: widget.selectedFolderId,
                  onFolderChanged: widget.onFolderChanged,
                  noteType: widget.noteType,
                  onNoteTypeChanged: widget.onNoteTypeChanged,
                  colorHex: widget.colorHex,
                  onColorChanged: widget.onColorChanged,
                  readOnly: _isPreviewMode,
                ),
                const Divider(height: 1),
                Expanded(
                  child: ClassicEditorBody(
                    noteId: widget.noteId,
                    editorMode: widget.editorMode,
                    quillController: widget.quillController,
                    editorFocusNode: widget.editorFocusNode,
                    attachments: widget.attachments,
                    noteType: widget.noteType,
                    blocks: widget.blocks,
                    focusNodes: widget.focusNodes,
                    scrollController: widget.scrollController,
                    isPreviewMode: _isPreviewMode,
                    onPreviewModeChanged: (val) => setState(() => _isPreviewMode = val),
                    previewStyle: _previewStyle,
                    titleController: widget.titleController,
                    previewBgColor: _previewBgColor,
                    onPreviewBgColorChanged: (val) => setState(() => _previewBgColor = val),
                    previewBgImagePath: _previewBgImagePath,
                    onPreviewBgImagePathChanged: (val) => setState(() => _previewBgImagePath = val),
                    previewOverlayOpacity: _previewOverlayOpacity,
                    previewOverlayColor: _previewOverlayColor,
                    isFullScreen: _isFullScreen,
                    onFullScreenChanged: (val) => setState(() => _isFullScreen = val),
                    isFocusMode: _isFocusMode,
                    onFocusModeChanged: (val) => setState(() => _isFocusMode = val),
                    isPinned: widget.isPinned,
                    onPinChanged: widget.onPinChanged,
                    isFavorite: widget.isFavorite,
                    onFavoriteChanged: widget.onFavoriteChanged,
                    onSave: widget.onSave,
                    onInsertBlock: widget.onInsertBlock,
                    onNoteTypeChanged: widget.onNoteTypeChanged,
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
            if (!_isPreviewMode)
              ClassicBottomBar(
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
            const ClassicSidePanel(),
          ],
        ),
      ),
    );
  }
}
