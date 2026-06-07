import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as speech_to_text;
import 'package:uuid/uuid.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../models/models.dart';
import '../../../../features/notes/data/models/floating_sticker_model.dart';
import 'controllers/floating_stickers_controller.dart';
import '../../../../features/notes/presentation/controllers/notes_controller.dart';
import '../../../../features/templates/presentation/controllers/templates_controller.dart';
import '../../../../features/settings/presentation/controllers/settings_controller.dart';
import '../domain/entities/block_entity.dart';
import '../domain/entities/block_type.dart';
import '../domain/usecases/convert_blocks_to_delta.dart';
import '../domain/usecases/convert_delta_to_blocks.dart';
import 'controllers/editor_block_controller.dart';
import 'widgets/blocks/drawing_canvas_screen.dart';
import 'widgets/editor_shell/editor_body.dart';
import 'widgets/editor_shell/editor_route_actions.dart';
import '../../../../core/utils/clipboard_helper.dart';
import '../../../../core/utils/quill_paste_handler.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/quill_markdown_converter.dart';

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

  // Quill Editor Controller and FocusNode
  late QuillController _quillController;
  final FocusNode _editorFocusNode = FocusNode();
  EditorMode? _lastEditorMode;
  StreamSubscription? _quillSubscription;

  // Speech to Text
  final speech_to_text.SpeechToText _speechToText = speech_to_text.SpeechToText();
  bool _speechInitialized = false;
  bool _isSpeechListening = false;

  void _updateUi() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _noteId = widget.noteId ?? const Uuid().v4();
    _isEditMode = widget.noteId != null;
    _selectedFolderId = widget.initialFolderId;
    _templateId = widget.initialTemplateId;

    _quillController = QuillController.basic();
    _quillController.addListener(_updateUi);

    _titleController.addListener(_markDirty);
    _tagController.addListener(_markDirty);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNoteOrTemplate();
      _setupAutosave();
      setupClipboardPasteListener(
        context,
        _editorFocusNode,
        (dataUrl, fileName) {
          final index = _quillController.selection.baseOffset;
          final insertIndex = index >= 0 ? index : _quillController.document.length - 1;
          _quillController.replaceText(
            insertIndex,
            0,
            BlockEmbed.image(dataUrl),
            TextSelection.collapsed(offset: insertIndex + 1),
          );
        },
        (plainText, htmlText) {
          QuillPasteHandler.handlePasteText(_quillController, plainText, htmlText);
        },
      );
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
    _quillController.removeListener(_updateUi);
    _quillController.dispose();
    _editorFocusNode.dispose();
    _quillSubscription?.cancel();
    disposeClipboardPasteListener();
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
        ref.read(floatingStickersProvider.notifier).initialize(note.stickers);
      } else {
        ref.read(floatingStickersProvider.notifier).clear();
      }
    } else {
      ref.read(floatingStickersProvider.notifier).clear();
      if (_templateId != null) {
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
    }
    AppLogger.info('EditorScreen: Loading note/template $_noteId. IsEditMode: $_isEditMode. TemplateId: $_templateId.');

    final blocks = ConvertDeltaToBlocks.execute(noteContent);
    ref.read(editorBlockControllerProvider.notifier).initializeWithBlocks(blocks);

    _quillSubscription?.cancel();
    _quillController.removeListener(_updateUi);
    Document doc;
    if (noteContent.isNotEmpty) {
      try {
        final deltaJson = jsonDecode(noteContent);
        doc = Document.fromJson(deltaJson);
      } catch (e) {
        AppLogger.warning('EditorScreen: Failed to jsonDecode note content. Attempting markdownToDelta parsing. Error: $e');
        try {
          final ops = QuillMarkdownConverter.markdownToDeltaOps(noteContent);
          doc = Document.fromJson(ops);
        } catch (err) {
          AppLogger.error('EditorScreen: Markdown parsing failed too. Falling back to raw insert. Error: $err');
          doc = Document()..insert(0, noteContent);
        }
      }
    } else {
      doc = Document();
    }
    _quillController = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _quillController.addListener(_updateUi);
    _quillSubscription = _quillController.document.changes.listen((_) {
      _isDirty = true;
    });

    setState(() {});
  }

  Future<void> _saveNote({bool isAutoSave = false}) async {
    final settings = ref.read(settingsProvider);
    final blocksState = ref.read(editorBlockControllerProvider);
    if (!_isDirty && !blocksState.isDirty && isAutoSave) return;

    final title = _titleController.text.trim();
    AppLogger.info('EditorScreen: Saving note $_noteId (isAutoSave: $isAutoSave). Title: "$title".');
    
    final String content;
    if (settings.editorMode == EditorMode.gentleNote) {
      content = jsonEncode(_quillController.document.toDelta().toJson());
    } else {
      content = ConvertBlocksToDelta.execute(blocksState.blocks);
    }

    final tags = _tagController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final now = DateTime.now();
    final stickers = ref.read(floatingStickersProvider);
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
      stickers: stickers,
    );

    try {
      if (_isEditMode || ref.read(notesProvider).any((n) => n.id == _noteId)) {
        await ref.read(notesProvider.notifier).updateNote(note);
      } else {
        await ref.read(notesProvider.notifier).addNote(note);
      }
      ref.read(editorBlockControllerProvider.notifier).markClean();
      _isDirty = false;
      AppLogger.info('EditorScreen: Note $_noteId saved successfully (isAutoSave: $isAutoSave).');
    } catch (e, stack) {
      AppLogger.error('EditorScreen: Error saving note $_noteId', e, stack);
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
                final settings = ref.read(settingsProvider);
                if (settings.editorMode == EditorMode.gentleNote) {
                  final index = _quillController.selection.baseOffset;
                  final length = _quillController.selection.extentOffset - index;
                  _quillController.replaceText(index, length, text, null);
                  _markDirty();
                } else {
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

  Future<void> _openQuillDrawing() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => DrawingCanvasScreen(
          onSave: (strokes, pngBytes) async {
            if (pngBytes != null) {
              final dir = await getApplicationDocumentsDirectory();
              final fileName = 'drawing_${const Uuid().v4()}.png';
              final file = File('${dir.path}/$fileName');
              await file.writeAsBytes(pngBytes);
              
              final index = _quillController.selection.baseOffset;
              final length = _quillController.selection.extentOffset - index;
              _quillController.replaceText(index, length, BlockEmbed('image', 'file://${file.path}'), null);
              _markDirty();
            }
          },
        ),
      ),
    );
  }

  void _onInsertBlock(BlockType type, {String content = '', Map<String, dynamic> attributes = const {}}) {
    final settings = ref.read(settingsProvider);
    
    if (type == BlockType.sticker) {
      final id = const Uuid().v4();
      final scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
      ref.read(floatingStickersProvider.notifier).addSticker(FloatingStickerModel(
        id: id,
        name: content,
        x: 80.0,
        y: scrollOffset + 100.0,
      ));
      _markDirty();
      return;
    }
    
    if (settings.editorMode == EditorMode.gentleNote) {
      int index = _quillController.selection.baseOffset;
      int length = _quillController.selection.extentOffset - index;
      if (index < 0) {
        index = _quillController.document.length - 1;
        if (index < 0) index = 0;
        length = 0;
      }
      
      switch (type) {
        case BlockType.heading:
          final currentHeader = _quillController.getSelectionStyle().attributes[Attribute.header.key]?.value;
          final targetHeader = attributes['header'] ?? 1;
          _quillController.formatSelection(currentHeader == targetHeader ? Attribute.clone(Attribute.header, null) : Attribute.h1);
          break;
        case BlockType.checklist:
          final currentList = _quillController.getSelectionStyle().attributes[Attribute.list.key]?.value;
          final isTodoList = currentList == 'checked' || currentList == 'unchecked';
          _quillController.formatSelection(isTodoList ? Attribute.clone(Attribute.list, null) : Attribute.unchecked);
          break;
        case BlockType.code:
          final isCode = _quillController.getSelectionStyle().attributes[Attribute.codeBlock.key]?.value != null;
          _quillController.formatSelection(isCode ? Attribute.clone(Attribute.codeBlock, null) : Attribute.codeBlock);
          break;
        case BlockType.image:
          _quillController.replaceText(index, length, BlockEmbed('image', content), null);
          break;
        case BlockType.photoFrame:
          List<String> paths;
          try {
            paths = List<String>.from(jsonDecode(content));
          } catch (_) {
            paths = [];
          }
          final blockData = {
            'images': paths,
            'layout': attributes['layout'] ?? 'grid',
          };
          _quillController.replaceText(index, length, BlockEmbed('photo-frame', jsonEncode(blockData)), null);
          break;
        case BlockType.pdf:
          final pdfBlockData = {
            'path': content,
            'name': attributes['name'] ?? 'PDF Document',
            'pages': attributes['pages'] ?? <int>[],
            'crops': attributes['crops'] ?? <String, dynamic>{},
          };
          _quillController.replaceText(index, length, BlockEmbed('pdf', jsonEncode(pdfBlockData)), null);
          break;
        case BlockType.audio:
          _quillController.replaceText(index, length, BlockEmbed('audio', content), null);
          break;
        case BlockType.drawing:
          _openQuillDrawing();
          break;
        case BlockType.sticker:
          _quillController.replaceText(index, length, BlockEmbed('sticker', content), null);
          break;
        case BlockType.horizontalRule:
          _quillController.replaceText(index, length, BlockEmbed('horizontal-rule', ''), null);
          break;
        default:
          if (content.isNotEmpty) {
            _quillController.replaceText(index, length, content, null);
          }
      }
      _markDirty();
    } else {
      final state = ref.read(editorBlockControllerProvider);
      final index = state.selectedIndex >= 0 ? state.selectedIndex : state.blocks.length - 1;
      ref.read(editorBlockControllerProvider.notifier).insertBlock(
            index,
            type,
            content: content,
            attributes: attributes,
          );
      _markDirty();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final blocksState = ref.watch(editorBlockControllerProvider);

    final currentMode = settings.editorMode;
    if (_lastEditorMode != currentMode) {
      if (_lastEditorMode == EditorMode.gentleNote && currentMode == EditorMode.blockEditor) {
        final deltaJson = jsonEncode(_quillController.document.toDelta().toJson());
        final blocks = ConvertDeltaToBlocks.execute(deltaJson);
        ref.read(editorBlockControllerProvider.notifier).initializeWithBlocks(blocks);
      } else if (_lastEditorMode == EditorMode.blockEditor && currentMode == EditorMode.gentleNote) {
        final deltaJson = ConvertBlocksToDelta.execute(blocksState.blocks);
        try {
          final doc = Document.fromJson(jsonDecode(deltaJson));
          _quillController.removeListener(_updateUi);
          _quillController = QuillController(
            document: doc,
            selection: const TextSelection.collapsed(offset: 0),
          );
          _quillController.addListener(_updateUi);
          _quillSubscription?.cancel();
          _quillSubscription = _quillController.document.changes.listen((_) {
            _isDirty = true;
          });
        } catch (_) {}
      }
      _lastEditorMode = currentMode;
    }

    final layoutVariant = settings.editorLayout;
    debugPrint('EDITOR SCREEN BUILD - RESOLVED LAYOUT VARIANT: $layoutVariant');

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
      final content = settings.editorMode == EditorMode.gentleNote
          ? jsonEncode(_quillController.document.toDelta().toJson())
          : ConvertBlocksToDelta.execute(blocksState.blocks);
      final stickers = ref.read(floatingStickersProvider);
      final note = NoteModel(
        id: _noteId,
        folderId: _selectedFolderId,
        title: _titleController.text.trim().isEmpty ? 'Untitled Note' : _titleController.text.trim(),
        content: content,
        noteType: _noteType,
        tags: _tagController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        attachments: _attachments,
        templateId: _templateId,
        isPinned: _isPinned,
        isFavorite: _isFavorite,
        colorHex: _colorHex,
        createdAt: _createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        stickers: stickers,
      );
      EditorRouteActions.exportToPdf(context, note);
    };

    final canUndo = settings.editorMode == EditorMode.gentleNote
        ? _quillController.hasUndo
        : blocksState.undoStack.isNotEmpty;
    final canRedo = settings.editorMode == EditorMode.gentleNote
        ? _quillController.hasRedo
        : blocksState.redoStack.isNotEmpty;

    final onUndo = () {
      if (settings.editorMode == EditorMode.gentleNote) {
        _quillController.undo();
      } else {
        ref.read(editorBlockControllerProvider.notifier).undo();
      }
    };
    final onRedo = () {
      if (settings.editorMode == EditorMode.gentleNote) {
        _quillController.redo();
      } else {
        ref.read(editorBlockControllerProvider.notifier).redo();
      }
    };

    return EditorBody(
      layoutVariant: layoutVariant,
      editorMode: settings.editorMode,
      noteId: _noteId,
      quillController: _quillController,
      editorFocusNode: _editorFocusNode,
      attachments: _attachments,
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
      onUndo: onUndo,
      onRedo: onRedo,
      canUndo: canUndo,
      canRedo: canRedo,
    );
  }
}
