import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../../../models/models.dart';
import '../../../domain/entities/block_type.dart';
import '../../../domain/entities/block_entity.dart';
import '../layouts/classic_layout.dart';
import '../layouts/minimal_layout.dart';
import '../layouts/notebook_layout.dart';
import '../layouts/zen_layout.dart';
import '../layouts/aesthetic_layouts.dart';

class EditorBody extends StatelessWidget {
  final EditorLayoutVariant layoutVariant;
  final EditorMode editorMode;
  final String noteId;
  final QuillController quillController;
  final FocusNode editorFocusNode;
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
  final void Function(BlockType, {String content, Map<String, dynamic> attributes}) onInsertBlock;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool canUndo;
  final bool canRedo;

  const EditorBody({
    super.key,
    required this.layoutVariant,
    required this.editorMode,
    required this.noteId,
    required this.quillController,
    required this.editorFocusNode,
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
  Widget build(BuildContext context) {
    if (layoutVariant.isAesthetic || layoutVariant == EditorLayoutVariant.cards) {
      return AestheticLayout(
        variant: layoutVariant,
        noteId: noteId,
        editorMode: editorMode,
        quillController: quillController,
        editorFocusNode: editorFocusNode,
        attachments: attachments,
        titleController: titleController,
        tagController: tagController,
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
        blocks: blocks,
        focusNodes: focusNodes,
        scrollController: scrollController,
        onSave: onSave,
        onPrintPdf: onPrintPdf,
        isSpeechListening: isSpeechListening,
        onSpeechToggle: onSpeechToggle,
        onInsertBlock: onInsertBlock,
        onUndo: onUndo,
        onRedo: onRedo,
        canUndo: canUndo,
        canRedo: canRedo,
      );
    }

    switch (layoutVariant) {
      case EditorLayoutVariant.minimal:
        return MinimalLayout(
          noteId: noteId,
          editorMode: editorMode,
          quillController: quillController,
          editorFocusNode: editorFocusNode,
          titleController: titleController,
          tagController: tagController,
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
          blocks: blocks,
          focusNodes: focusNodes,
          scrollController: scrollController,
          onSave: onSave,
          onPrintPdf: onPrintPdf,
          isSpeechListening: isSpeechListening,
          onSpeechToggle: onSpeechToggle,
          onInsertBlock: onInsertBlock,
          onUndo: onUndo,
          onRedo: onRedo,
          canUndo: canUndo,
          canRedo: canRedo,
        );
      case EditorLayoutVariant.notebook:
        return NotebookLayout(
          noteId: noteId,
          editorMode: editorMode,
          quillController: quillController,
          editorFocusNode: editorFocusNode,
          titleController: titleController,
          tagController: tagController,
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
          blocks: blocks,
          focusNodes: focusNodes,
          scrollController: scrollController,
          onSave: onSave,
          onPrintPdf: onPrintPdf,
          isSpeechListening: isSpeechListening,
          onSpeechToggle: onSpeechToggle,
          onInsertBlock: onInsertBlock,
          onUndo: onUndo,
          onRedo: onRedo,
          canUndo: canUndo,
          canRedo: canRedo,
        );
      case EditorLayoutVariant.zen:
        return ZenLayout(
          noteId: noteId,
          editorMode: editorMode,
          quillController: quillController,
          editorFocusNode: editorFocusNode,
          titleController: titleController,
          tagController: tagController,
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
          blocks: blocks,
          focusNodes: focusNodes,
          scrollController: scrollController,
          onSave: onSave,
          onPrintPdf: onPrintPdf,
          isSpeechListening: isSpeechListening,
          onSpeechToggle: onSpeechToggle,
          onInsertBlock: onInsertBlock,
          onUndo: onUndo,
          onRedo: onRedo,
          canUndo: canUndo,
          canRedo: canRedo,
        );
      case EditorLayoutVariant.classic:
      default:
        return ClassicLayout(
          noteId: noteId,
          editorMode: editorMode,
          quillController: quillController,
          editorFocusNode: editorFocusNode,
          attachments: attachments,
          titleController: titleController,
          tagController: tagController,
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
          blocks: blocks,
          focusNodes: focusNodes,
          scrollController: scrollController,
          onSave: onSave,
          onPrintPdf: onPrintPdf,
          isSpeechListening: isSpeechListening,
          onSpeechToggle: onSpeechToggle,
          onInsertBlock: onInsertBlock,
          onUndo: onUndo,
          onRedo: onRedo,
          canUndo: canUndo,
          canRedo: canRedo,
        );
    }
  }
}
