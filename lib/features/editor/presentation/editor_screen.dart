import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as speech_to_text;
import 'package:uuid/uuid.dart';

import '../../../../models/models.dart';
import '../../../../features/notes/presentation/controllers/notes_controller.dart';
import '../../../../features/templates/presentation/controllers/templates_controller.dart';
import '../../../../features/settings/presentation/controllers/settings_controller.dart';
import '../domain/entities/block_entity.dart';
import '../domain/entities/block_type.dart';
import '../domain/usecases/convert_blocks_to_delta.dart';
import '../domain/usecases/convert_delta_to_blocks.dart';
import 'controllers/editor_block_controller.dart';

import 'widgets/layouts/classic_layout.dart';
import 'widgets/layouts/minimal_layout.dart';
import 'widgets/layouts/notebook_layout.dart';
import 'widgets/layouts/zen_layout.dart';
import 'widgets/layouts/aesthetic_layouts.dart';
import 'widgets/panels/pdf_export_dialog.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final String? noteId;
  final String? initialFolderId;
  final String? initialTemplateId;

  const EditorScreen({
    super.key,
    this.noteId,
    this.initialFolderId,
    this.initialTemplateId,
  });

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late String _noteId;
  bool _isEditMode = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, FocusNode> _focusNodes = {};

  NoteType _noteType = NoteType.mixed;
  String? _selectedFolderId;
  String? _templateId;
  bool _isPinned = false;
  bool _isFavorite = false;
  String _colorHex = '#FFFFFF';
  DateTime? _createdAt;
  List<AttachmentModel> _attachments = [];

  Timer? _autoSaveTimer;
  bool _isDirty = false;

  // Speech to Text
  final speech_to_text.SpeechToText _speechToText = speech_to_text.SpeechToText();
  bool _speechInitialized = false;
  bool _isSpeechListening = false;

  @override
  void initState() {
    super.initState();
    _noteId = widget.noteId ?? const Uuid().v4();
    _isEditMode = widget.noteId != null;
    _selectedFolderId = widget.initialFolderId;
    _templateId = widget.initialTemplateId;

    _titleController.addListener(_markDirty);
    _tagController.addListener(_markDirty);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNoteOrTemplate();
      _setupAutosave();
    });
  }

  void _markDirty() => _isDirty = true;

  void _setupAutosave() {
    final settings = ref.read(settingsProvider);
    if (settings.autoSaveEnabled) {
      _autoSaveTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        final blocksDirty = ref.read(editorBlockControllerProvider).isDirty;
        if (_isDirty || blocksDirty) {
          _saveNote(isAutoSave: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _tagController.dispose();
    _scrollController.dispose();
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _loadNoteOrTemplate() {
    String noteContent = '';

    if (_isEditMode) {
      final notes = ref.read(notesProvider);
      final note = notes.cast<NoteModel?>().firstWhere(
            (n) => n?.id == _noteId,
            orElse: () => null,
          );

      if (note != null) {
        _titleController.text = note.title;
        _tagController.text = note.tags.join(', ');
        _noteType = note.noteType;
        _selectedFolderId = note.folderId;
        _templateId = note.templateId;
        _isPinned = note.isPinned;
        _isFavorite = note.isFavorite;
        _colorHex = note.colorHex;
        _createdAt = note.createdAt;
        _attachments = note.attachments;
        noteContent = note.content;
      }
    } else if (_templateId != null) {
      final templates = ref.read(templatesProvider);
      final template = templates.cast<NoteTemplateModel?>().firstWhere(
            (t) => t?.id == _templateId,
            orElse: () => null,
          );

      if (template != null) {
        _titleController.text = template.defaultTitle;
        _tagController.text = template.defaultTags.join(', ');
        noteContent = template.defaultContent;
        if (template.id == 't-code') {
          _noteType = NoteType.code;
        } else if (template.id == 't-journal') {
          _noteType = NoteType.markdown;
        }
      }
    }

    final blocks = ConvertDeltaToBlocks.execute(noteContent);
    ref.read(editorBlockControllerProvider.notifier).initializeWithBlocks(blocks);
    setState(() {});
  }

  Future<void> _saveNote({bool isAutoSave = false}) async {
    final blocksState = ref.read(editorBlockControllerProvider);
    if (!_isDirty && !blocksState.isDirty && isAutoSave) return;

    final title = _titleController.text.trim();
    final content = ConvertBlocksToDelta.execute(blocksState.blocks);
    final tags = _tagController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final now = DateTime.now();
    final note = NoteModel(
      id: _noteId,
      folderId: _selectedFolderId,
      title: title.isEmpty ? 'Untitled Note' : title,
      content: content,
      noteType: _noteType,
      tags: tags,
      attachments: _attachments,
      templateId: _templateId,
      isPinned: _isPinned,
      isFavorite: _isFavorite,
      colorHex: _colorHex,
      createdAt: _createdAt ?? now,
      updatedAt: now,
    );

    try {
      if (_isEditMode || ref.read(notesProvider).any((n) => n.id == _noteId)) {
        await ref.read(notesProvider.notifier).updateNote(note);
      } else {
        await ref.read(notesProvider.notifier).addNote(note);
      }
      ref.read(editorBlockControllerProvider.notifier).markClean();
      _isDirty = false;
    } catch (e) {
      debugPrint('Error saving note: $e');
    }

    if (!isAutoSave && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note saved successfully'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _toggleSpeechToText() async {
    if (_isSpeechListening) {
      await _speechToText.stop();
      setState(() => _isSpeechListening = false);
    } else {
      if (!_speechInitialized) {
        _speechInitialized = await _speechToText.initialize(
          onError: (e) {
            setState(() => _isSpeechListening = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Speech error: ${e.errorMsg}'), backgroundColor: Colors.red),
            );
          },
          onStatus: (status) {
            if (status == 'done' || status == 'notListening') {
              setState(() => _isSpeechListening = false);
            }
          },
        );
      }

      if (_speechInitialized) {
        setState(() => _isSpeechListening = true);
        await _speechToText.listen(
          onResult: (result) {
            if (result.finalResult) {
              final text = result.recognizedWords;
              if (text.isNotEmpty) {
                // Add speech dictation as a new text block
                final state = ref.read(editorBlockControllerProvider);
                final index = state.blocks.length - 1;
                ref.read(editorBlockControllerProvider.notifier).insertBlock(
                      index,
                      BlockType.text,
                      content: text,
                    );
                _markDirty();
              }
            }
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech dictation unavailable'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onInsertBlock(BlockType type, {String content = '', Map<String, dynamic> attributes = const {}}) {
    final state = ref.read(editorBlockControllerProvider);
    final index = state.selectedIndex >= 0 ? state.selectedIndex : state.blocks.length - 1;
    ref.read(editorBlockControllerProvider.notifier).insertBlock(index, type, content: content);
    _markDirty();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final blocksState = ref.watch(editorBlockControllerProvider);

    final layoutVariant = settings.editorLayout;

    // Common callbacks and parameters
    final onFolderChanged = (String? val) => setState(() {
          _selectedFolderId = val;
          _markDirty();
        });
    final onNoteTypeChanged = (NoteType val) => setState(() {
          _noteType = val;
          _markDirty();
        });
    final onPinChanged = (bool val) => setState(() {
          _isPinned = val;
          _markDirty();
        });
    final onFavoriteChanged = (bool val) => setState(() {
          _isFavorite = val;
          _markDirty();
        });
    final onColorChanged = (String val) => setState(() {
          _colorHex = val;
          _markDirty();
        });
    final onPrintPdf = () {
      final note = NoteModel(
        id: _noteId,
        folderId: _selectedFolderId,
        title: _titleController.text.trim().isEmpty ? 'Untitled Note' : _titleController.text.trim(),
        content: ConvertBlocksToDelta.execute(blocksState.blocks),
        noteType: _noteType,
        tags: _tagController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        attachments: _attachments,
        templateId: _templateId,
        isPinned: _isPinned,
        isFavorite: _isFavorite,
        colorHex: _colorHex,
        createdAt: _createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      PdfExportDialog.show(context, note);
    };

    if (layoutVariant.isAesthetic || layoutVariant == EditorLayoutVariant.cards) {
      return AestheticLayout(
        variant: layoutVariant,
        noteId: _noteId,
        titleController: _titleController,
        tagController: _tagController,
        selectedFolderId: _selectedFolderId,
        onFolderChanged: onFolderChanged,
        noteType: _noteType,
        onNoteTypeChanged: onNoteTypeChanged,
        isPinned: _isPinned,
        onPinChanged: onPinChanged,
        isFavorite: _isFavorite,
        onFavoriteChanged: onFavoriteChanged,
        colorHex: _colorHex,
        onColorChanged: onColorChanged,
        blocks: blocksState.blocks,
        focusNodes: _focusNodes,
        scrollController: _scrollController,
        onSave: _saveNote,
        onPrintPdf: onPrintPdf,
        isSpeechListening: _isSpeechListening,
        onSpeechToggle: _toggleSpeechToText,
        onInsertBlock: _onInsertBlock,
        onUndo: () => ref.read(editorBlockControllerProvider.notifier).undo(),
        onRedo: () => ref.read(editorBlockControllerProvider.notifier).redo(),
        canUndo: blocksState.undoStack.isNotEmpty,
        canRedo: blocksState.redoStack.isNotEmpty,
      );
    }

    switch (layoutVariant) {
      case EditorLayoutVariant.minimal:
        return MinimalLayout(
          noteId: _noteId,
          titleController: _titleController,
          tagController: _tagController,
          selectedFolderId: _selectedFolderId,
          onFolderChanged: onFolderChanged,
          noteType: _noteType,
          onNoteTypeChanged: onNoteTypeChanged,
          isPinned: _isPinned,
          onPinChanged: onPinChanged,
          isFavorite: _isFavorite,
          onFavoriteChanged: onFavoriteChanged,
          colorHex: _colorHex,
          onColorChanged: onColorChanged,
          blocks: blocksState.blocks,
          focusNodes: _focusNodes,
          scrollController: _scrollController,
          onSave: _saveNote,
          onPrintPdf: onPrintPdf,
          isSpeechListening: _isSpeechListening,
          onSpeechToggle: _toggleSpeechToText,
          onInsertBlock: _onInsertBlock,
          onUndo: () => ref.read(editorBlockControllerProvider.notifier).undo(),
          onRedo: () => ref.read(editorBlockControllerProvider.notifier).redo(),
          canUndo: blocksState.undoStack.isNotEmpty,
          canRedo: blocksState.redoStack.isNotEmpty,
        );
      case EditorLayoutVariant.notebook:
        return NotebookLayout(
          noteId: _noteId,
          titleController: _titleController,
          tagController: _tagController,
          selectedFolderId: _selectedFolderId,
          onFolderChanged: onFolderChanged,
          noteType: _noteType,
          onNoteTypeChanged: onNoteTypeChanged,
          isPinned: _isPinned,
          onPinChanged: onPinChanged,
          isFavorite: _isFavorite,
          onFavoriteChanged: onFavoriteChanged,
          colorHex: _colorHex,
          onColorChanged: onColorChanged,
          blocks: blocksState.blocks,
          focusNodes: _focusNodes,
          scrollController: _scrollController,
          onSave: _saveNote,
          onPrintPdf: onPrintPdf,
          isSpeechListening: _isSpeechListening,
          onSpeechToggle: _toggleSpeechToText,
          onInsertBlock: _onInsertBlock,
          onUndo: () => ref.read(editorBlockControllerProvider.notifier).undo(),
          onRedo: () => ref.read(editorBlockControllerProvider.notifier).redo(),
          canUndo: blocksState.undoStack.isNotEmpty,
          canRedo: blocksState.redoStack.isNotEmpty,
        );
      case EditorLayoutVariant.zen:
        return ZenLayout(
          noteId: _noteId,
          titleController: _titleController,
          tagController: _tagController,
          selectedFolderId: _selectedFolderId,
          onFolderChanged: onFolderChanged,
          noteType: _noteType,
          onNoteTypeChanged: onNoteTypeChanged,
          isPinned: _isPinned,
          onPinChanged: onPinChanged,
          isFavorite: _isFavorite,
          onFavoriteChanged: onFavoriteChanged,
          colorHex: _colorHex,
          onColorChanged: onColorChanged,
          blocks: blocksState.blocks,
          focusNodes: _focusNodes,
          scrollController: _scrollController,
          onSave: _saveNote,
          onPrintPdf: onPrintPdf,
          isSpeechListening: _isSpeechListening,
          onSpeechToggle: _toggleSpeechToText,
          onInsertBlock: _onInsertBlock,
          onUndo: () => ref.read(editorBlockControllerProvider.notifier).undo(),
          onRedo: () => ref.read(editorBlockControllerProvider.notifier).redo(),
          canUndo: blocksState.undoStack.isNotEmpty,
          canRedo: blocksState.redoStack.isNotEmpty,
        );
      case EditorLayoutVariant.classic:
      default:
        return ClassicLayout(
          noteId: _noteId,
          titleController: _titleController,
          tagController: _tagController,
          selectedFolderId: _selectedFolderId,
          onFolderChanged: onFolderChanged,
          noteType: _noteType,
          onNoteTypeChanged: onNoteTypeChanged,
          isPinned: _isPinned,
          onPinChanged: onPinChanged,
          isFavorite: _isFavorite,
          onFavoriteChanged: onFavoriteChanged,
          colorHex: _colorHex,
          onColorChanged: onColorChanged,
          blocks: blocksState.blocks,
          focusNodes: _focusNodes,
          scrollController: _scrollController,
          onSave: _saveNote,
          onPrintPdf: onPrintPdf,
          isSpeechListening: _isSpeechListening,
          onSpeechToggle: _toggleSpeechToText,
          onInsertBlock: _onInsertBlock,
          onUndo: () => ref.read(editorBlockControllerProvider.notifier).undo(),
          onRedo: () => ref.read(editorBlockControllerProvider.notifier).redo(),
          canUndo: blocksState.undoStack.isNotEmpty,
          canRedo: blocksState.redoStack.isNotEmpty,
        );
    }
  }
}
