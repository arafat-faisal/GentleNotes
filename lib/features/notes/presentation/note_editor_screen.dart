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
import 'package:speech_to_text/speech_to_text.dart' as speech_to_text;

import '../../../core/widgets/gentle_scaffold.dart';
import '../../../core/utils/quill_markdown_converter.dart';
import '../../../core/utils/responsive_helper.dart';
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

  // ── UI mode flags ────────────────────────────────────────────────────────
  bool _isFullScreen = false;
  bool _isFocusMode = false;

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

  // ── Custom Color Picker Helper ───────────────────────────────────────────
  Future<Color?> _showCustomColorPicker(BuildContext context, {
    required List<Color> presetColors,
    required String title,
    Widget Function(Color)? previewBuilder,
  }) async {
    Color? selectedColor;
    final hexController = TextEditingController();
    Color previewColor = presetColors.first;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) {
          final theme = Theme.of(ctx2);
          final isDark = theme.brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF13111C) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: isDark ? const Color(0xFF252234) : const Color(0xFFE9E6F5)),
            ),
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx2).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3D3557) : const Color(0xFFD1CBE8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
                const SizedBox(height: 16),
                Text(title, style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: 'Outfit', fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: [
                    ...presetColors.map((c) {
                      final isSelected = previewColor == c;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() => previewColor = c);
                          hexController.text = '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                        },
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade400,
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.4), blurRadius: 6)] : null,
                          ),
                          child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 20),
                if (previewBuilder != null) ...[
                  Text('Preview', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  previewBuilder(previewColor),
                  const SizedBox(height: 20),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: hexController,
                        decoration: const InputDecoration(
                          hintText: '#HEX Color',
                          prefixText: 'Value: ',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (val) {
                          if (val.length == 7 && val.startsWith('#')) {
                            final parsedColor = Color(int.parse('FF${val.substring(1)}', radix: 16));
                            setModalState(() => previewColor = parsedColor);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onPressed: () {
                        selectedColor = const Color(0x00000000);
                        Navigator.pop(ctx2);
                      },
                      child: const Text('Normal'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onPressed: () {
                        selectedColor = previewColor;
                        Navigator.pop(ctx2);
                      },
                      child: const Text('Select'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    return selectedColor;
  }

  // Highlight color picker button
  Widget _buildHighlightButton(ThemeData theme, bool isDark) {
    final highlights = [
      const Color(0xFFFFFF00),
      const Color(0xFFADFF2F),
      const Color(0xFF87CEEB),
      const Color(0xFFFFB6C1),
      const Color(0xFFFFD700),
      const Color(0xFFFFA07A),
      const Color(0xFF98FB98),
      const Color(0xFFDDA0DD),
    ];
    return Tooltip(
      message: 'Highlight Text',
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () async {
          final color = await _showCustomColorPicker(
            context,
            presetColors: highlights,
            title: '🖌️ Highlight Color',
            previewBuilder: (c) => Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: RichText(
                text: TextSpan(
                  text: 'Sample highlighted ',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                  children: [
                    TextSpan(
                      text: 'text preview',
                      style: TextStyle(backgroundColor: c, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
          if (color != null && !_titleFocusNode.hasFocus) {
            if (color.value == 0) {
              _quillController.formatSelection(BackgroundAttribute(null));
            } else {
              final hexStr = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
              _quillController.formatSelection(BackgroundAttribute(hexStr));
            }
            _markDirty();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFF00).withOpacity(0.4),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.highlight, size: 18),
          ),
        ),
      ),
    );
  }

  // Text color picker button
  Widget _buildTextColorButton(ThemeData theme, bool isDark) {
    final textColors = [
      const Color(0xFFEF4444),
      const Color(0xFFF97316),
      const Color(0xFFEAB308),
      const Color(0xFF22C55E),
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF6B7280),
      const Color(0xFF111827),
      const Color(0xFF6366F1),
      const Color(0xFF14B8A6),
      const Color(0xFFF59E0B),
    ];
    return Tooltip(
      message: 'Text Color',
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () async {
          final color = await _showCustomColorPicker(
            context,
            presetColors: textColors,
            title: '🎨 Text Color',
            previewBuilder: (c) => Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: RichText(
                text: TextSpan(
                  text: 'Normal text with ',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14),
                  children: [
                    TextSpan(
                      text: 'colored text preview',
                      style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
          if (color != null && !_titleFocusNode.hasFocus) {
            if (color.value == 0) {
              _quillController.formatSelection(ColorAttribute(null));
            } else {
              final hexStr = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
              _quillController.formatSelection(ColorAttribute(hexStr));
            }
            _markDirty();
          }
        },
        child: const Padding(
          padding: EdgeInsets.all(6.0),
          child: Icon(Icons.format_color_text, size: 18),
        ),
      ),
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
          return Row(
            children: [
              _buildTextColorButton(theme, isDark),
              const SizedBox(width: 4),
              _buildHighlightButton(theme, isDark),
            ],
          );
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
                      ],
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
    final isMarkdownPreview = _noteType == NoteType.markdown;

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
                      ],
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

  Widget _wrapWithPreviewStyle(Widget content) {
    return CustomPaint(
      painter: PreviewStylePainter(_previewStyle),
      child: Padding(
        padding: styleContentPadding(_previewStyle),
        child: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final folders = ref.watch(foldersProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = theme.brightness == Brightness.dark;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final showFolderOptions = !isKeyboardOpen || !_editorFocusNode.hasFocus;
    final isMobile = ResponsiveHelper.isMobile(context);
    
    if (_isFullScreen) {
      return _buildFullScreenBody();
    }

    if (_isFocusMode) {
      return _buildFocusModeBody();
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

    return GentleScaffold(
      title: _isEditMode ? 'Edit Note' : 'New Note',
      showBackButton: true,
      showBottomNav: false,
      titleWidget: TextField(
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
      actions: [
        Builder(
          builder: (context) {
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.mic_rounded, color: Color(0xFF8B5CF6)),
                      tooltip: 'Record Voice Note',
                      onPressed: _toggleVoiceRecording,
                    ),
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
                    PopupMenuButton<PreviewStyle>(
                      tooltip: 'Preview Style',
                      icon: const Icon(Icons.style_rounded, color: Color(0xFF8B5CF6)),
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
                    IconButton(
                      icon: const Icon(Icons.fullscreen_rounded, color: Color(0xFF8B5CF6)),
                      tooltip: 'Zen Writing Mode (Focus)',
                      onPressed: () => setState(() => _isFocusMode = true),
                    ),
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
                      icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
                      color: _isFavorite ? const Color(0xFFF43F5E) : const Color(0xFF8B5CF6),
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
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'save', child: Row(children: [Icon(Icons.save_outlined), SizedBox(width: 8), Text('Save Note')])),
                        const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share_outlined), SizedBox(width: 8), Text('Share Note')])),
                        const PopupMenuItem(value: 'md', child: Row(children: [Icon(Icons.article_outlined), SizedBox(width: 8), Text('Export MD')])),
                        const PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF8B5CF6)), SizedBox(width: 8), Text('Export PDF')])),
                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red), SizedBox(width: 8), Text('Delete Note', style: TextStyle(color: Colors.red))])),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
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

