import 'dart:ui' show ImageFilter;
import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:speech_to_text/speech_to_text.dart' as speech_to_text;

import '../../../core/widgets/gentle_scaffold.dart';
import '../../../core/utils/quill_markdown_converter.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/utils/clipboard_helper.dart';
import '../../../models/models.dart';
import '../../folders/data/folders_repository.dart';
import '../../notes/data/notes_repository.dart';
import '../../templates/data/templates_repository.dart';
import '../../settings/data/settings_repository.dart';
import '../../../services/export_import_service.dart';
import '../../../services/pdf_export_service.dart';
import 'widgets/preview_style_painter.dart';
import 'widgets/inline_audio_player.dart';
import 'widgets/markdown_widget.dart';
import 'drawing_canvas_screen.dart';
import 'widgets/image_embed_builder.dart';
import 'widgets/voice_recorder_bottom_sheet.dart';
import 'widgets/audio_embed_builder.dart';
import 'widgets/horizontal_rule_embed_builder.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String? noteId;
  final String? initialFolderId;
  final String? initialTemplateId;

  const NoteEditorScreen({
    super.key,
    this.noteId,
    this.initialFolderId,
    this.initialTemplateId,
  });

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> with SingleTickerProviderStateMixin {
  late String _noteId;
  bool _isEditMode = false;

  final TextEditingController _titleController = TextEditingController();
  QuillController _quillController = QuillController.basic();
  final TextEditingController _tagController = TextEditingController();
  final FocusNode _editorFocusNode = FocusNode();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _tagsFocusNode = FocusNode();

  NoteType _noteType = NoteType.text;
  String? _selectedFolderId;
  String? _templateId;
  bool _isPinned = false;
  bool _isFavorite = false;
  String _colorHex = '#FFFFFF';
  DateTime? _createdAt;
  List<AttachmentModel> _attachments = [];
  MarkdownLayoutMode _markdownLayout = MarkdownLayoutMode.splitView;
  bool _isPreviewMode = false;
  String? _activeToolbarGroup;
  bool _isToolsTabSelected = false;

  String? _activeColorMode;
  bool _showCustomColorPicker = false;
  double _customHue = 0.0;
  double _customSaturation = 1.0;
  double _customLightness = 0.5;
  Color _customSelectedColor = const Color(0xFFEF4444);
  final List<Color> _userSavedColors = [];

  // ── UI mode flags ────────────────────────────────────────────────────────
  bool _isFullScreen = false;
  bool _isFocusMode = false;

  // ── Zen layout: shows/hides chrome on tap ─────────────────────────────────
  bool _zenChromeVisible = false;

  String get _currentFontFamily {
    return _noteType == NoteType.mixed
        ? 'Georgia'
        : (_noteType == NoteType.code ? 'Courier' : 'Inter');
  }

  // ── Preview background ───────────────────────────────────────────────────
  Color? _previewBgColor;
  String? _previewBgImagePath;
  double _previewOverlayOpacity = 0.0;
  Color _previewOverlayColor = Colors.black;
  bool _showBgPicker = false;

  // ── Preview Style ────────────────────────────────────────────────────────
  PreviewStyle _previewStyle = PreviewStyle.plain;

  // ── Voice Notes ──────────────────────────────────────────────────────────

  // ── Speech to Text (Voice typing) ────────────────────────────────────────
  final speech_to_text.SpeechToText _speechToText = speech_to_text.SpeechToText();
  bool _speechInitialized = false;
  bool _isSpeechListening = false;

  Timer? _autoSaveTimer;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _noteId = widget.noteId ?? const Uuid().v4();
    _isEditMode = widget.noteId != null;
    _selectedFolderId = widget.initialFolderId;
    _templateId = widget.initialTemplateId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNoteOrTemplate();
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
          _handlePasteText(plainText, htmlText);
        },
      );
    });

    _titleController.addListener(_markDirty);
    _tagController.addListener(_markDirty);

    _titleFocusNode.addListener(_onFocusChange);
    _tagsFocusNode.addListener(_onFocusChange);
    _editorFocusNode.addListener(_onFocusChange);

    final settings = ref.read(settingsProvider);
    if (settings.autoSaveEnabled) {
      _autoSaveTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (_isDirty) {
          _saveNote(isAutoSave: true);
        }
      });
    }
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }



  void _markDirty() {
    _isDirty = true;
  }

  void _loadNoteOrTemplate() {
    if (_isEditMode) {
      final notes = ref.read(notesProvider);
      final note = notes.cast<NoteModel?>().firstWhere(
            (n) => n?.id == _noteId,
            orElse: () => null,
          );

      if (note != null) {
        setState(() {
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

          Document doc;
          if (note.content.startsWith('[')) {
            try {
              final list = jsonDecode(note.content) as List;
              doc = Document.fromJson(list);
            } catch (e) {
              final ops = QuillMarkdownConverter.markdownToDeltaOps(note.content);
              doc = Document.fromJson(ops);
            }
          } else {
            final ops = QuillMarkdownConverter.markdownToDeltaOps(note.content);
            doc = Document.fromJson(ops);
          }

          _quillController.dispose();
          _quillController = QuillController(
            document: doc,
            selection: const TextSelection.collapsed(offset: 0),
          );
          _quillController.readOnly = _isPreviewMode;
          _quillController.changes.listen((_) => _markDirty());
          _quillController.addListener(() {
            if (mounted) setState(() {});
          });
        });
      }
    } else {
      final settings = ref.read(settingsProvider);
      setState(() {
        _noteType = settings.defaultNoteType;
      });

      if (_templateId != null) {
        final templates = ref.read(templatesProvider);
        final template = templates.cast<NoteTemplateModel?>().firstWhere(
              (t) => t?.id == _templateId,
              orElse: () => null,
            );

        if (template != null) {
          setState(() {
            _titleController.text = template.defaultTitle;
            _tagController.text = template.defaultTags.join(', ');

            final ops = QuillMarkdownConverter.markdownToDeltaOps(template.defaultContent);
            final doc = Document.fromJson(ops);
            _quillController.dispose();
            _quillController = QuillController(
              document: doc,
              selection: const TextSelection.collapsed(offset: 0),
            );
            _quillController.readOnly = _isPreviewMode;
            _quillController.changes.listen((_) => _markDirty());
            _quillController.addListener(() {
              if (mounted) setState(() {});
            });

            if (template.id == 't-code') {
              _noteType = NoteType.code;
            } else if (template.id == 't-journal' || template.id == 't-study') {
              _noteType = NoteType.markdown;
            }
          });
        }
      } else {
        _quillController.dispose();
        _quillController = QuillController(
          document: Document(),
          selection: const TextSelection.collapsed(offset: 0),
        );
        _quillController.readOnly = _isPreviewMode;
        _quillController.changes.listen((_) => _markDirty());
        _quillController.addListener(() {
          if (mounted) setState(() {});
        });
      }
    }

    setState(() {
      _isDirty = false;
    });
  }

  Future<void> _saveNote({bool isAutoSave = false}) async {
    if (!_isDirty && isAutoSave) return;

    final title = _titleController.text.trim();
    final content = jsonEncode(_quillController.document.toDelta().toJson());
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
    } catch (e) {
      debugPrint('Note auto-save ignored during disposal: $e');
    }

    _isDirty = false;

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

  @override
  void dispose() {
    disposeClipboardPasteListener();
    _autoSaveTimer?.cancel();
    if (_isDirty) {
      _saveNote(isAutoSave: true);
    }
    _titleFocusNode.removeListener(_onFocusChange);
    _tagsFocusNode.removeListener(_onFocusChange);
    _editorFocusNode.removeListener(_onFocusChange);
    _titleController.dispose();
    _quillController.dispose();
    _tagController.dispose();
    _editorFocusNode.dispose();
    _titleFocusNode.dispose();
    _tagsFocusNode.dispose();
    super.dispose();
  }

  String _convertHtmlToMarkdown(String html) {
    String result = html;
    
    // Replace headings
    result = result.replaceAllMapped(RegExp(r'<h1[^>]*>([\s\S]*?)</h1>', caseSensitive: false), (m) => '# ${m[1]}\n\n');
    result = result.replaceAllMapped(RegExp(r'<h2[^>]*>([\s\S]*?)</h2>', caseSensitive: false), (m) => '## ${m[1]}\n\n');
    result = result.replaceAllMapped(RegExp(r'<h3[^>]*>([\s\S]*?)</h3>', caseSensitive: false), (m) => '### ${m[1]}\n\n');
    result = result.replaceAllMapped(RegExp(r'<h4[^>]*>([\s\S]*?)</h4>', caseSensitive: false), (m) => '#### ${m[1]}\n\n');
    result = result.replaceAllMapped(RegExp(r'<h5[^>]*>([\s\S]*?)</h5>', caseSensitive: false), (m) => '##### ${m[1]}\n\n');
    result = result.replaceAllMapped(RegExp(r'<h6[^>]*>([\s\S]*?)</h6>', caseSensitive: false), (m) => '###### ${m[1]}\n\n');
    
    // Replace bold & strong
    result = result.replaceAllMapped(RegExp(r'<strong[^>]*>([\s\S]*?)</strong>|<b[^>]*>([\s\S]*?)</b>', caseSensitive: false), (m) => '**${m[1] ?? m[2]}**');
    
    // Replace italic & em
    result = result.replaceAllMapped(RegExp(r'<em[^>]*>([\s\S]*?)</em>|<i[^>]*>([\s\S]*?)</i>', caseSensitive: false), (m) => '*${m[1] ?? m[2]}*');
    
    // Replace underline
    result = result.replaceAllMapped(RegExp(r'<u[^>]*>([\s\S]*?)</u>', caseSensitive: false), (m) => '<u>${m[1]}</u>');
    
    // Replace strike
    result = result.replaceAllMapped(RegExp(r'<strike[^>]*>([\s\S]*?)</strike>|<s[^>]*>([\s\S]*?)</s>|<del[^>]*>([\s\S]*?)</del>', caseSensitive: false), (m) => '~~${m[1] ?? m[2] ?? m[3]}~~');
    
    // Replace lists
    // Unordered
    result = result.replaceAllMapped(RegExp(r'<ul[^>]*>([\s\S]*?)</ul>', caseSensitive: false), (m) {
      var listContent = m[1]!;
      listContent = listContent.replaceAllMapped(RegExp(r'<li[^>]*>([\s\S]*?)</li>', caseSensitive: false), (li) {
        var content = li[1]!;
        // Check for checked checkbox
        if (RegExp(r'<input[^>]*type="checkbox"[^>]*checked', caseSensitive: false).hasMatch(content)) {
          content = content.replaceAll(RegExp(r'<input[^>]*>', caseSensitive: false), '');
          return '- [x] ${content.trim()}\n';
        }
        // Check for unchecked checkbox
        if (RegExp(r'<input[^>]*type="checkbox"', caseSensitive: false).hasMatch(content)) {
          content = content.replaceAll(RegExp(r'<input[^>]*>', caseSensitive: false), '');
          return '- [ ] ${content.trim()}\n';
        }
        return '- ${content.trim()}\n';
      });
      return '$listContent\n';
    });
    // Ordered
    result = result.replaceAllMapped(RegExp(r'<ol[^>]*>([\s\S]*?)</ol>', caseSensitive: false), (m) {
      var listContent = m[1]!;
      int index = 1;
      listContent = listContent.replaceAllMapped(RegExp(r'<li[^>]*>([\s\S]*?)</li>', caseSensitive: false), (li) => '${index++}. ${li[1]?.trim()}\n');
      return '$listContent\n';
    });
    
    // Replace code blocks and inline code
    result = result.replaceAllMapped(RegExp(r'<pre[^>]*><code[^>]*>([\s\S]*?)</code></pre>', caseSensitive: false), (m) => '```\n${m[1]}\n```\n\n');
    result = result.replaceAllMapped(RegExp(r'<code[^>]*>([\s\S]*?)</code>', caseSensitive: false), (m) => '`${m[1]}`');
    
    // Replace links
    result = result.replaceAllMapped(RegExp(r'<a[^>]*href="([^"]*)"[^>]*>([\s\S]*?)</a>', caseSensitive: false), (m) => '[${m[2]}](${m[1]})');
    
    // Replace line breaks & paragraphs
    result = result.replaceAll(RegExp(r'<br[^>]*>', caseSensitive: false), '\n');
    result = result.replaceAllMapped(RegExp(r'<p[^>]*>([\s\S]*?)</p>', caseSensitive: false), (m) => '${m[1]}\n\n');
    
    // Strip remaining tags except div, span, mark, u, details, summary
    result = result.replaceAll(RegExp(r'<(?!/?(div|span|mark|u|details|summary)\b)[^>]+>', caseSensitive: false), '');
    
    // Clean up entities
    result = result
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
        
    return result;
  }

  bool _detectMarkdown(String text) {
    if (text.isEmpty) return false;
    
    final headingRegex = RegExp(r'^#{1,6}\s+', multiLine: true);
    final bulletRegex = RegExp(r'^(\s*)[-*+]\s+', multiLine: true);
    final orderedRegex = RegExp(r'^(\s*)\d+\.\s+', multiLine: true);
    final checklistRegex = RegExp(r'^(\s*)[-*+]\s+\[[\s_xX]?\]\s+', multiLine: true);
    final codeBlockRegex = RegExp(r'```');
    final blockquoteRegex = RegExp(r'^(\s*)>\s+', multiLine: true);
    final tableRegex = RegExp(r'^\s*\|.*\|', multiLine: true);
    final inlineFormatRegex = RegExp(r'\*\*.*?\*\*|\*.*?\*|~~.*?~~|`.*?`|<u>.*?</u>');
    final linkRegex = RegExp(r'\[.*?\]\(.*?\)');
    final hrRegex = RegExp(r'^\s*(\*|-|_)\s*\1\s*\1\s*(\1|\s)*$', multiLine: true);
    final mathRegex = RegExp(r'\$\$|\\int_');
    
    return headingRegex.hasMatch(text) ||
        bulletRegex.hasMatch(text) ||
        orderedRegex.hasMatch(text) ||
        checklistRegex.hasMatch(text) ||
        codeBlockRegex.hasMatch(text) ||
        blockquoteRegex.hasMatch(text) ||
        tableRegex.hasMatch(text) ||
        inlineFormatRegex.hasMatch(text) ||
        linkRegex.hasMatch(text) ||
        hrRegex.hasMatch(text) ||
        mathRegex.hasMatch(text);
  }

  Future<void> _handlePasteText(String plainText, [String? htmlText]) async {
    String textToParse = plainText;
    
    if (htmlText != null && htmlText.isNotEmpty) {
      textToParse = _convertHtmlToMarkdown(htmlText);
    }
    
    final isMarkdown = _detectMarkdown(textToParse);
    
    if (isMarkdown) {
      final ops = QuillMarkdownConverter.markdownToDeltaOps(textToParse);
      
      if (ops.isNotEmpty && !textToParse.endsWith('\n')) {
        final lastOp = ops.last;
        if (lastOp['insert'] == '\n' && (lastOp['attributes'] == null || (lastOp['attributes'] as Map).isEmpty)) {
          ops.removeLast();
        }
      }
      
      final index = _quillController.selection.baseOffset;
      final insertIndex = index >= 0 ? index : _quillController.document.length - 1;
      final length = _quillController.selection.extentOffset - index;
      
      final change = Delta();
      if (insertIndex > 0) {
        change.retain(insertIndex);
      }
      if (length > 0) {
        change.delete(length);
      }
      
      int pastedLength = 0;
      for (final op in ops) {
        final insertVal = op['insert'];
        final attrs = op['attributes'] as Map<String, dynamic>?;
        
        change.insert(insertVal, attrs);
        if (insertVal is String) {
          pastedLength += insertVal.length;
        } else {
          pastedLength += 1;
        }
      }
      
      _quillController.document.compose(change, ChangeSource.local);
      _quillController.updateSelection(
        TextSelection.collapsed(offset: insertIndex + pastedLength),
        ChangeSource.local,
      );
    } else {
      final index = _quillController.selection.baseOffset;
      final insertIndex = index >= 0 ? index : _quillController.document.length - 1;
      final length = _quillController.selection.extentOffset - index;
      
      _quillController.replaceText(
        insertIndex,
        length,
        plainText,
        TextSelection.collapsed(offset: insertIndex + plainText.length),
      );
    }
  }

  // --- ACTIONS HANDLERS ---

  Future<void> _handleShare(BuildContext context) async {
    await _saveNote();
    final folders = ref.read(foldersProvider);
    final folder = folders.cast<FolderModel?>().firstWhere(
          (f) => f?.id == _selectedFolderId,
          orElse: () => null,
        );

    final note = ref.read(notesProvider).firstWhere((n) => n.id == _noteId);
    await ExportImportService().shareNote(note, folderName: folder?.name);
  }

  Future<void> _handleExportMarkdown(BuildContext context) async {
    await _saveNote();
    final note = ref.read(notesProvider).firstWhere((n) => n.id == _noteId);
    final markdown = ExportImportService().exportNoteAsMarkdown(note);

    await Share.share(markdown, subject: '${note.title}.md');
  }

  Future<void> _handleDeleteNote(BuildContext context) async {
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
                _autoSaveTimer?.cancel();
                _isDirty = false;
                await ref.read(notesProvider.notifier).deleteNote(_noteId);
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

  Future<void> _handlePrintPdf(BuildContext context) async {
    await _saveNote();
    if (!mounted) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String selectedSize = 'A4';
    bool isLandscape = false;
    bool inclMetadata = true;
    bool inclTags = true;

    final sizeMap = {
      'A4': PdfPageFormat.a4,
      'Letter': PdfPageFormat.letter,
      'Legal': PdfPageFormat.legal,
      'A3': PdfPageFormat.a3,
    };

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setS) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF13111C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark ? const Color(0xFF252234) : const Color(0xFFE9E6F5),
            ),
          ),
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx2).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3D3557) : const Color(0xFFD1CBE8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Export PDF', style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: 'Outfit', fontWeight: FontWeight.w700,
                  )),
                ],
              ),
              const SizedBox(height: 20),

              Text('Paper Size', style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700, letterSpacing: 0.8,
                color: const Color(0xFF8B5CF6),
              )),
              const SizedBox(height: 8),
              Row(
                children: sizeMap.keys.map((size) {
                  final selected = selectedSize == size;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setS(() => selectedSize = size),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFF8B5CF6) : (isDark ? const Color(0xFF1C1829) : const Color(0xFFF3F0FF)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? const Color(0xFF8B5CF6) : (isDark ? const Color(0xFF2E2845) : const Color(0xFFD4C8F5)),
                          ),
                        ),
                        child: Text(
                          size,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: selected ? Colors.white : (isDark ? const Color(0xFFAA9ECC) : const Color(0xFF7C3AED)),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              Text('Orientation', style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700, letterSpacing: 0.8,
                color: const Color(0xFF8B5CF6),
              )),
              const SizedBox(height: 8),
              Row(
                children: [
                  _pdfOptionPill('Portrait', !isLandscape, Icons.crop_portrait_rounded, isDark,
                      () => setS(() => isLandscape = false)),
                  const SizedBox(width: 8),
                  _pdfOptionPill('Landscape', isLandscape, Icons.crop_landscape_rounded, isDark,
                      () => setS(() => isLandscape = true)),
                ],
              ),
              const SizedBox(height: 16),

              Text('Include', style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700, letterSpacing: 0.8,
                color: const Color(0xFF8B5CF6),
              )),
              const SizedBox(height: 8),
              Row(
                children: [
                  _pdfTogglePill('Metadata', inclMetadata, isDark, () => setS(() => inclMetadata = !inclMetadata)),
                  const SizedBox(width: 8),
                  _pdfTogglePill('Tags', inclTags, isDark, () => setS(() => inclTags = !inclTags)),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx2);
                    var fmt = sizeMap[selectedSize] ?? PdfPageFormat.a4;
                    if (isLandscape) fmt = fmt.landscape;
                    final folders = ref.read(foldersProvider);
                    final folder = folders.cast<FolderModel?>().firstWhere(
                      (f) => f?.id == _selectedFolderId, orElse: () => null);
                    final note = ref.read(notesProvider).firstWhere((n) => n.id == _noteId);
                    try {
                      await PdfExportService().printOrExportNote(
                        note,
                        folderName: folder?.name,
                        pageFormat: fmt,
                        includeMetadata: inclMetadata,
                        includeTags: inclTags,
                      );
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('PDF Error: $e'),
                            backgroundColor: Colors.red.shade700,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Generate PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _pdfOptionPill(String label, bool selected, IconData icon, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF8B5CF6) : (isDark ? const Color(0xFF1C1829) : const Color(0xFFF3F0FF)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF8B5CF6) : (isDark ? const Color(0xFF2E2845) : const Color(0xFFD4C8F5)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : (isDark ? const Color(0xFFAA9ECC) : const Color(0xFF7C3AED))),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: selected ? Colors.white : (isDark ? const Color(0xFFAA9ECC) : const Color(0xFF7C3AED)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pdfTogglePill(String label, bool selected, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF8B5CF6) : (isDark ? const Color(0xFF1C1829) : const Color(0xFFF3F0FF)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF8B5CF6) : (isDark ? const Color(0xFF2E2845) : const Color(0xFFD4C8F5)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 16,
              color: selected ? Colors.white : (isDark ? const Color(0xFFAA9ECC) : const Color(0xFF7C3AED)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: selected ? Colors.white : (isDark ? const Color(0xFFAA9ECC) : const Color(0xFF7C3AED)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutSelector() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF13111C) : const Color(0xFFFBFBFE),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _layoutSelectorItem(MarkdownLayoutMode.editOnly, Icons.edit_rounded, 'Editor Only'),
          _layoutSelectorItem(MarkdownLayoutMode.splitView, Icons.splitscreen_rounded, 'Split View'),
          _layoutSelectorItem(MarkdownLayoutMode.previewOnly, Icons.preview_rounded, 'Preview Only'),
        ],
      ),
    );
  }

  Widget _layoutSelectorItem(MarkdownLayoutMode mode, IconData icon, String label) {
    final theme = Theme.of(context);
    final isSelected = _markdownLayout == mode;
    final activeColor = theme.colorScheme.primary;

    return InkWell(
      onTap: () => setState(() => _markdownLayout = mode),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? activeColor : theme.colorScheme.onSurfaceVariant.withOpacity(0.6)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogPillButton({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _insertImageDialog() async {
    final theme = Theme.of(context);
    String selectedSize = 'medium';
    String selectedAlign = 'center';
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Insert Image'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _pickAndInsertLocalImage(ImageSource.camera, selectedSize, selectedAlign);
                      },
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Take Photo (Camera)'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _pickAndInsertLocalImage(ImageSource.gallery, selectedSize, selectedAlign);
                      },
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Upload Local Image (Gallery)'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('OR', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: urlController,
                      decoration: const InputDecoration(
                        labelText: 'Image Web URL',
                        hintText: 'https://example.com/image.jpg',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Layout Options',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Alignment', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _dialogPillButton(
                          label: 'Left',
                          isSelected: selectedAlign == 'left',
                          onTap: () => setStateDialog(() => selectedAlign = 'left'),
                        ),
                        const SizedBox(width: 8),
                        _dialogPillButton(
                          label: 'Center',
                          isSelected: selectedAlign == 'center',
                          onTap: () => setStateDialog(() => selectedAlign = 'center'),
                        ),
                        const SizedBox(width: 8),
                        _dialogPillButton(
                          label: 'Right',
                          isSelected: selectedAlign == 'right',
                          onTap: () => setStateDialog(() => selectedAlign = 'right'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Size Preset', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _dialogPillButton(
                          label: 'Small',
                          isSelected: selectedSize == 'small',
                          onTap: () => setStateDialog(() => selectedSize = 'small'),
                        ),
                        const SizedBox(width: 8),
                        _dialogPillButton(
                          label: 'Medium',
                          isSelected: selectedSize == 'medium',
                          onTap: () => setStateDialog(() => selectedSize = 'medium'),
                        ),
                        const SizedBox(width: 8),
                        _dialogPillButton(
                          label: 'Full Width',
                          isSelected: selectedSize == 'large',
                          onTap: () => setStateDialog(() => selectedSize = 'large'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final url = urlController.text.trim();
                    if (url.isNotEmpty) {
                      Navigator.pop(context);
                      final index = _quillController.selection.baseOffset;
                      final insertIndex = index >= 0 ? index : _quillController.document.length - 1;
                      final length = _quillController.selection.extentOffset - index;
                      _quillController.replaceText(
                        insertIndex,
                        length >= 0 ? length : 0,
                        BlockEmbed.image(url),
                        TextSelection.collapsed(offset: insertIndex + 1),
                      );
                      _markDirty();
                    }
                  },
                  child: const Text('Insert URL'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndInsertLocalImage(ImageSource source, String size, String align) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      final attachmentId = const Uuid().v4();
      String dataUrlOrPath = '';

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        final base64Str = base64Encode(bytes);
        final fileExtension = image.name.split('.').last.toLowerCase();
        final mimeType = fileExtension == 'png' ? 'image/png' : 'image/jpeg';
        dataUrlOrPath = 'data:$mimeType;base64,$base64Str';
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        final fileExtension = image.name.split('.').last.toLowerCase();
        final uniqueName = '$attachmentId.$fileExtension';
        final savedFile = io.File('${appDir.path}/$uniqueName');
        
        final bytes = await image.readAsBytes();
        await savedFile.writeAsBytes(bytes);
        
        dataUrlOrPath = 'file://${savedFile.path}';
      }

      final newAttachment = AttachmentModel(
        id: attachmentId,
        noteId: _noteId,
        type: AttachmentType.image,
        name: image.name,
        pathOrUrl: dataUrlOrPath,
        createdAt: DateTime.now(),
      );

      setState(() {
        _attachments.add(newAttachment);
        _isDirty = true;
      });

      final index = _quillController.selection.baseOffset;
      final insertIndex = index >= 0 ? index : _quillController.document.length - 1;
      final length = _quillController.selection.extentOffset - index;
      _quillController.replaceText(
        insertIndex,
        length >= 0 ? length : 0,
        BlockEmbed.image(dataUrlOrPath),
        TextSelection.collapsed(offset: insertIndex + 1),
      );
      _markDirty();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image inserted successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Speech to Text Dictation (Voice Typing) ──────────────────────────────
  Future<void> _toggleSpeechToText() async {
    if (_isSpeechListening) {
      await _speechToText.stop();
      setState(() {
        _isSpeechListening = false;
      });
    } else {
      if (!_speechInitialized) {
        _speechInitialized = await _speechToText.initialize(
          onError: (error) {
            debugPrint('STT error: $error');
            setState(() {
              _isSpeechListening = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Speech recognition error: ${error.errorMsg}'), backgroundColor: Colors.red),
            );
          },
          onStatus: (status) {
            debugPrint('STT status: $status');
            if (status == 'done' || status == 'notListening') {
              setState(() {
                _isSpeechListening = false;
              });
            }
          },
        );
      }

      if (_speechInitialized) {
        setState(() {
          _isSpeechListening = true;
        });
        await _speechToText.listen(
          onResult: (result) {
            if (result.finalResult) {
              final text = result.recognizedWords;
              if (text.isNotEmpty) {
                final index = _quillController.selection.baseOffset;
                final insertIndex = index >= 0 ? index : _quillController.document.length - 1;
                _quillController.document.insert(insertIndex, ' $text');
                _quillController.updateSelection(
                  TextSelection.collapsed(offset: insertIndex + text.length + 1),
                  ChangeSource.local,
                );
                _markDirty();
              }
            }
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available or permission denied'), backgroundColor: Colors.red),
        );
      }
    }
  }



  Color _getCurrentSelectedColor() {
    final style = _quillController.getSelectionStyle();
    if (_activeColorMode == 'text') {
      final attr = style.attributes[Attribute.color.key];
      if (attr != null && attr.value is String) {
        return Color(int.parse('FF${(attr.value as String).replaceAll('#', '')}', radix: 16));
      }
      return Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;
    } else if (_activeColorMode == 'highlight') {
      final attr = style.attributes[Attribute.background.key];
      if (attr != null && attr.value is String) {
        return Color(int.parse('FF${(attr.value as String).replaceAll('#', '')}', radix: 16));
      }
      return Colors.transparent;
    }
    return Colors.transparent;
  }

  void _applyColor(Color? color) {
    if (_titleFocusNode.hasFocus) return;
    final hexStr = color != null
        ? '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}'
        : null;

    if (_activeColorMode == 'text') {
      _quillController.formatSelection(ColorAttribute(hexStr));
    } else if (_activeColorMode == 'highlight') {
      _quillController.formatSelection(BackgroundAttribute(hexStr));
    }
    _markDirty();
  }

  void _updateCustomColor() {
    _customSelectedColor = HSLColor.fromAHSL(1.0, _customHue, _customSaturation, _customLightness).toColor();
    _applyColor(_customSelectedColor);
  }

  void _updateCustomColorPickerFromSelection() {
    final color = _getCurrentSelectedColor();
    if (color != Colors.transparent &&
        color != (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)) {
      final hsl = HSLColor.fromColor(color);
      setState(() {
        _customHue = hsl.hue;
        _customSaturation = hsl.saturation;
        _customLightness = hsl.lightness;
        _customSelectedColor = color;
      });
    }
  }

  Widget _buildColorSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required Gradient gradient,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 38,
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              gradient: gradient,
            ),
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 10,
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                thumbColor: Colors.white,
                overlayColor: Colors.transparent,
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineCustomColorPicker(ThemeData theme, bool isDark) {
    final hexStr = '#${_customSelectedColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildColorSlider(
          label: 'Hue',
          value: _customHue,
          min: 0.0,
          max: 360.0,
          gradient: LinearGradient(
            colors: List.generate(360, (index) => HSLColor.fromAHSL(1.0, index.toDouble(), 1.0, 0.5).toColor()),
          ),
          onChanged: (val) {
            setState(() {
              _customHue = val;
              _updateCustomColor();
            });
          },
        ),
        const SizedBox(height: 6),
        _buildColorSlider(
          label: 'Sat',
          value: _customSaturation,
          min: 0.0,
          max: 1.0,
          gradient: LinearGradient(
            colors: [
              HSLColor.fromAHSL(1.0, _customHue, 0.0, _customLightness).toColor(),
              HSLColor.fromAHSL(1.0, _customHue, 1.0, _customLightness).toColor(),
            ],
          ),
          onChanged: (val) {
            setState(() {
              _customSaturation = val;
              _updateCustomColor();
            });
          },
        ),
        const SizedBox(height: 6),
        _buildColorSlider(
          label: 'Light',
          value: _customLightness,
          min: 0.0,
          max: 1.0,
          gradient: LinearGradient(
            colors: [
              Colors.black,
              HSLColor.fromAHSL(1.0, _customHue, _customSaturation, 0.5).toColor(),
              Colors.white,
            ],
          ),
          onChanged: (val) {
            setState(() {
              _customLightness = val;
              _updateCustomColor();
            });
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _customSelectedColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              hexStr,
              style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              tooltip: 'Save to Palette',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                if (!_userSavedColors.contains(_customSelectedColor)) {
                  setState(() {
                    _userSavedColors.add(_customSelectedColor);
                  });
                }
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 24,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _userSavedColors.map((c) {
                      final isSelected = _getCurrentSelectedColor() == c;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _customSelectedColor = c;
                            final hsl = HSLColor.fromColor(c);
                            _customHue = hsl.hue;
                            _customSaturation = hsl.saturation;
                            _customLightness = hsl.lightness;
                          });
                          _applyColor(c);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? theme.colorScheme.primary : Colors.grey.shade400,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGentleNoteToolbar(ThemeData theme, bool isDark, {bool isAtBottom = false}) {
    const groups = [
      ('format', Icons.format_bold, 'Format'),
      ('color',   Icons.palette_outlined, 'Color'),
      ('heading', Icons.title_rounded, 'Heading'),
      ('align',   Icons.format_align_left_rounded, 'Align'),
      ('lists',   Icons.format_list_bulleted, 'Lists'),
      ('insert',  Icons.add_box_outlined, 'Insert'),
      ('indent',  Icons.format_indent_increase_rounded, 'Indent'),
    ];

    final surfaceColor = isDark
        ? const Color(0xFF13111C).withOpacity(0.97)
        : Colors.white.withOpacity(0.97);
    final borderColor = isDark ? const Color(0xFF2E2845) : const Color(0xFFE8E4F5);
    final accentColor = theme.colorScheme.primary;

    Widget groupBtn(String id, IconData icon, String label) {
      final isActive = _activeToolbarGroup == id;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() {
            _activeToolbarGroup = (isActive ? null : id);
            if (_activeToolbarGroup != 'color') {
              _activeColorMode = null;
              _showCustomColorPicker = false;
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: isActive ? accentColor.withOpacity(0.12) : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: isActive ? accentColor : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: isActive ? accentColor : theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? accentColor : theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget sub(IconData icon, String tooltip, VoidCallback onTap, {bool active = false}) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: active ? accentColor.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: active ? accentColor : theme.colorScheme.onSurface),
          ),
        ),
      );
    }

    Widget subText(String text, String tooltip, VoidCallback onTap, {bool active = false}) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: active ? accentColor.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: active ? accentColor : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      );
    }

    final style = _quillController.getSelectionStyle();
    final isBold = !_titleFocusNode.hasFocus && style.containsKey(Attribute.bold.key);
    final isItalic = !_titleFocusNode.hasFocus && style.containsKey(Attribute.italic.key);
    final isUnderline = !_titleFocusNode.hasFocus && style.containsKey(Attribute.underline.key);
    final isStrike = !_titleFocusNode.hasFocus && style.containsKey(Attribute.strikeThrough.key);
    final isCode = style.containsKey(Attribute.inlineCode.key);

    final isH1 = style.attributes[Attribute.header.key]?.value == 1;
    final isH2 = style.attributes[Attribute.header.key]?.value == 2;
    final isH3 = style.attributes[Attribute.header.key]?.value == 3;
    final isH4 = style.attributes[Attribute.header.key]?.value == 4;

    final alignVal = style.attributes[Attribute.align.key]?.value;
    final isAlignLeft = alignVal == null || alignVal == 'left';
    final isAlignCenter = alignVal == 'center';
    final isAlignRight = alignVal == 'right';
    final isAlignJustify = alignVal == 'justify';

    final listVal = style.attributes[Attribute.list.key]?.value;
    final isBullet = listVal == 'bullet';
    final isOrdered = listVal == 'ordered';
    final isChecklist = listVal == 'checked' || listVal == 'unchecked';
    final isBlockquote = style.containsKey(Attribute.blockQuote.key);
    final isCodeBlock = style.containsKey(Attribute.codeBlock.key);

    Widget subRow() {
      switch (_activeToolbarGroup) {
        case 'format':
          return Row(
            children: [
              sub(Icons.format_bold, 'Bold', () {
                if (!_titleFocusNode.hasFocus) {
                  _quillController.formatSelection(isBold ? Attribute.clone(Attribute.bold, null) : Attribute.bold);
                }
              }, active: isBold),
              sub(Icons.format_italic, 'Italic', () {
                if (!_titleFocusNode.hasFocus) {
                  _quillController.formatSelection(isItalic ? Attribute.clone(Attribute.italic, null) : Attribute.italic);
                }
              }, active: isItalic),
              sub(Icons.format_underlined, 'Underline', () {
                if (!_titleFocusNode.hasFocus) {
                  _quillController.formatSelection(isUnderline ? Attribute.clone(Attribute.underline, null) : Attribute.underline);
                }
              }, active: isUnderline),
              sub(Icons.format_strikethrough, 'Strikethrough', () {
                if (!_titleFocusNode.hasFocus) {
                  _quillController.formatSelection(isStrike ? Attribute.clone(Attribute.strikeThrough, null) : Attribute.strikeThrough);
                }
              }, active: isStrike),
              sub(Icons.code_rounded, 'Inline Code', () => _quillController.formatSelection(isCode ? Attribute.clone(Attribute.inlineCode, null) : Attribute.inlineCode), active: isCode),
            ],
          );
        case 'color':
          final textColors = [
            const Color(0xFF000000),
            const Color(0xFFEF4444),
            const Color(0xFFF97316),
            const Color(0xFFEAB308),
            const Color(0xFF22C55E),
            const Color(0xFF06B6D4),
            const Color(0xFF3B82F6),
            const Color(0xFF6366F1),
            const Color(0xFF8B5CF6),
            const Color(0xFFEC4899),
            const Color(0xFF6B7280),
            const Color(0xFFFFFFFF),
          ];
          final highlights = [
            const Color(0xFFFFFF00),
            const Color(0xFFADFF2F),
            const Color(0xFF87CEEB),
            const Color(0xFFFFB6C1),
            const Color(0xFFFFD700),
            const Color(0xFFFFA07A),
            const Color(0xFF98FB98),
            const Color(0xFFDDA0DD),
            const Color(0xFFE2E8F0),
            const Color(0xFFFFC0CB),
          ];
          if (_activeColorMode == null) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _activeColorMode = 'text';
                      _showCustomColorPicker = false;
                    });
                    _updateCustomColorPickerFromSelection();
                  },
                  icon: Icon(Icons.format_color_text, color: theme.colorScheme.primary),
                  label: Text('Text Color', style: TextStyle(color: theme.colorScheme.onSurface)),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _activeColorMode = 'highlight';
                      _showCustomColorPicker = false;
                    });
                    _updateCustomColorPickerFromSelection();
                  },
                  icon: Icon(Icons.highlight, color: theme.colorScheme.primary),
                  label: Text('Highlight Color', style: TextStyle(color: theme.colorScheme.onSurface)),
                ),
              ],
            );
          } else {
            final colorsToUse = _activeColorMode == 'text' ? textColors : highlights;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      onPressed: () => setState(() {
                        _activeColorMode = null;
                        _showCustomColorPicker = false;
                      }),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Tooltip(
                              message: 'Clear Color',
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  _applyColor(null);
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.shade400),
                                  ),
                                  child: const Icon(Icons.format_color_reset_rounded, size: 16, color: Colors.red),
                                ),
                              ),
                            ),
                            ...colorsToUse.map((c) {
                              final isSelected = _getCurrentSelectedColor() == c;
                              return GestureDetector(
                                onTap: () {
                                  _applyColor(c);
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : (c == Colors.white ? Colors.grey.shade300 : Colors.transparent),
                                      width: isSelected ? 2.5 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.4), blurRadius: 4)]
                                        : null,
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check,
                                          size: 14,
                                          color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                        )
                                      : null,
                                ),
                              );
                            }),
                            Tooltip(
                              message: 'Custom Color',
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => setState(() {
                                  _showCustomColorPicker = !_showCustomColorPicker;
                                }),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _showCustomColorPicker ? theme.colorScheme.primary : Colors.transparent,
                                    border: Border.all(color: theme.colorScheme.primary),
                                  ),
                                  child: Icon(
                                    Icons.palette_outlined,
                                    size: 16,
                                    color: _showCustomColorPicker
                                        ? Colors.white
                                        : theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_showCustomColorPicker) ...[
                  const Divider(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: _buildInlineCustomColorPicker(theme, isDark),
                  ),
                ],
              ],
            );
          }
        case 'heading':
          return Row(
            children: [
              subText('H1', 'Heading 1', () => _quillController.formatSelection(isH1 ? Attribute.clone(Attribute.header, null) : Attribute.h1), active: isH1),
              subText('H2', 'Heading 2', () => _quillController.formatSelection(isH2 ? Attribute.clone(Attribute.header, null) : Attribute.h2), active: isH2),
              subText('H3', 'Heading 3', () => _quillController.formatSelection(isH3 ? Attribute.clone(Attribute.header, null) : Attribute.h3), active: isH3),
              subText('H4', 'Heading 4', () => _quillController.formatSelection(isH4 ? Attribute.clone(Attribute.header, null) : Attribute.h4), active: isH4),
            ],
          );
        case 'align':
          return Row(
            children: [
              sub(Icons.format_align_left_rounded, 'Align Left', () => _quillController.formatSelection(Attribute.leftAlignment), active: isAlignLeft),
              sub(Icons.format_align_center_rounded, 'Align Center', () => _quillController.formatSelection(Attribute.centerAlignment), active: isAlignCenter),
              sub(Icons.format_align_right_rounded, 'Align Right', () => _quillController.formatSelection(Attribute.rightAlignment), active: isAlignRight),
              sub(Icons.format_align_justify_rounded, 'Justify', () => _quillController.formatSelection(Attribute.justifyAlignment), active: isAlignJustify),
            ],
          );
        case 'lists':
          return Row(
            children: [
              sub(Icons.format_list_bulleted, 'Bullet List', () => _quillController.formatSelection(isBullet ? Attribute.clone(Attribute.list, null) : Attribute.ul), active: isBullet),
              sub(Icons.format_list_numbered, 'Numbered List', () => _quillController.formatSelection(isOrdered ? Attribute.clone(Attribute.list, null) : Attribute.ol), active: isOrdered),
              sub(Icons.check_box_outlined, 'Checklist', () => _quillController.formatSelection(isChecklist ? Attribute.clone(Attribute.list, null) : Attribute.unchecked), active: isChecklist),
              sub(Icons.format_quote_rounded, 'Blockquote', () => _quillController.formatSelection(isBlockquote ? Attribute.clone(Attribute.blockQuote, null) : Attribute.blockQuote), active: isBlockquote),
            ],
          );
        case 'insert':
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                sub(Icons.image_outlined, 'Insert Image', _insertImageDialog),
                sub(Icons.horizontal_rule_rounded, 'Divider', () {
                  final index = _quillController.selection.baseOffset;
                  final insertIndex = index >= 0 ? index : _quillController.document.length - 1;
                  final length = _quillController.selection.extentOffset - index;
                  _quillController.replaceText(
                    insertIndex,
                    length >= 0 ? length : 0,
                    '\n---\n',
                    TextSelection.collapsed(offset: insertIndex + 5),
                  );
                }),
                sub(Icons.data_object_rounded, 'Code Block', () => _quillController.formatSelection(isCodeBlock ? Attribute.clone(Attribute.codeBlock, null) : Attribute.codeBlock), active: isCodeBlock),
                sub(Icons.mic_outlined, 'Voice Note', _toggleVoiceRecording),
                sub(Icons.mic_none_outlined, 'Dictation (STT)', _toggleSpeechToText, active: _isSpeechListening),
                sub(Icons.draw_outlined, 'Drawing', () => _openDrawingCanvas()),
              ],
            ),
          );
        case 'indent':
          return Row(
            children: [
              sub(Icons.format_indent_increase_rounded, 'Indent', () => _quillController.indentSelection(true)),
              sub(Icons.format_indent_decrease_rounded, 'Outdent', () => _quillController.indentSelection(false)),
              sub(Icons.format_line_spacing_rounded, 'Line Break', () {
                final index = _quillController.selection.baseOffset;
                final insertIndex = index >= 0 ? index : _quillController.document.length - 1;
                final length = _quillController.selection.extentOffset - index;
                _quillController.replaceText(
                  insertIndex,
                  length >= 0 ? length : 0,
                  '\n',
                  TextSelection.collapsed(offset: insertIndex + 1),
                );
              }),
            ],
          );
      }
      return const SizedBox.shrink();
    }

    Widget? previewBanner;
    if (_activeToolbarGroup == 'color' && _activeColorMode != null) {
      final selection = _quillController.selection;
      final hasSelection = selection.baseOffset != selection.extentOffset;
      if (!hasSelection) {
        final previewColor = _getCurrentSelectedColor();
        final isHighlight = _activeColorMode == 'highlight';
        previewBanner = Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1B2C) : const Color(0xFFF3F1FA),
            border: isAtBottom
                ? Border(bottom: BorderSide(color: borderColor))
                : Border(top: BorderSide(color: borderColor)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Preview: ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isHighlight ? previewColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Sample Text',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isHighlight
                        ? (previewColor.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                        : (previewColor == Colors.transparent
                            ? (isDark ? Colors.white : Colors.black)
                            : previewColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(Select text in the editor to apply)',
                style: TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: isAtBottom
            ? Border(top: BorderSide(color: borderColor))
            : Border(bottom: BorderSide(color: borderColor)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: isAtBottom ? const Offset(0, -2) : const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: isAtBottom
            ? [
                if (previewBanner != null) previewBanner,
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: _activeToolbarGroup == null
                      ? const SizedBox.shrink()
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1C1829).withOpacity(0.9)
                                : const Color(0xFFF8F6FF),
                            border: Border(
                              bottom: BorderSide(color: borderColor),
                            ),
                          ),
                          child: subRow(),
                        ),
                ),
                Row(
                  children: groups
                      .map((g) => groupBtn(g.$1, g.$2, g.$3))
                      .toList(),
                ),
              ]
            : [
                if (previewBanner != null) previewBanner,
                Row(
                  children: groups
                      .map((g) => groupBtn(g.$1, g.$2, g.$3))
                      .toList(),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: _activeToolbarGroup == null
                      ? const SizedBox.shrink()
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1C1829).withOpacity(0.9)
                                : const Color(0xFFF8F6FF),
                            border: Border(
                              top: BorderSide(color: borderColor),
                            ),
                          ),
                          child: subRow(),
                        ),
                ),
              ],
      ),
    );
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  Widget _buildFocusModeBody() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final isMobile = ResponsiveHelper.isMobile(context);
    
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
                    onPressed: () { _saveNote(); context.pop(); },
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
                            onPressed: _toggleFullScreen,
                            style: IconButton.styleFrom(
                              foregroundColor: isDark ? const Color(0xFF8B5CF6) : const Color(0xFF7C3AED),
                            ),
                          ),
                          IconButton(
                            icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                            color: _isPinned ? theme.colorScheme.secondary : null,
                            tooltip: _isPinned ? 'Unpin Note' : 'Pin Note',
                            onPressed: () {
                              setState(() {
                                _isPinned = !_isPinned;
                                _isDirty = true;
                              });
                              _saveNote(isAutoSave: true);
                            },
                          ),
                          IconButton(
                            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
                            color: _isFavorite ? const Color(0xFFF43F5E) : null,
                            tooltip: _isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                            onPressed: () {
                              setState(() {
                                _isFavorite = !_isFavorite;
                                _isDirty = true;
                              });
                              _saveNote(isAutoSave: true);
                            },
                          ),
                          PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'save') _saveNote();
                              if (val == 'share') _handleShare(context);
                              if (val == 'md') _handleExportMarkdown(context);
                              if (val == 'pdf') _handlePrintPdf(context);
                              if (val == 'delete') _handleDeleteNote(context);
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'save', child: Row(children: [Icon(Icons.save_outlined), SizedBox(width: 8), Text('Save Note')])),
                              const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share_outlined), SizedBox(width: 8), Text('Share Note')])),
                              const PopupMenuItem(value: 'md', child: Row(children: [Icon(Icons.article_outlined), SizedBox(width: 8), Text('Export MD')])),
                              const PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.picture_as_pdf_outlined), SizedBox(width: 8), Text('Export PDF')])),
                              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red), SizedBox(width: 8), Text('Delete Note', style: TextStyle(color: Colors.red))])),
                            ],
                            icon: const Icon(Icons.more_vert_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isKeyboardOpen && !isMobile) _buildGentleNoteToolbar(theme, isDark),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
              child: TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 4, 28, 0),
                child: DefaultTextStyle(
                  style: TextStyle(
                    fontFamily: _noteType == NoteType.mixed
                        ? 'Georgia'
                        : (_noteType == NoteType.code ? 'Courier' : 'Inter'),
                    fontSize: 16,
                    height: _noteType == NoteType.mixed ? 1.75 : 1.5,
                    color: isDark ? Colors.white.withOpacity(0.92) : const Color(0xFF1A1A2E),
                  ),
                  child: Actions(
                    actions: <Type, Action<Intent>>{
                      PasteTextIntent: CallbackAction<PasteTextIntent>(
                        onInvoke: (intent) {
                          Clipboard.getData(Clipboard.kTextPlain).then((data) {
                            if (data != null && data.text != null) {
                              _handlePasteText(data.text!);
                            }
                          });
                          return null;
                        },
                      ),
                    },
                    child: QuillEditor.basic(
                      key: const ValueKey('focus_mode_quill_editor'),
                      controller: _quillController,
                      focusNode: _editorFocusNode,
                      config: QuillEditorConfig(
                        placeholder: _noteType == NoteType.mixed ? 'Write something beautiful...' : 'Start writing...',
                        autoFocus: false,
                        expands: true,
                        padding: EdgeInsets.zero,
                        embedBuilders: [
                          ImageEmbedBuilder(),
                          AudioEmbedBuilder(getAttachments: () => _attachments),
                          HorizontalRuleEmbedBuilder(key: 'horizontal-rule'),
                          HorizontalRuleEmbedBuilder(key: 'divider'),
                        ],
                        customActions: <Type, Action<Intent>>{
                          PasteTextIntent: CallbackAction<PasteTextIntent>(
                            onInvoke: (intent) {
                              Clipboard.getData(Clipboard.kTextPlain).then((data) {
                                if (data != null && data.text != null) {
                                  _handlePasteText(data.text!);
                                }
                              });
                              return null;
                            },
                          ),
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (isMobile || (isKeyboardOpen && !isMobile))
              _buildGentleNoteToolbar(theme, isDark, isAtBottom: true),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenBody() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = _previewBgColor ?? (isDark ? const Color(0xFF0D0B18) : Colors.white);
    final isMarkdownPreview = _noteType == NoteType.markdown && _isPreviewMode;

    return Scaffold(
      backgroundColor: _previewBgImagePath != null ? Colors.transparent : bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            if (_previewBgImagePath != null)
              Positioned.fill(
                child: Image.file(io.File(_previewBgImagePath!), fit: BoxFit.cover),
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
                    _titleController.text.isEmpty ? 'Untitled Note' : _titleController.text,
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
                                data: QuillMarkdownConverter.deltaToMarkdown(jsonEncode(_quillController.document.toDelta().toJson())),
                                attachments: _attachments,
                                fontFamily: _currentFontFamily,
                              ),
                            ),
                          ],
                        )
                      : _buildEditorBody(context),
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
                        _quillController.readOnly = _isPreviewMode;
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
                    onPressed: _toggleFullScreen,
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

  Widget _buildEditorBody(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final showFolderOptions = !isKeyboardOpen || !_editorFocusNode.hasFocus;
    final isMobile = ResponsiveHelper.isMobile(context);

    if (_isPreviewMode) {
      final bgColor = _previewBgColor ?? theme.scaffoldBackgroundColor;
      final markdown = QuillMarkdownConverter.deltaToMarkdown(jsonEncode(_quillController.document.toDelta().toJson()));
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
              if (!_isFullScreen) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Text(
                    _titleController.text.isEmpty ? 'Untitled Note' : _titleController.text,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                ),
                Divider(height: 1, color: isDark ? const Color(0xFF1E1A30) : const Color(0xFFE9E6F5)),
              ],
              Expanded(
                child: Stack(
                  children: [
                    if (_previewStyle != PreviewStyle.plain)
                      Positioned.fill(
                        child: CustomPaint(painter: PreviewStylePainter(_previewStyle)),
                      ),
                    Padding(
                      padding: styleContentPadding(_previewStyle),
                      child: MarkdownWidget(
                        data: markdown.isEmpty ? '*Nothing here yet…*' : markdown,
                        attachments: _attachments,
                        fontFamily: _currentFontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Editable Pane
    final bgColor = _previewBgColor ?? theme.scaffoldBackgroundColor;
    final editWidget = Stack(
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
          children: [
            if (!isKeyboardOpen && !isMobile)
              _buildGentleNoteToolbar(theme, isDark)
            else
              const SizedBox.shrink(),
            Expanded(
              child: Padding(
                padding: styleContentPadding(_previewStyle).add(const EdgeInsets.all(16.0)),
                child: DefaultTextStyle(
                  style: TextStyle(
                    fontFamily: _noteType == NoteType.mixed
                        ? 'Georgia'
                        : (_noteType == NoteType.code ? 'Courier' : 'Inter'),
                    fontSize: 16,
                    height: _noteType == NoteType.mixed ? 1.75 : 1.5,
                    color: isDark ? Colors.white.withOpacity(0.92) : const Color(0xFF1A1A2E),
                  ),
                  child: Actions(
                    actions: <Type, Action<Intent>>{
                      PasteTextIntent: CallbackAction<PasteTextIntent>(
                        onInvoke: (intent) {
                          Clipboard.getData(Clipboard.kTextPlain).then((data) {
                            if (data != null && data.text != null) {
                              _handlePasteText(data.text!);
                            }
                          });
                          return null;
                        },
                      ),
                    },
                    child: QuillEditor.basic(
                      key: const ValueKey('standard_mode_quill_editor'),
                      controller: _quillController,
                      focusNode: _editorFocusNode,
                      config: QuillEditorConfig(
                        placeholder: _noteType == NoteType.mixed ? 'Write something beautiful...' : 'Start writing...',
                        autoFocus: false,
                        expands: true,
                        padding: EdgeInsets.zero,
                        embedBuilders: [
                          ImageEmbedBuilder(),
                          AudioEmbedBuilder(getAttachments: () => _attachments),
                          HorizontalRuleEmbedBuilder(key: 'horizontal-rule'),
                          HorizontalRuleEmbedBuilder(key: 'divider'),
                        ],
                        customActions: <Type, Action<Intent>>{
                          PasteTextIntent: CallbackAction<PasteTextIntent>(
                            onInvoke: (intent) {
                              Clipboard.getData(Clipboard.kTextPlain).then((data) {
                                if (data != null && data.text != null) {
                                  _handlePasteText(data.text!);
                                }
                              });
                              return null;
                            },
                          ),
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 12,
          right: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_showBgPicker) _buildBgColorPicker(theme),
              const SizedBox(height: 6),
              FloatingActionButton.small(
                heroTag: 'bgColorBtn',
                onPressed: () => setState(() => _showBgPicker = !_showBgPicker),
                backgroundColor: theme.colorScheme.surfaceVariant,
                foregroundColor: _previewBgColor != null
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                tooltip: 'Background Color',
                child: const Icon(Icons.palette_outlined, size: 18),
              ),
            ],
          ),
        ),
      ],
    );

    if (_noteType == NoteType.markdown) {
      final previewWidget = Stack(
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
          Padding(
            padding: styleContentPadding(_previewStyle),
            child: MarkdownWidget(
              data: QuillMarkdownConverter.deltaToMarkdown(jsonEncode(_quillController.document.toDelta().toJson())),
              attachments: _attachments,
              fontFamily: _currentFontFamily,
            ),
          ),
        ],
      );

      return Column(
        children: [
          if (showFolderOptions)
            _buildLayoutSelector()
          else
            const SizedBox.shrink(),
          if (showFolderOptions)
            const Divider(height: 1)
          else
            const SizedBox.shrink(),
          Expanded(
            child: _markdownLayout == MarkdownLayoutMode.editOnly
                ? editWidget
                : _markdownLayout == MarkdownLayoutMode.previewOnly
                    ? previewWidget
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 720) {
                            return Row(
                              children: [
                                Expanded(child: editWidget),
                                const VerticalDivider(width: 1, thickness: 1),
                                Expanded(child: previewWidget),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                Expanded(child: editWidget),
                                const Divider(height: 1, thickness: 1),
                                Expanded(child: previewWidget),
                              ],
                            );
                          }
                        },
                      ),
          ),
        ],
      );
    }

    return editWidget;
  }

  // ── Voice Note Recording ──────────────────────────────────────────────────
  void _toggleVoiceRecording() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoiceRecorderBottomSheet(
        noteId: _noteId,
        onAttach: (attachment, embedBlock) {
          setState(() {
            _attachments = [..._attachments, attachment];
            _isDirty = true;
          });

          final index = _quillController.selection.baseOffset;
          final insertIndex = index >= 0 ? index : _quillController.document.length - 1;
          final length = _quillController.selection.extentOffset - index;
          _quillController.replaceText(
            insertIndex,
            length >= 0 ? length : 0,
            embedBlock,
            TextSelection.collapsed(offset: insertIndex + 1),
          );
          _saveNote(isAutoSave: true);
        },
      ),
    );
  }

  // ── Drawing Canvas ────────────────────────────────────────────────────────
  Future<void> _openDrawingCanvas() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => DrawingCanvasScreen(
          onSave: (strokes, pngBytes) async {
            if (pngBytes != null) {
              final dir = await getApplicationDocumentsDirectory();
              final fileName = 'drawing_${const Uuid().v4()}.png';
              final file = io.File('${dir.path}/$fileName');
              await file.writeAsBytes(pngBytes);

              final attachmentId = const Uuid().v4();
              final newAttachment = AttachmentModel(
                id: attachmentId,
                noteId: _noteId,
                type: AttachmentType.image,
                name: 'Drawing',
                pathOrUrl: 'file://${file.path}',
                createdAt: DateTime.now(),
              );
              if (mounted) {
                setState(() {
                  _attachments = [..._attachments, newAttachment];
                  _isDirty = true;
                });
                
                final index = _quillController.selection.baseOffset;
                final insertIndex = index >= 0 ? index : _quillController.document.length - 1;
                final length = _quillController.selection.extentOffset - index;
                _quillController.replaceText(
                  insertIndex,
                  length >= 0 ? length : 0,
                  BlockEmbed.image('file://${file.path}'),
                  TextSelection.collapsed(offset: insertIndex + 1),
                );
                _markDirty();
                _saveNote(isAutoSave: true);
              }
            }
          },
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
          Icon(icon, size: 18,
              color: _previewStyle == style ? const Color(0xFF8B5CF6) : null),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontWeight: _previewStyle == style ? FontWeight.bold : FontWeight.normal,
                  color: _previewStyle == style ? const Color(0xFF8B5CF6) : null)),
        ],
      ),
    );
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
                          controller: _titleController,
                          focusNode: _titleFocusNode,
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
                      icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                      color: _isPinned ? theme.colorScheme.secondary : const Color(0xFF8B5CF6),
                      tooltip: _isPinned ? 'Unpin Note' : 'Pin Note',
                      onPressed: () {
                        setState(() {
                          _isPinned = !_isPinned;
                          _isDirty = true;
                        });
                        _saveNote(isAutoSave: true);
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
                          _quillController.readOnly = _isPreviewMode;
                        });
                      },
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF8B5CF6)),
                      onSelected: (val) {
                        if (val == 'save') _saveNote();
                        if (val == 'share') _handleShare(context);
                        if (val == 'delete') _handleDeleteNote(context);
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
                                onTap: () => _handlePrintPdf(context),
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
                                icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: _isFavorite ? const Color(0xFFF43F5E) : const Color(0xFF8B5CF6),
                                tooltip: _isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                                onTap: () {
                                  setState(() {
                                    _isFavorite = !_isFavorite;
                                    _isDirty = true;
                                  });
                                  _saveNote(isAutoSave: true);
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

  // ══════════════════════════════════════════════════════════════════════════
  //  NEW LAYOUT VARIANT BUILDERS
  // ══════════════════════════════════════════════════════════════════════════

  // ── Minimal Layout ────────────────────────────────────────────────────────
  Widget _buildMinimalLayout() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final isMobile = ResponsiveHelper.isMobile(context);
    final accent = theme.colorScheme.primary;
    final bg = isDark ? const Color(0xFF0D0B18) : const Color(0xFFFBFAFF);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Slim top bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    onPressed: () { _saveNote(); if (Navigator.of(context).canPop()) Navigator.of(context).pop(); else context.go('/home'); },
                    style: IconButton.styleFrom(foregroundColor: accent),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 18),
                    color: _isPinned ? theme.colorScheme.secondary : accent,
                    onPressed: () { setState(() { _isPinned = !_isPinned; _isDirty = true; }); _saveNote(isAutoSave: true); },
                  ),
                  IconButton(
                    icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, size: 18),
                    color: _isFavorite ? const Color(0xFFF43F5E) : accent,
                    onPressed: () { setState(() { _isFavorite = !_isFavorite; _isDirty = true; }); _saveNote(isAutoSave: true); },
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, size: 18, color: accent),
                    onSelected: (val) {
                      if (val == 'save') _saveNote();
                      if (val == 'share') _handleShare(context);
                      if (val == 'md') _handleExportMarkdown(context);
                      if (val == 'pdf') _handlePrintPdf(context);
                      if (val == 'delete') _handleDeleteNote(context);
                      if (val == 'focus') setState(() => _isFocusMode = true);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'save', child: Row(children: [Icon(Icons.save_outlined), SizedBox(width: 8), Text('Save Note')])),
                      const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share_outlined), SizedBox(width: 8), Text('Share Note')])),
                      const PopupMenuItem(value: 'md', child: Row(children: [Icon(Icons.article_outlined), SizedBox(width: 8), Text('Export MD')])),
                      const PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.picture_as_pdf_outlined), SizedBox(width: 8), Text('Export PDF')])),
                      const PopupMenuItem(value: 'focus', child: Row(children: [Icon(Icons.center_focus_strong_rounded), SizedBox(width: 8), Text('Focus Mode')])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red), SizedBox(width: 8), Text('Delete Note', style: TextStyle(color: Colors.red))])),
                    ],
                  ),
                ],
              ),
            ),

            // ── Large inline title ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1.2,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
                decoration: InputDecoration(
                  hintText: 'Untitled Note',
                  hintStyle: TextStyle(fontFamily: 'Outfit', fontSize: 26, fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF3D3557) : const Color(0xFFD1CBE8)),
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
                child: Row(children: _buildMinimalMetaChips(theme, isDark)),
              ),
            ),

            Divider(height: 16, indent: 24, endIndent: 24,
                color: isDark ? const Color(0xFF252234) : const Color(0xFFE9E6F5)),

            // ── Editor body ────────────────────────────────────────────────
            Expanded(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: _buildEditorBody(context),
            )),

            // ── Tags bar ──────────────────────────────────────────────────
            Visibility(
              visible: !isKeyboardOpen || _tagsFocusNode.hasFocus,
              maintainState: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Divider(height: 1, color: isDark ? const Color(0xFF252234) : const Color(0xFFE9E6F5)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                    child: Row(
                      children: [
                        Icon(Icons.local_offer_outlined, size: 16, color: accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _tagController,
                            focusNode: _tagsFocusNode,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Add tags…',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Floating compact toolbar ───────────────────────────────────
            if (!isKeyboardOpen || isMobile)
              _buildMinimalFloatingToolbar(theme, isDark),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMinimalMetaChips(ThemeData theme, bool isDark) {
    final accent = theme.colorScheme.primary;
    final folders = ref.read(foldersProvider);
    final folder = folders.cast<FolderModel?>().firstWhere((f) => f?.id == _selectedFolderId, orElse: () => null);
    return [
      _metaChip(
        icon: Icons.folder_outlined,
        label: folder?.name ?? 'No Folder',
        color: folder?.color ?? (isDark ? const Color(0xFF3D3557) : const Color(0xFFD1CBE8)),
        isDark: isDark,
        accent: accent,
      ),
      const SizedBox(width: 8),
      _metaChip(
        icon: _noteType.icon,
        label: _noteType.displayName,
        color: accent,
        isDark: isDark,
        accent: accent,
      ),
    ];
  }

  Widget _metaChip({required IconData icon, required String label, required Color color, required bool isDark, required Color accent}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
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

  Widget _buildMinimalFloatingToolbar(ThemeData theme, bool isDark) {
    final accent = theme.colorScheme.primary;
    final bg = isDark ? const Color(0xFF1C1829).withOpacity(0.95) : Colors.white.withOpacity(0.95);
    final border = isDark ? const Color(0xFF2E2845) : const Color(0xFFE8E4F5);
    final isActive = _activeToolbarGroup != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1829) : const Color(0xFFF8F6FF),
                border: Border(top: BorderSide(color: border)),
              ),
              child: _buildSubRow(theme, isDark, accent),
            ),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: bg,
              border: Border(top: BorderSide(color: border)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ('format', Icons.format_bold, 'Format'),
                ('color', Icons.palette_outlined, 'Color'),
                ('heading', Icons.title_rounded, 'Heading'),
                ('lists', Icons.format_list_bulleted, 'Lists'),
                ('insert', Icons.add_box_outlined, 'Insert'),
              ].map((g) {
                final isGroupActive = _activeToolbarGroup == g.$1;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _activeToolbarGroup = (isGroupActive ? null : g.$1);
                      if (_activeToolbarGroup != 'color') { _activeColorMode = null; _showCustomColorPicker = false; }
                    }),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(g.$2, size: 20, color: isGroupActive ? accent : theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 2),
                        Text(g.$3, style: TextStyle(fontSize: 8, color: isGroupActive ? accent : theme.colorScheme.onSurfaceVariant.withOpacity(0.7))),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Notebook Layout ───────────────────────────────────────────────────────
  Widget _buildNotebookLayout() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final sidebarBg = isDark ? const Color(0xFF1C1829) : Colors.white;
    final mainBg = isDark ? const Color(0xFF13111C) : const Color(0xFFF8F6FF);
    final border = isDark ? const Color(0xFF2E2845) : const Color(0xFFE8E4F5);
    final folders = ref.watch(foldersProvider);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    // On mobile hide sidebar when keyboard is open (no room)
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = screenWidth < 400 ? 160.0 : 200.0;

    Widget sidebar = SizedBox(
      width: sidebarWidth,
      child: Container(
        color: sidebarBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Back + save row ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
                    onPressed: () {
                      _saveNote();
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/home');
                      }
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
                    onPressed: _saveNote,
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
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        maxLines: 3,
                        minLines: 1,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                          height: 1.3,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Untitled',
                          hintStyle: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFF3D3557)
                                : const Color(0xFFD1CBE8),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),

                    Divider(height: 1, indent: 14, endIndent: 14, color: border),
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
                    // Folder dropdown — constrained to sidebar width
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedFolderId,
                          isExpanded: true,
                          isDense: true,
                          hint: Row(
                            children: [
                              Icon(Icons.folder_outlined,
                                  size: 12,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text('No Folder',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.5))),
                              ),
                            ],
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Row(children: [
                                const Icon(Icons.folder_off_outlined, size: 12),
                                const SizedBox(width: 4),
                                const Flexible(
                                    child: Text('No Folder',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 11))),
                              ]),
                            ),
                            ...folders.map((f) => DropdownMenuItem<String?>(
                                  value: f.id,
                                  child: Row(children: [
                                    Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                            color: f.color,
                                            shape: BoxShape.circle)),
                                    const SizedBox(width: 6),
                                    Flexible(
                                        child: Text(f.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 11))),
                                  ]),
                                )),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedFolderId = val;
                              _isDirty = true;
                            });
                          },
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
                          value: _noteType,
                          isExpanded: true,
                          isDense: true,
                          items: NoteType.values
                              .map((t) => DropdownMenuItem<NoteType>(
                                    value: t,
                                    child: Row(children: [
                                      Icon(t.icon, size: 12, color: accent),
                                      const SizedBox(width: 5),
                                      Flexible(
                                          child: Text(t.displayName,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 11))),
                                    ]),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _noteType = val;
                                _isDirty = true;
                              });
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Divider(height: 1, indent: 14, endIndent: 14, color: border),
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
                          Icon(Icons.local_offer_outlined,
                              size: 12, color: accent.withOpacity(0.7)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: TextField(
                              controller: _tagController,
                              focusNode: _tagsFocusNode,
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
                    Divider(height: 1, indent: 14, endIndent: 14, color: border),
                    const SizedBox(height: 4),

                    // Pin / Fave / More actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isPinned
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                              size: 16,
                            ),
                            color: _isPinned ? accent : null,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                                minWidth: 30, minHeight: 30),
                            onPressed: () {
                              setState(() {
                                _isPinned = !_isPinned;
                                _isDirty = true;
                              });
                              _saveNote(isAutoSave: true);
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 16,
                            ),
                            color: _isFavorite
                                ? const Color(0xFFF43F5E)
                                : null,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                                minWidth: 30, minHeight: 30),
                            onPressed: () {
                              setState(() {
                                _isFavorite = !_isFavorite;
                                _isDirty = true;
                              });
                              _saveNote(isAutoSave: true);
                            },
                          ),
                          const Spacer(),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_horiz_rounded,
                                size: 16, color: accent),
                            padding: const EdgeInsets.all(4),
                            onSelected: (val) {
                              if (val == 'share') _handleShare(context);
                              if (val == 'md') _handleExportMarkdown(context);
                              if (val == 'pdf') _handlePrintPdf(context);
                              if (val == 'delete') _handleDeleteNote(context);
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                  value: 'share',
                                  child: Row(children: [
                                    Icon(Icons.share_outlined),
                                    SizedBox(width: 8),
                                    Text('Share')
                                  ])),
                              const PopupMenuItem(
                                  value: 'md',
                                  child: Row(children: [
                                    Icon(Icons.article_outlined),
                                    SizedBox(width: 8),
                                    Text('Export MD')
                                  ])),
                              const PopupMenuItem(
                                  value: 'pdf',
                                  child: Row(children: [
                                    Icon(Icons.picture_as_pdf_outlined),
                                    SizedBox(width: 8),
                                    Text('Export PDF')
                                  ])),
                              const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(children: [
                                    Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete',
                                        style: TextStyle(color: Colors.red))
                                  ])),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Widget editorPanel = Column(
      children: [
        _buildGentleNoteToolbar(theme, isDark),
        Expanded(child: _buildEditorBody(context)),
        if (isKeyboardOpen)
          _buildGentleNoteToolbar(theme, isDark, isAtBottom: true),
      ],
    );

    // On very narrow screens (e.g. small phones), hide sidebar when keyboard opens
    final showSidebar = !isKeyboardOpen || screenWidth >= 500;

    return Scaffold(
      backgroundColor: mainBg,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showSidebar) ...[
              sidebar,
              Container(width: 1, color: border),
            ],
            Expanded(child: editorPanel),
          ],
        ),
      ),
    );
  }

  // ── Zen Layout ────────────────────────────────────────────────────────────

  Widget _buildZenLayout() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final bg = isDark ? const Color(0xFF090B16) : const Color(0xFFFDFCFF);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: bg,
      body: GestureDetector(
        onTap: () => setState(() => _zenChromeVisible = !_zenChromeVisible),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: Stack(
            children: [
              // ── Editor fills entire screen ─────────────────────────────
              Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 48, 32, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _titleController,
                            focusNode: _titleFocusNode,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              height: 1.2,
                              color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF111827),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Begin…',
                              hintStyle: TextStyle(fontFamily: 'Outfit', fontSize: 28, fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFF2E2845) : const Color(0xFFE9E6F5)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(child: DefaultTextStyle(
                            style: TextStyle(
                              fontFamily: _noteType == NoteType.mixed ? 'Georgia' : (_noteType == NoteType.code ? 'Courier' : 'Inter'),
                              fontSize: 16,
                              height: 1.7,
                              color: isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF1A1A2E),
                            ),
                            child: QuillEditor.basic(
                              key: const ValueKey('zen_quill_editor'),
                              controller: _quillController,
                              focusNode: _editorFocusNode,
                              config: QuillEditorConfig(
                                placeholder: 'Write freely…',
                                autoFocus: false,
                                expands: true,
                                padding: EdgeInsets.zero,
                                embedBuilders: [
                                  ImageEmbedBuilder(),
                                  AudioEmbedBuilder(getAttachments: () => _attachments),
                                  HorizontalRuleEmbedBuilder(key: 'horizontal-rule'),
                                  HorizontalRuleEmbedBuilder(key: 'divider'),
                                ],
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                  if (isKeyboardOpen)
                    _buildGentleNoteToolbar(theme, isDark, isAtBottom: true),
                ],
              ),

              // ── Fade-in chrome overlay ─────────────────────────────────
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _zenChromeVisible ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: !_zenChromeVisible,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: bg.withOpacity(0.95),
                          border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF252234) : const Color(0xFFEEEBFF))),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                              onPressed: () { _saveNote(); if (Navigator.of(context).canPop()) Navigator.of(context).pop(); else context.go('/home'); },
                              style: IconButton.styleFrom(foregroundColor: accent),
                            ),
                            const Spacer(),
                            Text('Zen', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accent.withOpacity(0.6), letterSpacing: 1)),
                            const Spacer(),
                            IconButton(
                              icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 18),
                              color: _isPinned ? accent : accent.withOpacity(0.5),
                              onPressed: () { setState(() { _isPinned = !_isPinned; _isDirty = true; }); _saveNote(isAutoSave: true); },
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert_rounded, size: 18, color: accent.withOpacity(0.7)),
                              onSelected: (val) {
                                if (val == 'save') _saveNote();
                                if (val == 'share') _handleShare(context);
                                if (val == 'delete') _handleDeleteNote(context);
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'save', child: Row(children: [Icon(Icons.save_outlined), SizedBox(width: 8), Text('Save Note')])),
                                const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share_outlined), SizedBox(width: 8), Text('Share Note')])),
                                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red), SizedBox(width: 8), Text('Delete Note', style: TextStyle(color: Colors.red))])),
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
      ),
    );
  }

  // ── Cards Layout ──────────────────────────────────────────────────────────
  Widget _buildCardsLayout() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final bg = isDark ? const Color(0xFF13111C) : const Color(0xFFF5F3FF);
    final cardBg = isDark ? const Color(0xFF1E1B2C) : Colors.white;
    final border = isDark ? const Color(0xFF2E2845) : const Color(0xFFE8E4F5);
    final folders = ref.watch(foldersProvider);
    final folder = folders.cast<FolderModel?>().firstWhere((f) => f?.id == _selectedFolderId, orElse: () => null);
    final coverColor = folder?.color ?? accent;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final isMobile = ResponsiveHelper.isMobile(context);

    // Generate the note card header colour from colorHex
    Color headerColor;
    try {
      final hex = _colorHex.replaceAll('#', '');
      headerColor = hex == 'FFFFFF' || hex == 'ffffff'
          ? coverColor
          : Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      headerColor = coverColor;
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Color cover card ──────────────────────────────────────────
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
                        onPressed: () { _saveNote(); if (Navigator.of(context).canPop()) Navigator.of(context).pop(); else context.go('/home'); },
                        style: IconButton.styleFrom(foregroundColor: Colors.white),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 18),
                        color: Colors.white,
                        onPressed: () { setState(() { _isPinned = !_isPinned; _isDirty = true; }); _saveNote(isAutoSave: true); },
                      ),
                      IconButton(
                        icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, size: 18),
                        color: Colors.white,
                        onPressed: () { setState(() { _isFavorite = !_isFavorite; _isDirty = true; }); _saveNote(isAutoSave: true); },
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 18, color: Colors.white),
                        onSelected: (val) {
                          if (val == 'save') _saveNote();
                          if (val == 'share') _handleShare(context);
                          if (val == 'md') _handleExportMarkdown(context);
                          if (val == 'pdf') _handlePrintPdf(context);
                          if (val == 'delete') _handleDeleteNote(context);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'save', child: Row(children: [Icon(Icons.save_outlined), SizedBox(width: 8), Text('Save Note')])),
                          const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share_outlined), SizedBox(width: 8), Text('Share Note')])),
                          const PopupMenuItem(value: 'md', child: Row(children: [Icon(Icons.article_outlined), SizedBox(width: 8), Text('Export MD')])),
                          const PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.picture_as_pdf_outlined), SizedBox(width: 8), Text('Export PDF')])),
                          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                    child: TextField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
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
                        hintStyle: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Meta chips row ────────────────────────────────────────────
            Container(
              color: cardBg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Color picker chips
                    ...(['#FFFFFF', '#FEE2E2', '#FEF3C7', '#ECFDF5', '#E0F2FE', '#F3E8FF', '#FDF4FF']).map((c) {
                      final isSelected = _colorHex == c;
                      final col = c == '#FFFFFF' ? Colors.grey.shade300 : Color(int.parse('FF${c.replaceAll('#', '')}', radix: 16));
                      return GestureDetector(
                        onTap: () => setState(() { _colorHex = c; _isDirty = true; }),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: col,
                            shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? theme.colorScheme.onSurface : Colors.grey.shade400, width: isSelected ? 2 : 0.5),
                          ),
                        ),
                      );
                    }),
                    Container(width: 1, height: 18, color: border, margin: const EdgeInsets.symmetric(horizontal: 8)),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<NoteType>(
                        value: _noteType,
                        isDense: true,
                        items: NoteType.values.map((t) => DropdownMenuItem<NoteType>(value: t, child: Row(children: [Icon(t.icon, size: 13, color: accent), const SizedBox(width: 4), Text(t.displayName, style: const TextStyle(fontSize: 11))]))).toList(),
                        onChanged: (val) { if (val != null) setState(() { _noteType = val; _isDirty = true; }); },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(height: 1, color: border),

            // ── Main editor card ──────────────────────────────────────────
            Expanded(
              child: Container(
                color: cardBg,
                child: _buildEditorBody(context),
              ),
            ),

            // ── Tags bar ──────────────────────────────────────────────────
            Visibility(
              visible: !isKeyboardOpen || _tagsFocusNode.hasFocus,
              maintainState: true,
              child: Container(
                color: cardBg,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Icon(Icons.local_offer_outlined, size: 16, color: accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _tagController,
                        focusNode: _tagsFocusNode,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(hintText: 'Add tags…', border: InputBorder.none, contentPadding: EdgeInsets.zero),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom toolbar ─────────────────────────────────────────────
            if (isMobile || isKeyboardOpen)
              _buildGentleNoteToolbar(theme, isDark, isAtBottom: true)
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  // ── Shared sub-row helper (for Minimal toolbar) ───────────────────────────
  Widget _buildSubRow(ThemeData theme, bool isDark, Color accentColor) {
    final style = _quillController.getSelectionStyle();
    final isBold = !_titleFocusNode.hasFocus && style.containsKey(Attribute.bold.key);
    final isItalic = !_titleFocusNode.hasFocus && style.containsKey(Attribute.italic.key);
    final isUnderline = !_titleFocusNode.hasFocus && style.containsKey(Attribute.underline.key);
    final isStrike = !_titleFocusNode.hasFocus && style.containsKey(Attribute.strikeThrough.key);
    final isCode = style.containsKey(Attribute.inlineCode.key);
    final isH1 = style.attributes[Attribute.header.key]?.value == 1;
    final isH2 = style.attributes[Attribute.header.key]?.value == 2;
    final isH3 = style.attributes[Attribute.header.key]?.value == 3;
    final listVal = style.attributes[Attribute.list.key]?.value;
    final isBullet = listVal == 'bullet';
    final isOrdered = listVal == 'ordered';
    final isChecklist = listVal == 'checked' || listVal == 'unchecked';

    Widget sub(IconData icon, String tooltip, VoidCallback onTap, {bool active = false}) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: active ? accentColor.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: active ? accentColor : theme.colorScheme.onSurface),
          ),
        ),
      );
    }

    Widget subText(String text, String tooltip, VoidCallback onTap, {bool active = false}) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: active ? accentColor.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                color: active ? accentColor : theme.colorScheme.onSurface)),
          ),
        ),
      );
    }

    switch (_activeToolbarGroup) {
      case 'format':
        return Row(children: [
          sub(Icons.format_bold, 'Bold', () { if (!_titleFocusNode.hasFocus) _quillController.formatSelection(isBold ? Attribute.clone(Attribute.bold, null) : Attribute.bold); }, active: isBold),
          sub(Icons.format_italic, 'Italic', () { if (!_titleFocusNode.hasFocus) _quillController.formatSelection(isItalic ? Attribute.clone(Attribute.italic, null) : Attribute.italic); }, active: isItalic),
          sub(Icons.format_underlined, 'Underline', () { if (!_titleFocusNode.hasFocus) _quillController.formatSelection(isUnderline ? Attribute.clone(Attribute.underline, null) : Attribute.underline); }, active: isUnderline),
          sub(Icons.format_strikethrough, 'Strikethrough', () { if (!_titleFocusNode.hasFocus) _quillController.formatSelection(isStrike ? Attribute.clone(Attribute.strikeThrough, null) : Attribute.strikeThrough); }, active: isStrike),
          sub(Icons.code_rounded, 'Code', () => _quillController.formatSelection(isCode ? Attribute.clone(Attribute.inlineCode, null) : Attribute.inlineCode), active: isCode),
        ]);
      case 'color':
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: () => setState(() { _activeColorMode = 'text'; _showCustomColorPicker = false; }),
              icon: Icon(Icons.format_color_text, color: accentColor),
              label: Text('Text Color', style: TextStyle(color: theme.colorScheme.onSurface)),
            ),
            TextButton.icon(
              onPressed: () => setState(() { _activeColorMode = 'highlight'; _showCustomColorPicker = false; }),
              icon: Icon(Icons.highlight, color: accentColor),
              label: Text('Highlight', style: TextStyle(color: theme.colorScheme.onSurface)),
            ),
          ],
        );
      case 'heading':
        return Row(children: [
          subText('H1', 'Heading 1', () => _quillController.formatSelection(isH1 ? Attribute.clone(Attribute.header, null) : Attribute.h1), active: isH1),
          subText('H2', 'Heading 2', () => _quillController.formatSelection(isH2 ? Attribute.clone(Attribute.header, null) : Attribute.h2), active: isH2),
          subText('H3', 'Heading 3', () => _quillController.formatSelection(isH3 ? Attribute.clone(Attribute.header, null) : Attribute.h3), active: isH3),
        ]);
      case 'lists':
        return Row(children: [
          sub(Icons.format_list_bulleted, 'Bullet List', () => _quillController.formatSelection(isBullet ? Attribute.clone(Attribute.list, null) : Attribute.ul), active: isBullet),
          sub(Icons.format_list_numbered, 'Numbered List', () => _quillController.formatSelection(isOrdered ? Attribute.clone(Attribute.list, null) : Attribute.ol), active: isOrdered),
          sub(Icons.check_box_outlined, 'Checklist', () => _quillController.formatSelection(isChecklist ? Attribute.clone(Attribute.list, null) : Attribute.unchecked), active: isChecklist),
        ]);
      case 'insert':
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            sub(Icons.image_outlined, 'Insert Image', _insertImageDialog),
            sub(Icons.mic_outlined, 'Voice Note', _toggleVoiceRecording),
            sub(Icons.mic_none_outlined, 'Dictation', _toggleSpeechToText, active: _isSpeechListening),
            sub(Icons.draw_outlined, 'Drawing', _openDrawingCanvas),
          ]),
        );
    }
    return const SizedBox.shrink();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  MAIN BUILD — dispatches to layout variant
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);

    // Full-screen and focus modes bypass layout variants
    if (_isFullScreen) return _buildFullScreenBody();
    if (_isFocusMode) return _buildFocusModeBody();

    // Dispatch to selected layout variant
    switch (settings.editorLayout) {
      case EditorLayoutVariant.minimal:
        return _buildMinimalLayout();
      case EditorLayoutVariant.notebook:
        return _buildNotebookLayout();
      case EditorLayoutVariant.zen:
        return _buildZenLayout();
      case EditorLayoutVariant.cards:
        return _buildCardsLayout();
      case EditorLayoutVariant.journal:
        return _buildJournalLayout();
      case EditorLayoutVariant.scrapbook:
        return _buildScrapbookLayout();
      case EditorLayoutVariant.petal:
        return _buildPetalLayout();
      case EditorLayoutVariant.stardust:
        return _buildStardustLayout();
      case EditorLayoutVariant.classic:
        return _buildClassicLayout(theme, isDark);
    }
  }

  // ── Journal Layout ─────────────────────────────────────────────────────────
  Widget _buildJournalLayout() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final bg = isDark ? const Color(0xFF0F1A0A) : const Color(0xFFFFFDF5);
    final lineColor = isDark ? const Color(0xFF1E2D15) : const Color(0xFFE2EDD0);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final now = DateTime.now();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr = '${months[now.month - 1]} ${now.day}, ${now.year}';

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Date header ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: accent.withOpacity(isDark ? 0.18 : 0.09),
                border: Border(bottom: BorderSide(color: lineColor, width: 1)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () { _saveNote(); if (Navigator.of(context).canPop()) Navigator.of(context).pop(); else context.go('/home'); },
                    child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 13, color: accent),
                        const SizedBox(width: 5),
                        Text(dateStr, style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.save_outlined, size: 18, color: accent),
                    onPressed: _saveNote,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
            // ── Title ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                maxLines: 2,
                minLines: 1,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A2E08),
                  height: 1.2,
                ),
                decoration: InputDecoration(
                  hintText: 'Dear Diary…',
                  hintStyle: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: lineColor.withOpacity(2),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            Divider(height: 1, indent: 20, endIndent: 20, color: accent.withOpacity(0.3)),
            // ── Ruled-line editor ────────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  // Ruled lines background
                  LayoutBuilder(builder: (ctx, box) {
                    const lineHeight = 28.0;
                    final count = (box.maxHeight / lineHeight).ceil() + 1;
                    return Column(
                      children: List.generate(count, (_) => Container(
                        height: lineHeight,
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: lineColor, width: 1)),
                        ),
                      )),
                    );
                  }),
                  // Left red margin line
                  Positioned(
                    left: 48,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 1.5, color: const Color(0xFFFFB3B3).withOpacity(isDark ? 0.3 : 0.7)),
                  ),
                  // Quill editor padded to feel like writing on ruled paper
                  Padding(
                    padding: const EdgeInsets.only(left: 56, right: 16, top: 4),
                    child: _buildEditorBody(context),
                  ),
                ],
              ),
            ),
            if (isKeyboardOpen) _buildGentleNoteToolbar(theme, isDark, isAtBottom: true),
          ],
        ),
      ),
    );
  }

  // ── Scrapbook Layout ────────────────────────────────────────────────────────
  Widget _buildScrapbookLayout() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final bg = isDark ? const Color(0xFF160A1A) : const Color(0xFFFFF8FF);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    // Sticky note colors
    final stickyColors = [
      (bg: isDark ? const Color(0xFF2E1030) : const Color(0xFFFFE4F6), border: const Color(0xFFFF69B4)),
      (bg: isDark ? const Color(0xFF0E2030) : const Color(0xFFE4F0FF), border: const Color(0xFF69B4FF)),
      (bg: isDark ? const Color(0xFF102010) : const Color(0xFFE4FFE8), border: const Color(0xFF69C880)),
    ];

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Back + Save bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: accent),
                    onPressed: () { _saveNote(); if (Navigator.of(context).canPop()) Navigator.of(context).pop(); else context.go('/home'); },
                  ),
                  const Spacer(),
                  IconButton(icon: Icon(Icons.save_outlined, size: 18, color: accent), onPressed: _saveNote),
                ],
              ),
            ),
            // ── Sticky-note metadata panels ──────────────────────────────
            SizedBox(
              height: 88,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  // Title sticky
                  _scrapbookSticky(
                    bgColor: stickyColors[0].bg,
                    borderColor: stickyColors[0].border,
                    label: 'TITLE',
                    child: TextField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      maxLines: 2,
                      minLines: 1,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A0030)),
                      decoration: const InputDecoration(hintText: 'Note title…', border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true),
                    ),
                    isDark: isDark,
                    width: 130,
                  ),
                  const SizedBox(width: 8),
                  // Tags sticky
                  _scrapbookSticky(
                    bgColor: stickyColors[2].bg,
                    borderColor: stickyColors[2].border,
                    label: 'TAGS',
                    child: TextField(
                      controller: _tagController,
                      focusNode: _tagsFocusNode,
                      style: const TextStyle(fontSize: 11),
                      decoration: const InputDecoration(hintText: 'tag1, tag2…', border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true),
                    ),
                    isDark: isDark,
                    width: 110,
                  ),
                  const SizedBox(width: 8),
                  // Actions sticky
                  _scrapbookSticky(
                    bgColor: stickyColors[1].bg,
                    borderColor: stickyColors[1].border,
                    label: 'ACTIONS',
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () { setState(() { _isPinned = !_isPinned; _isDirty = true; }); _saveNote(isAutoSave: true); },
                          child: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 18, color: _isPinned ? accent : null),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () { setState(() { _isFavorite = !_isFavorite; _isDirty = true; }); _saveNote(isAutoSave: true); },
                          child: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, size: 18, color: _isFavorite ? const Color(0xFFF43F5E) : null),
                        ),
                      ],
                    ),
                    isDark: isDark,
                    width: 100,
                  ),
                ],
              ),
            ),
            // ── Editor card ──────────────────────────────────────────────
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF200A28) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withOpacity(0.2)),
                  boxShadow: [BoxShadow(color: accent.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    children: [
                      if (!isKeyboardOpen) _buildGentleNoteToolbar(theme, isDark),
                      Expanded(child: _buildEditorBody(context)),
                      if (isKeyboardOpen) _buildGentleNoteToolbar(theme, isDark, isAtBottom: true),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scrapbookSticky({
    required Color bgColor,
    required Color borderColor,
    required String label,
    required Widget child,
    required bool isDark,
    required double width,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: borderColor.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: borderColor, letterSpacing: 0.8)),
          const SizedBox(height: 4),
          Expanded(child: child),
        ],
      ),
    );
  }

  // ── Petal Layout ────────────────────────────────────────────────────────────
  Widget _buildPetalLayout() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final bg = isDark ? const Color(0xFF1A0710) : const Color(0xFFFFF5F9);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final headerGradient = isDark
        ? [const Color(0xFF9B1B5A), const Color(0xFF4A0B2A)]
        : [const Color(0xFFFF9EC8), const Color(0xFFFFCDE0)];

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Curved petal header ──────────────────────────────────────
            ClipPath(
              clipper: _PetalHeaderClipper(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: headerGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back + actions
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () { _saveNote(); if (Navigator.of(context).canPop()) Navigator.of(context).pop(); else context.go('/home'); },
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () { setState(() { _isPinned = !_isPinned; _isDirty = true; }); _saveNote(isAutoSave: true); },
                          child: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 18, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () { setState(() { _isFavorite = !_isFavorite; _isDirty = true; }); _saveNote(isAutoSave: true); },
                          child: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, size: 18, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _saveNote,
                          child: const Icon(Icons.save_outlined, size: 18, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Title
                    TextField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      maxLines: 2,
                      minLines: 1,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Beautiful title…',
                        hintStyle: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.55)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Toolbar + Editor ─────────────────────────────────────────
            if (!isKeyboardOpen) _buildGentleNoteToolbar(theme, isDark),
            Expanded(child: _buildEditorBody(context)),
            // ── Rounded pill meta row ────────────────────────────────────
            if (!isKeyboardOpen)
              Container(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _petalChip(icon: Icons.local_offer_outlined, label: _tagController.text.isEmpty ? 'Tags' : _tagController.text, accent: accent, isDark: isDark),
                      const SizedBox(width: 6),
                      _petalChip(icon: Icons.folder_outlined, label: 'Folder', accent: accent, isDark: isDark),
                    ],
                  ),
                ),
              ),
            if (isKeyboardOpen) _buildGentleNoteToolbar(theme, isDark, isAtBottom: true),
          ],
        ),
      ),
    );
  }

  Widget _petalChip({required IconData icon, required String label, required Color accent, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withOpacity(isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: accent),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  // ── Stardust Layout ─────────────────────────────────────────────────────────
  Widget _buildStardustLayout() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    const starPrimary = Color(0xFFCFA8FF);
    const starSecondary = Color(0xFFE8D0FF);
    final bgTop = isDark ? const Color(0xFF07031A) : const Color(0xFF150A38);
    final bgBot = isDark ? const Color(0xFF110A2E) : const Color(0xFF2A1060);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgTop, bgBot],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // ── Decorative stars ───────────────────────────────────────
              ..._buildStarParticles(),
              // ── Content ────────────────────────────────────────────────
              Column(
                children: [
                  // Toolbar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: starPrimary),
                          onPressed: () { _saveNote(); if (Navigator.of(context).canPop()) Navigator.of(context).pop(); else context.go('/home'); },
                        ),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.auto_awesome_rounded, size: 18, color: starPrimary), onPressed: _saveNote),
                      ],
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: TextField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      maxLines: 2,
                      minLines: 1,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: starSecondary,
                        height: 1.2,
                      ),
                      decoration: InputDecoration(
                        hintText: '✨ A dream note…',
                        hintStyle: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.w700, color: starPrimary.withOpacity(0.4)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                  // Editor on frosted glass card
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: starPrimary.withOpacity(0.2)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          children: [
                            if (!isKeyboardOpen) _buildGentleNoteToolbar(theme, isDark),
                            Expanded(child: _buildEditorBody(context)),
                            if (isKeyboardOpen) _buildGentleNoteToolbar(theme, isDark, isAtBottom: true),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStarParticles() {
    const stars = [
      (left: 20.0, top: 40.0, size: 2.0, opacity: 0.8),
      (left: 80.0, top: 15.0, size: 1.5, opacity: 0.6),
      (left: 150.0, top: 60.0, size: 2.5, opacity: 0.9),
      (left: 250.0, top: 25.0, size: 1.5, opacity: 0.7),
      (left: 310.0, top: 70.0, size: 2.0, opacity: 0.8),
      (left: 50.0, top: 120.0, size: 1.0, opacity: 0.5),
      (left: 190.0, top: 100.0, size: 1.5, opacity: 0.6),
      (left: 340.0, top: 130.0, size: 1.0, opacity: 0.4),
      (left: 120.0, top: 160.0, size: 2.0, opacity: 0.7),
      (left: 280.0, top: 180.0, size: 1.5, opacity: 0.5),
    ];
    return stars.map((s) => Positioned(
      left: s.left,
      top: s.top,
      child: Opacity(
        opacity: s.opacity,
        child: Container(
          width: s.size,
          height: s.size,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
      ),
    )).toList();
  }

  /// Original layout — preserved exactly as it was before this refactor.
  Widget _buildClassicLayout(ThemeData theme, bool isDark) {
    final folders = ref.watch(foldersProvider);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final showFolderOptions = !isKeyboardOpen || !_editorFocusNode.hasFocus;
    final isMobile = ResponsiveHelper.isMobile(context);

    final colors = [
      '#FFFFFF',
      '#FEE2E2',
      '#FEF3C7',
      '#ECFDF5',
      '#E0F2FE',
      '#F3E8FF',
      '#FDF4FF',
    ];

    return GentleScaffold(
      title: _isEditMode ? 'Edit Note' : 'New Note',
      showBackButton: false,
      showBottomNav: false,
      appBar: _buildCustomAppBar(theme, isDark),
      body: Stack(
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
                              value: _selectedFolderId,
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
                              onChanged: (val) {
                                setState(() {
                                  _selectedFolderId = val;
                                  _isDirty = true;
                                });
                              },
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
                              value: _noteType,
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
                                  setState(() {
                                    _noteType = val;
                                    _isDirty = true;
                                  });
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
                              final isSelected = _colorHex == colHex;
                              final color = colHex == '#FFFFFF'
                                  ? Colors.grey.shade300
                                  : Color(int.parse('FF${colHex.replaceAll('#', '')}', radix: 16));
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _colorHex = colHex;
                                    _isDirty = true;
                                  });
                                },
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
                )
              else
                const SizedBox.shrink(),
              if (showFolderOptions)
                const Divider(height: 1)
              else
                const SizedBox.shrink(),
              Expanded(
                child: _buildEditorBody(context),
              ),
              if (!isMobile && isKeyboardOpen && !_tagsFocusNode.hasFocus)
                _buildGentleNoteToolbar(theme, isDark, isAtBottom: true)
              else
                const SizedBox.shrink(),
              Visibility(
                visible: !isKeyboardOpen || _tagsFocusNode.hasFocus,
                maintainState: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Row(
                        children: [
                          Icon(Icons.local_offer_outlined, size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _tagController,
                              focusNode: _tagsFocusNode,
                              style: const TextStyle(fontSize: 13),
                              decoration: const InputDecoration(
                                hintText: 'Add tags (comma separated, e.g., flutter, research, ai)',
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                fillColor: Colors.transparent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isMobile && (!isKeyboardOpen || (isKeyboardOpen && !_tagsFocusNode.hasFocus)))
                _buildGentleNoteToolbar(theme, isDark, isAtBottom: true)
              else
                const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom clipper for the petal layout's curved header.
class _PetalHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 16);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 10,
      size.width,
      size.height - 16,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_PetalHeaderClipper old) => false;
}

