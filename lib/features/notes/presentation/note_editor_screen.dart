import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
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

import '../../../core/widgets/gentle_scaffold.dart';
import '../../../core/utils/clipboard_helper.dart';
import '../../../models/models.dart';
import '../../folders/data/folders_repository.dart';
import '../../notes/data/notes_repository.dart';
import '../../templates/data/templates_repository.dart';
import '../../settings/data/settings_repository.dart';
import '../../../services/export_import_service.dart';
import '../../../services/pdf_export_service.dart';
import 'drawing_canvas_screen.dart';
import 'markdown_syntax_controller.dart';

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
  final MarkdownSyntaxController _contentController = MarkdownSyntaxController(wysiwygMode: true);
  final TextEditingController _tagController = TextEditingController();
  final FocusNode _editorFocusNode = FocusNode();

  NoteType _noteType = NoteType.text;
  String? _selectedFolderId;
  String? _templateId;
  bool _isPinned = false;
  bool _isFavorite = false;
  String _colorHex = '#FFFFFF';
  DateTime? _createdAt;
  List<AttachmentModel> _attachments = [];
  MarkdownLayoutMode _markdownLayout = MarkdownLayoutMode.splitView;
  List<NoteBlock> _blocks = [];
  bool _isPreviewMode = false; // For preview-only rendering across all note types
  String? _activeToolbarGroup; // For GentleNote grouped toolbar: which group is expanded
  TextAlign _gentleTextAlign = TextAlign.start; // Live text alignment for GentleNote mode

  // ── UI mode flags ────────────────────────────────────────────────────────
  bool _isFullScreen = false;
  bool _isFocusMode = false; // Zen / simple writing mode

  // ── Preview background ───────────────────────────────────────────────────
  Color? _previewBgColor;
  String? _previewBgImagePath;
  double _previewOverlayOpacity = 0.0;
  Color _previewOverlayColor = Colors.black;
  bool _showBgPicker = false;

  // ── Preview Style ────────────────────────────────────────────────────────
  PreviewStyle _previewStyle = PreviewStyle.plain;

  // ── Voice Notes ──────────────────────────────────────────────────────────
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  Timer? _autoSaveTimer;
  bool _isDirty = false;

  bool _showPasteOptions = false;
  int _lastPasteStartOffset = 0;
  int _lastPasteFormattedLength = 0;
  String _lastPastePlainText = '';
  Timer? _pasteOptionsTimer;

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

    // Setup auto-save listener
    _titleController.addListener(_markDirty);
    _contentController.addListener(_markDirty);
    _contentController.addListener(_detectCurrentAlignment);
    _tagController.addListener(_markDirty);

    // Setup web/desktop clipboard paste listener
    setupClipboardPasteListener(
      context,
      _editorFocusNode,
      _onClipboardImagePasted,
      _onTextPasted,
    );

    final settings = ref.read(settingsProvider);
    if (settings.autoSaveEnabled) {
      _autoSaveTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (_isDirty) {
          _saveNote(isAutoSave: true);
        }
      });
    }
  }

  void _markDirty() {
    _isDirty = true;
  }

  // ── Detect alignment of the paragraph under the cursor ────────────────────
  void _detectCurrentAlignment() {
    if (_noteType != NoteType.mixed) return;
    final text = _contentController.text;
    final cursor = _contentController.selection.baseOffset;
    if (cursor < 0 || cursor > text.length) return;

    final before = text.substring(0, cursor);
    final lineStart = before.lastIndexOf('\n') + 1;
    final lineEndRaw = text.indexOf('\n', cursor);
    final lineEnd = lineEndRaw < 0 ? text.length : lineEndRaw;
    final currentLine = text.substring(lineStart, lineEnd);

    final alignMatch = RegExp(
      r'^<div\s+align="(left|center|right|justify)">(.*)</div>$',
    ).firstMatch(currentLine);

    TextAlign newAlign = TextAlign.start;
    if (alignMatch != null) {
      switch (alignMatch.group(1)) {
        case 'center':  newAlign = TextAlign.center; break;
        case 'right':   newAlign = TextAlign.right; break;
        case 'justify': newAlign = TextAlign.justify; break;
        default:        newAlign = TextAlign.left;
      }
    }

    if (newAlign != _gentleTextAlign) {
      // We only track this for the UI toggle button highlights (if we add them later)
      // but we NO LONGER call setState() to rebuild the TextField because a single TextField
      // cannot have per-line alignment.
      _gentleTextAlign = newAlign;
    }
  }

  // ── Apply alignment to the current line/paragraph ─────────────────────────
  void _applyLineAlignment(String align) {
    final text = _contentController.text;
    final sel = _contentController.selection;
    final cursor = sel.isValid ? sel.baseOffset : text.length;

    final before = text.substring(0, cursor);
    final lineStart = before.lastIndexOf('\n') + 1;
    final lineEndRaw = text.indexOf('\n', cursor);
    final lineEnd = lineEndRaw < 0 ? text.length : lineEndRaw;
    final currentLine = text.substring(lineStart, lineEnd);

    final stripped = RegExp(
      r'^<div\s+align="(?:left|center|right|justify)">(.*)</div>$',
    ).firstMatch(currentLine)?.group(1) ?? currentLine;

    final existing = RegExp(
      r'^<div\s+align="(left|center|right|justify)">',
    ).firstMatch(currentLine)?.group(1);
    final newLine = (existing == align)
        ? stripped
        : '<div align="$align">$stripped</div>';

    final newText = text.substring(0, lineStart) + newLine + text.substring(lineEnd);
    final newCursor = (lineStart + newLine.length).clamp(0, newText.length);

    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    _markDirty();
    _detectCurrentAlignment();
  }

  void _loadNoteOrTemplate() {
    if (_isEditMode) {
      // Edit mode: Load existing note
      final notes = ref.read(notesProvider);
      final note = notes.cast<NoteModel?>().firstWhere(
            (n) => n?.id == _noteId,
            orElse: () => null,
          );

      if (note != null) {
        setState(() {
          _titleController.text = note.title;
          _contentController.text = note.content;
          _tagController.text = note.tags.join(', ');
          _noteType = note.noteType;
          _selectedFolderId = note.folderId;
          _templateId = note.templateId;
          _isPinned = note.isPinned;
          _isFavorite = note.isFavorite;
          _colorHex = note.colorHex;
          _createdAt = note.createdAt;
          _attachments = note.attachments;
          _blocks = _parseMarkdownToBlocks(note.content);
        });
      }
    } else {
      // Create mode: Check templates or defaults
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
            _contentController.text = template.defaultContent;
            _tagController.text = template.defaultTags.join(', ');
            _blocks = _parseMarkdownToBlocks(template.defaultContent);
            // Deduce note type based on template hints
            if (template.id == 't-code') {
              _noteType = NoteType.code;
            } else if (template.id == 't-journal' || template.id == 't-study') {
              _noteType = NoteType.markdown;
            }
          });
        }
      } else {
        setState(() {
          _blocks = [NoteBlock(id: const Uuid().v4(), type: NoteBlockType.paragraph, text: '')];
        });
      }
    }
    // After loading, reset dirty flag
    setState(() {
      _isDirty = false;
    });
  }

  Future<void> _saveNote({bool isAutoSave = false}) async {
    if (!_isDirty && isAutoSave) return;

    final title = _titleController.text.trim();
    final content = _contentController.text;
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
      debugPrint('Note auto-save ignored during disposal/deactivation: $e');
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
    _pasteOptionsTimer?.cancel();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    if (_isDirty) {
      _saveNote(isAutoSave: true);
    }
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _editorFocusNode.dispose();
    disposeClipboardPasteListener();
    for (final block in _blocks) {
      block.controller.dispose();
      block.focusNode.dispose();
    }
    super.dispose();
  }

  // Parses markdown checklist items and toggles them
  void _toggleChecklistItem(int lineIndex, bool currentValue) {
    final lines = _contentController.text.split('\n');
    final line = lines[lineIndex];

    String updatedLine;
    if (currentValue) {
      // Checked -> Unchecked
      updatedLine = line.replaceFirst('[x]', '[ ]').replaceFirst('[X]', '[ ]');
    } else {
      // Unchecked -> Checked
      updatedLine = line.replaceFirst('[ ]', '[x]');
    }

    lines[lineIndex] = updatedLine;
    setState(() {
      _contentController.text = lines.join('\n');
      _isDirty = true;
    });
    _saveNote(isAutoSave: true);
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

    // Dynamic sharing/saving
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
                  Navigator.pop(context); // close dialog
                  context.pop(); // route back
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

    // Paper size state
    String _selectedSize = 'A4';
    bool _isLandscape = false;
    bool _inclMetadata = true;
    bool _inclTags = true;

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
              // Handle
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

              // Paper size
              Text('Paper Size', style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700, letterSpacing: 0.8,
                color: const Color(0xFF8B5CF6),
              )),
              const SizedBox(height: 8),
              Row(
                children: sizeMap.keys.map((size) {
                  final selected = _selectedSize == size;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setS(() => _selectedSize = size),
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

              // Orientation
              Text('Orientation', style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700, letterSpacing: 0.8,
                color: const Color(0xFF8B5CF6),
              )),
              const SizedBox(height: 8),
              Row(
                children: [
                  _pdfOptionPill('Portrait', !_isLandscape, Icons.crop_portrait_rounded, isDark,
                      () => setS(() => _isLandscape = false)),
                  const SizedBox(width: 8),
                  _pdfOptionPill('Landscape', _isLandscape, Icons.crop_landscape_rounded, isDark,
                      () => setS(() => _isLandscape = true)),
                ],
              ),
              const SizedBox(height: 16),

              // Options
              Text('Include', style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700, letterSpacing: 0.8,
                color: const Color(0xFF8B5CF6),
              )),
              const SizedBox(height: 8),
              Row(
                children: [
                  _pdfTogglePill('Metadata', _inclMetadata, isDark, () => setS(() => _inclMetadata = !_inclMetadata)),
                  const SizedBox(width: 8),
                  _pdfTogglePill('Tags', _inclTags, isDark, () => setS(() => _inclTags = !_inclTags)),
                ],
              ),
              const SizedBox(height: 24),

              // Export button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx2);
                    var fmt = sizeMap[_selectedSize] ?? PdfPageFormat.a4;
                    if (_isLandscape) fmt = fmt.landscape;
                    final folders = ref.read(foldersProvider);
                    final folder = folders.cast<FolderModel?>().firstWhere(
                      (f) => f?.id == _selectedFolderId, orElse: () => null);
                    final note = ref.read(notesProvider).firstWhere((n) => n.id == _noteId);
                    try {
                      await PdfExportService().printOrExportNote(
                        note,
                        folderName: folder?.name,
                        pageFormat: fmt,
                        includeMetadata: _inclMetadata,
                        includeTags: _inclTags,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: selected ? Colors.white : const Color(0xFF8B5CF6)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13,
              color: selected ? Colors.white : (isDark ? const Color(0xFFAA9ECC) : const Color(0xFF7C3AED)),
            )),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 14,
              color: selected ? Colors.white : const Color(0xFF8B5CF6),
            ),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13,
              color: selected ? Colors.white : (isDark ? const Color(0xFFAA9ECC) : const Color(0xFF7C3AED)),
            )),
          ],
        ),
      ),
    );
  }


  Widget _buildLayoutSelector() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      alignment: Alignment.center,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _layoutSelectorItem(
              mode: MarkdownLayoutMode.editOnly,
              icon: Icons.edit_note,
              label: 'Edit',
            ),
            _layoutSelectorItem(
              mode: MarkdownLayoutMode.splitView,
              icon: Icons.vertical_split_outlined,
              label: 'Split',
            ),
            _layoutSelectorItem(
              mode: MarkdownLayoutMode.previewOnly,
              icon: Icons.visibility_outlined,
              label: 'Preview',
            ),
          ],
        ),
      ),
    );
  }

  Widget _layoutSelectorItem({
    required MarkdownLayoutMode mode,
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final isSelected = _markdownLayout == mode;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _markdownLayout = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 38,
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _insertImageDialog() async {
    final theme = Theme.of(context);
    String selectedSize = 'medium'; // small, medium, large
    String selectedAlign = 'center'; // left, center, right
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
                    // Alignment selector
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
                    // Size selector
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
                          label: 'Large',
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
                ElevatedButton(
                  onPressed: () {
                    final url = urlController.text.trim();
                    if (url.isNotEmpty) {
                      _insertText('![Image | size=$selectedSize | align=$selectedAlign]($url)\n\n', '');
                    }
                    Navigator.pop(context);
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

  Widget _dialogPillButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
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

      _insertText('![${image.name} | size=$size | align=$align](attachment://$attachmentId)\n\n', '');
      _saveNote(isAutoSave: true);

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

  void _onClipboardImagePasted(String dataUrl, String fileName) {
    final attachmentId = const Uuid().v4();
    final newAttachment = AttachmentModel(
      id: attachmentId,
      noteId: _noteId,
      type: AttachmentType.image,
      name: fileName,
      pathOrUrl: dataUrl,
      createdAt: DateTime.now(),
    );

    setState(() {
      _attachments.add(newAttachment);
      _isDirty = true;
    });

    _insertText('![$fileName | size=medium | align=center](attachment://$attachmentId)\n\n', '');
    _saveNote(isAutoSave: true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image pasted from clipboard!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _onTextPasted(String plainText, String? htmlText) {
    String textToInsert;
    bool isRichPaste = false;
    
    if (htmlText != null && htmlText.isNotEmpty) {
      textToInsert = _convertHtmlToMarkdown(htmlText);
      isRichPaste = true;
    } else if (_isTabularData(plainText)) {
      textToInsert = _convertTabularToMarkdownTable(plainText);
      isRichPaste = true;
    } else {
      textToInsert = plainText;
    }

    if (_noteType == NoteType.markdown || _noteType == NoteType.mixed) {
      final focused = _findFocusedBlock();
      if (focused != null) {
        final newBlocks = _parseMarkdownToBlocks(textToInsert);
        final index = _blocks.indexOf(focused);
        if (newBlocks.length == 1 && newBlocks.first.type == NoteBlockType.paragraph) {
          final ctrl = focused.controller;
          final sel = ctrl.selection;
          int start = sel.start;
          int end = sel.end;
          if (start < 0 || start > ctrl.text.length) {
            start = ctrl.text.length;
            end = ctrl.text.length;
          }
          final newTxt = ctrl.text.replaceRange(start, end, newBlocks.first.controller.text);
          ctrl.value = TextEditingValue(
            text: newTxt,
            selection: TextSelection.collapsed(offset: start + newBlocks.first.controller.text.length),
          );
        } else {
          setState(() {
            _blocks.insertAll(index + 1, newBlocks);
            _isDirty = true;
          });
        }
        _syncBlocksToContent();
        _saveNote(isAutoSave: true);
        return;
      }
    }
    
    final text = _contentController.text;
    final selection = _contentController.selection;
    int start = selection.start;
    int end = selection.end;
    if (start < 0 || start > text.length) {
      start = text.length;
      end = text.length;
    }
    final selectedText = text.substring(start, end);
    final newText = text.replaceRange(start, end, textToInsert);
    
    setState(() {
      _contentController.text = newText;
      _isDirty = true;
      
      if (isRichPaste) {
        _showPasteOptions = true;
        _lastPasteStartOffset = start;
        _lastPasteFormattedLength = textToInsert.length;
        _lastPastePlainText = plainText;
        
        _pasteOptionsTimer?.cancel();
        _pasteOptionsTimer = Timer(const Duration(seconds: 8), () {
          if (mounted) {
            setState(() {
              _showPasteOptions = false;
            });
          }
        });
      } else {
        _showPasteOptions = false;
      }
    });
    
    _contentController.selection = TextSelection.collapsed(
      offset: start + textToInsert.length,
    );
    
    _saveNote(isAutoSave: true);
  }

  bool _isTabularData(String text) {
    final cleanText = text.replaceAll('\r', '').trim();
    if (cleanText.isEmpty) return false;
    final lines = cleanText.split('\n');
    if (lines.isEmpty) return false;

    // Check if it's TSV
    if (_detectSeparator(lines, '\t')) return true;

    // Check if it's CSV
    if (_detectSeparator(lines, ',')) return true;

    // Check if it's Semicolon-separated
    if (_detectSeparator(lines, ';')) return true;

    return false;
  }

  bool _detectSeparator(List<String> lines, String separator) {
    int linesWithSeparator = 0;
    int nonEmptyLines = 0;
    final List<int> separatorCounts = [];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      nonEmptyLines++;
      final count = separator.allMatches(line).length;
      if (count > 0) {
        linesWithSeparator++;
        separatorCounts.add(count);
      }
    }

    if (nonEmptyLines < 1 || linesWithSeparator < nonEmptyLines * 0.5) {
      return false;
    }

    if (separatorCounts.isEmpty) return false;
    final firstCount = separatorCounts.first;
    int matchesFirst = 0;
    for (final c in separatorCounts) {
      if (c == firstCount) matchesFirst++;
    }

    return (matchesFirst / separatorCounts.length) >= 0.7;
  }

  String _convertTabularToMarkdownTable(String text) {
    final cleanText = text.replaceAll('\r', '').trim();
    final lines = cleanText.split('\n');
    if (lines.isEmpty) return text;

    String separator = '\t';
    if (_detectSeparator(lines, '\t')) {
      separator = '\t';
    } else if (_detectSeparator(lines, ',')) {
      separator = ',';
    } else if (_detectSeparator(lines, ';')) {
      separator = ';';
    } else {
      return text;
    }

    final List<List<String>> rows = [];
    int maxCols = 0;

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      List<String> cells;
      if (separator == ',') {
        cells = _parseCsvLine(line);
      } else {
        cells = line.split(separator).map((e) => e.trim()).toList();
      }
      rows.add(cells);
      if (cells.length > maxCols) {
        maxCols = cells.length;
      }
    }

    if (rows.isEmpty) return text;

    final buffer = StringBuffer();
    final headers = rows.first;
    buffer.write('\n| ');
    buffer.write(headers.join(' | '));
    if (headers.length < maxCols) {
      buffer.write(' | ' * (maxCols - headers.length));
    }
    buffer.write(' |\n');

    buffer.write('| ');
    buffer.write(List.filled(maxCols, '---').join(' | '));
    buffer.write(' |\n');

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      buffer.write('| ');
      buffer.write(row.map((e) => e.replaceAll('|', '\\|')).join(' | '));
      if (row.length < maxCols) {
        buffer.write(' | ' * (maxCols - row.length));
      }
      buffer.write(' |\n');
    }
    buffer.write('\n');
    return buffer.toString();
  }

  List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    final StringBuffer currentCell = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          currentCell.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(currentCell.toString().trim());
        currentCell.clear();
      } else {
        currentCell.write(char);
      }
    }
    result.add(currentCell.toString().trim());
    return result;
  }

  bool _isCodeTable(String htmlTable) {
    final lower = htmlTable.toLowerCase();
    return lower.contains('class="highlight') ||
           lower.contains('class="blob-code') ||
           lower.contains('class="js-file-line') ||
           lower.contains('class="line-content') ||
           lower.contains('code-table') ||
           lower.contains('class="prettyprint');
  }

  String _parseHtmlTable(String htmlTable) {
    final trRegExp = RegExp(r'<tr(?: [^>]*)?>([\s\S]*?)</tr>', caseSensitive: false);
    final cellRegExp = RegExp(r'<(?:td|th)(?: [^>]*)?>([\s\S]*?)</(?:td|th)>', caseSensitive: false);

    // If it's a code line table (like GitHub code view), convert it directly into a code block
    if (_isCodeTable(htmlTable)) {
      final List<String> lines = [];
      for (final trMatch in trRegExp.allMatches(htmlTable)) {
        final trContent = trMatch.group(1)!;
        final List<String> cells = [];
        for (final cellMatch in cellRegExp.allMatches(trContent)) {
          final cellHtml = cellMatch.group(0)!;
          final cellText = cellMatch.group(1)!;
          
          // Skip line numbers
          if (cellHtml.contains('class="blob-num') ||
              cellHtml.contains('class="js-line-number') ||
              cellHtml.contains('class="line-number') ||
              RegExp(r'^\s*\d+\s*$').hasMatch(cellText.replaceAll(RegExp(r'<[^>]+>'), ''))) {
            continue;
          }
          cells.add(cellText);
        }
        if (cells.isNotEmpty) {
          final lineText = cells.join(' ')
              .replaceAll(RegExp(r'<[^>]+>'), '')
              .replaceAll('&nbsp;', ' ')
              .replaceAll('&amp;', '&')
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>')
              .replaceAll('&quot;', '"')
              .replaceAll('&#39;', "'")
              .trim();
          lines.add(lineText);
        }
      }
      return '\n```\n${lines.join('\n')}\n```\n';
    }

    final List<List<String>> rows = [];
    
    for (final trMatch in trRegExp.allMatches(htmlTable)) {
      final trContent = trMatch.group(1)!;
      final List<String> rowCells = [];
      
      for (final cellMatch in cellRegExp.allMatches(trContent)) {
        String cellText = cellMatch.group(1)!
            .replaceAll(RegExp(r'<[^>]+>'), '')
            .replaceAll('&nbsp;', ' ')
            .replaceAll('\n', ' ')
            .trim();
        rowCells.add(cellText);
      }
      if (rowCells.isNotEmpty) {
        rows.add(rowCells);
      }
    }
    
    if (rows.isEmpty) return '';
    
    final buffer = StringBuffer();
    
    final headers = rows.first;
    buffer.write('\n| ');
    buffer.write(headers.join(' | '));
    buffer.write(' |\n');
    
    buffer.write('| ');
    buffer.write(List.filled(headers.length, '---').join(' | '));
    buffer.write(' |\n');
    
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      while (row.length < headers.length) {
        row.add('');
      }
      final trimmedRow = row.sublist(0, headers.length);
      buffer.write('| ');
      buffer.write(trimmedRow.join(' | '));
      buffer.write(' |\n');
    }
    buffer.write('\n');
    
    return buffer.toString();
  }

  String _convertHtmlToMarkdown(String html) {
    // 0. Protect <u> and </u> tags
    html = html.replaceAll(RegExp(r'<u>', caseSensitive: false), '%%U_OPEN%%')
               .replaceAll(RegExp(r'</u>', caseSensitive: false), '%%U_CLOSE%%');

    // 1. Extract and placeholder <pre>...</pre> code blocks
    final List<String> codeBlocks = [];
    final preRegExp = RegExp(r'<pre(?: [^>]*)?>([\s\S]*?)</pre>', caseSensitive: false);
    
    html = html.replaceAllMapped(preRegExp, (m) {
      final codeBlocksIndex = codeBlocks.length;
      codeBlocks.add(m.group(0)!);
      return '\n\n%%CODE_BLOCK_$codeBlocksIndex%%\n\n';
    });

    // 2. Pre-parse HTML tables (safe from mangling code lines tables inside code blocks)
    html = html.replaceAllMapped(RegExp(r'<table(?: [^>]*)?>([\s\S]*?)</table>', caseSensitive: false), (m) {
      return _parseHtmlTable(m.group(0)!);
    });

    // 3. Remove style, head, script tags and HTML comments
    html = html.replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), '');
    html = html.replaceAll(RegExp(r'<head[\s\S]*?</head>', caseSensitive: false), '');
    html = html.replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), '');
    html = html.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');

    // 4. Inline code
    html = html.replaceAllMapped(RegExp(r'<code(?: [^>]*)?>([\s\S]*?)</code>', caseSensitive: false), (m) {
      return ' `${m.group(1)}` ';
    });

    // 5. Bold
    html = html.replaceAllMapped(RegExp(r'<(?:strong|b)(?: [^>]*)?>([\s\S]*?)</(?:strong|b)>', caseSensitive: false), (m) {
      return '**${m.group(1)}**';
    });

    // 6. Italic (uses underscore format to guarantee nested bold-italic formatting parses cleanly)
    html = html.replaceAllMapped(RegExp(r'<(?:em|i)(?: [^>]*)?>([\s\S]*?)</(?:em|i)>', caseSensitive: false), (m) {
      return '_${m.group(1)}_';
    });

    // 7. Headers
    html = html.replaceAllMapped(RegExp(r'<h1(?: [^>]*)?>([\s\S]*?)</h1>', caseSensitive: false), (m) {
      return '\n# ${m.group(1)}\n';
    });
    html = html.replaceAllMapped(RegExp(r'<h2(?: [^>]*)?>([\s\S]*?)</h2>', caseSensitive: false), (m) {
      return '\n## ${m.group(1)}\n';
    });
    html = html.replaceAllMapped(RegExp(r'<h3(?: [^>]*)?>([\s\S]*?)</h3>', caseSensitive: false), (m) {
      return '\n### ${m.group(1)}\n';
    });
    html = html.replaceAllMapped(RegExp(r'<h4(?: [^>]*)?>([\s\S]*?)</h4>', caseSensitive: false), (m) {
      return '\n#### ${m.group(1)}\n';
    });

    // 8. Anchor/Links
    html = html.replaceAllMapped(RegExp(r'''<a\s+[^>]*href=["']([^"']+)["'][^>]*>([\s\S]*?)</a>''', caseSensitive: false), (m) {
      return '[${m.group(2)}](${m.group(1)})';
    });

    // 9. Break tags
    html = html.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');

    // 10. Paragraphs and Divs (using proper block newlines to prevent header smashing)
    html = html.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n');
    html = html.replaceAll(RegExp(r'<p(?: [^>]*)?>', caseSensitive: false), '\n');
    html = html.replaceAll(RegExp(r'</div>', caseSensitive: false), '\n');
    html = html.replaceAll(RegExp(r'<div(?: [^>]*)?>', caseSensitive: false), '\n');

    // 11. List items
    html = html.replaceAllMapped(RegExp(r'<li(?: [^>]*)?>([\s\S]*?)</li>', caseSensitive: false), (m) {
      return '\n- ${m.group(1)}';
    });
    html = html.replaceAll(RegExp(r'</?(?:ul|ol)(?: [^>]*)?>', caseSensitive: false), '\n');

    // 12. Strip remaining tags
    html = html.replaceAll(RegExp(r'<[^>]+>'), '');

    // 13. HTML entities decode
    html = html.replaceAll('&amp;', '&')
               .replaceAll('&lt;', '<')
               .replaceAll('&gt;', '>')
               .replaceAll('&quot;', '"')
               .replaceAll('&#39;', "'")
               .replaceAll('&nbsp;', ' ');

    // 14. Restore and format placeholder code blocks
    for (int i = 0; i < codeBlocks.length; i++) {
      final placeholder = '%%CODE_BLOCK_$i%%';
      final rawPre = codeBlocks[i];
      
      String language = '';
      String codeContent = '';
      
      final codeWithClassRegExp = RegExp(r'''<code(?: [^>]*)?class=["'](?:language-)?([-a-zA-Z0-9+]+)["'](?: [^>]*)?>([\s\S]*?)</code>''', caseSensitive: false);
      final codeRegExp = RegExp(r'<code(?: [^>]*)?>([\s\S]*?)</code>', caseSensitive: false);
      
      final classMatch = codeWithClassRegExp.firstMatch(rawPre);
      if (classMatch != null) {
        language = classMatch.group(1)!.trim();
        codeContent = classMatch.group(2)!;
      } else {
        final codeMatch = codeRegExp.firstMatch(rawPre);
        if (codeMatch != null) {
          codeContent = codeMatch.group(1)!;
        } else {
          final preInnerRegExp = RegExp(r'<pre(?: [^>]*)?>([\s\S]*?)</pre>', caseSensitive: false);
          final preMatch = preInnerRegExp.firstMatch(rawPre);
          codeContent = preMatch != null ? preMatch.group(1)! : rawPre;
        }
      }
      
      String processedCode = codeContent;
      processedCode = processedCode.replaceAll(RegExp(r'</div>', caseSensitive: false), '\n')
                                   .replaceAll(RegExp(r'</tr>', caseSensitive: false), '\n')
                                   .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
                                   .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
      
      processedCode = processedCode.replaceAll(RegExp(r'<[^>]+>'), '');
      
      processedCode = processedCode.replaceAll('&amp;', '&')
                                   .replaceAll('&lt;', '<')
                                   .replaceAll('&gt;', '>')
                                   .replaceAll('&quot;', '"')
                                   .replaceAll('&#39;', "'")
                                   .replaceAll('&nbsp;', ' ');
      
      final formattedBlock = '\n```$language\n$processedCode\n```\n';
      html = html.replaceFirst(placeholder, formattedBlock);
    }

    // 15. Clean up extra newlines
    html = html.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Restore <u> and </u>
    html = html.replaceAll('%%U_OPEN%%', '<u>')
               .replaceAll('%%U_CLOSE%%', '</u>');

    return html.trim();
  }

  void _keepPlainTextOnly() {
    final text = _contentController.text;
    final start = _lastPasteStartOffset;
    final end = start + _lastPasteFormattedLength;
    
    if (start >= 0 && end <= text.length) {
      final newText = text.replaceRange(start, end, _lastPastePlainText);
      setState(() {
        _contentController.text = newText;
        _showPasteOptions = false;
        _isDirty = true;
      });
      
      _contentController.selection = TextSelection.collapsed(
        offset: start + _lastPastePlainText.length,
      );
      
      _saveNote(isAutoSave: true);
    } else {
      setState(() {
        _showPasteOptions = false;
      });
    }
  }

  Widget _buildPasteOptionsBanner() {
    final theme = Theme.of(context);
    
    return Material(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.3),
      borderRadius: BorderRadius.circular(12),
      color: theme.colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.paste_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Pasted with formatting',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                TextButton(
                  onPressed: _keepPlainTextOnly,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Keep Text Only',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    setState(() {
                      _showPasteOptions = false;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _insertText(String prefix, String suffix) {
    if (_noteType == NoteType.mixed) {
      final block = _findFocusedBlock();
      if (block != null) {
        final ctrl = block.controller;
        final txt = ctrl.text;
        final sel = ctrl.selection;
        int start = sel.start;
        int end = sel.end;
        if (start < 0 || start > txt.length) {
          start = txt.length;
          end = txt.length;
        }
        final selectedText = txt.substring(start, end);
        final newTxt = txt.replaceRange(start, end, '$prefix$selectedText$suffix');
        ctrl.value = TextEditingValue(
          text: newTxt,
          selection: TextSelection.collapsed(offset: start + prefix.length + selectedText.length + suffix.length),
        );
        _syncBlocksToContent();
        return;
      }
    }
    final text = _contentController.text;
    final selection = _contentController.selection;
    
    int start = selection.start;
    int end = selection.end;
    
    if (start < 0 || start > text.length) {
      start = text.length;
      end = text.length;
    }
    
    final selectedText = text.substring(start, end);
    final newText = text.replaceRange(start, end, '$prefix$selectedText$suffix');
    
    _contentController.text = newText;
    
    // Position cursor after the inserted text
    _contentController.selection = TextSelection.collapsed(
      offset: (start + prefix.length + selectedText.length + suffix.length).toInt(),
    );
    
    _markDirty();
  }

  Widget _buildMarkdownToolbar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _toolbarButton(
              icon: Icons.format_bold,
              tooltip: 'Bold',
              onPressed: () => _insertText('**', '**'),
            ),
            _toolbarButton(
              icon: Icons.format_italic,
              tooltip: 'Italic',
              onPressed: () => _insertText('*', '*'),
            ),
            _toolbarButton(
              icon: Icons.format_underlined,
              tooltip: 'Underline',
              onPressed: () => _insertText('<u>', '</u>'),
            ),
            _toolbarButton(
              icon: Icons.format_strikethrough,
              tooltip: 'Strikethrough',
              onPressed: () => _insertText('~~', '~~'),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 1,
              height: 24,
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
            // Highlight button with color picker
            _buildHighlightButton(theme, isDark),
            // Text color button
            _buildTextColorButton(theme, isDark),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 1,
              height: 24,
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
            _toolbarButton(
              icon: Icons.title_rounded,
              tooltip: 'Heading 1',
              onPressed: () => _insertText('\n# ', ''),
            ),
            _toolbarButton(
              icon: Icons.subtitles_rounded,
              tooltip: 'Heading 2',
              onPressed: () => _insertText('\n## ', ''),
            ),
            _toolbarButton(
              icon: Icons.text_fields_rounded,
              tooltip: 'Heading 3',
              onPressed: () => _insertText('\n### ', ''),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 1,
              height: 24,
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
            _toolbarButton(
              icon: Icons.format_list_bulleted,
              tooltip: 'Bullet List',
              onPressed: () => _insertText('\n- ', ''),
            ),
            _toolbarButton(
              icon: Icons.format_list_numbered,
              tooltip: 'Numbered List',
              onPressed: () => _insertText('\n1. ', ''),
            ),
            _toolbarButton(
              icon: Icons.check_box_outlined,
              tooltip: 'Checklist Item',
              onPressed: () => _insertText('\n- [ ] ', ''),
            ),
            _toolbarButton(
              icon: Icons.format_quote_rounded,
              tooltip: 'Blockquote',
              onPressed: () => _insertText('\n> ', ''),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 1,
              height: 24,
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
            _toolbarButton(
              icon: Icons.code_rounded,
              tooltip: 'Inline Code',
              onPressed: () => _insertText('`', '`'),
            ),
            _toolbarButton(
              icon: Icons.data_object_rounded,
              tooltip: 'Code Block',
              onPressed: () => _insertText('\n```\n', '\n```\n'),
            ),
            _toolbarButton(
              icon: Icons.table_chart_outlined,
              tooltip: 'Insert Table',
              onPressed: () => _insertText('\n| Col 1 | Col 2 | Col 3 |\n|-------|-------|-------|\n| A | B | C |\n', ''),
            ),
            _toolbarButton(
              icon: Icons.image_outlined,
              tooltip: 'Insert Image',
              onPressed: _insertImageDialog,
            ),
            _toolbarButton(
              icon: Icons.horizontal_rule_rounded,
              tooltip: 'Divider',
              onPressed: () => _insertText('\n---\n', ''),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 1,
              height: 24,
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
            // ── Text Alignment (Fix 4) ──────────────────────────────────────
            _toolbarButton(
              icon: Icons.format_align_left_rounded,
              tooltip: 'Align Left',
              onPressed: () => _insertText('<div align="left">', '</div>'),
            ),
            _toolbarButton(
              icon: Icons.format_align_center_rounded,
              tooltip: 'Align Center',
              onPressed: () => _insertText('<div align="center">', '</div>'),
            ),
            _toolbarButton(
              icon: Icons.format_align_right_rounded,
              tooltip: 'Align Right',
              onPressed: () => _insertText('<div align="right">', '</div>'),
            ),
            _toolbarButton(
              icon: Icons.format_align_justify_rounded,
              tooltip: 'Justify',
              onPressed: () => _insertText('<div align="justify">', '</div>'),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 1,
              height: 24,
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
            // ── Paragraph Formatting (Fix 4) ────────────────────────────────
            _toolbarButton(
              icon: Icons.format_indent_increase_rounded,
              tooltip: 'Indent',
              onPressed: () {
                final text = _contentController.text;
                final sel = _contentController.selection;
                final start = sel.start < 0 ? 0 : sel.start;
                final lineStart = text.lastIndexOf('\n', start - 1) + 1;
                final newText = text.substring(0, lineStart) + '    ' + text.substring(lineStart);
                _contentController.value = TextEditingValue(
                  text: newText,
                  selection: TextSelection.collapsed(offset: start + 4),
                );
                _markDirty();
              },
            ),
            _toolbarButton(
              icon: Icons.format_indent_decrease_rounded,
              tooltip: 'Outdent',
              onPressed: () {
                final text = _contentController.text;
                final sel = _contentController.selection;
                final start = sel.start < 0 ? 0 : sel.start;
                final lineStart = text.lastIndexOf('\n', start - 1) + 1;
                final lineText = text.substring(lineStart);
                if (lineText.startsWith('    ')) {
                  final newText = text.substring(0, lineStart) + lineText.substring(4);
                  _contentController.value = TextEditingValue(
                    text: newText,
                    selection: TextSelection.collapsed(offset: (start - 4).clamp(lineStart, newText.length)),
                  );
                  _markDirty();
                }
              },
            ),
            _toolbarButton(
              icon: Icons.format_line_spacing_rounded,
              tooltip: 'Insert Line Break',
              onPressed: () => _insertText('\n\n', ''),
            ),
          ],
        ),
      ),
    );
  }

  // ── GentleNote grouped expandable toolbar ────────────────────────────────
  Widget _buildGentleNoteToolbar(ThemeData theme, bool isDark) {
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

    Widget subText(String text, String tooltip, VoidCallback onTap) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      );
    }

    Widget subRow() {
      switch (_activeToolbarGroup) {
        case 'format':
          return Row(
            children: [
              sub(Icons.format_bold, 'Bold', () => _insertText('**', '**')),
              sub(Icons.format_italic, 'Italic', () => _insertText('*', '*')),
              sub(Icons.format_underlined, 'Underline', () => _insertText('<u>', '</u>')),
              sub(Icons.format_strikethrough, 'Strikethrough', () => _insertText('~~', '~~')),
              sub(Icons.code_rounded, 'Inline Code', () => _insertText('`', '`')),
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
              subText('H1', 'Heading 1', () => _insertText('\n# ', '')),
              subText('H2', 'Heading 2', () => _insertText('\n## ', '')),
              subText('H3', 'Heading 3', () => _insertText('\n### ', '')),
              subText('H4', 'Heading 4', () => _insertText('\n#### ', '')),
            ],
          );
        case 'align':
          return Row(
            children: [
              sub(Icons.format_align_left_rounded, 'Align Left', () => _applyLineAlignment('left')),
              sub(Icons.format_align_center_rounded, 'Align Center', () => _applyLineAlignment('center')),
              sub(Icons.format_align_right_rounded, 'Align Right', () => _applyLineAlignment('right')),
              sub(Icons.format_align_justify_rounded, 'Justify', () => _applyLineAlignment('justify')),
            ],
          );
        case 'lists':
          return Row(
            children: [
              sub(Icons.format_list_bulleted, 'Bullet List', () => _insertText('\n- ', '')),
              sub(Icons.format_list_numbered, 'Numbered List', () => _insertText('\n1. ', '')),
              sub(Icons.check_box_outlined, 'Checklist', () => _insertText('\n- [ ] ', '')),
              sub(Icons.format_quote_rounded, 'Blockquote', () => _insertText('\n> ', '')),
            ],
          );
        case 'insert':
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                sub(Icons.image_outlined, 'Insert Image', _insertImageDialog),
                sub(Icons.table_chart_outlined, 'Insert Table', () => _insertText('\n| Col 1 | Col 2 | Col 3 |\n|-------|-------|-------|\n| A | B | C |\n', '')),
                sub(Icons.horizontal_rule_rounded, 'Divider', () => _insertText('\n---\n', '')),
                sub(Icons.data_object_rounded, 'Code Block', () => _insertText('\n```\n', '\n```\n')),
                sub(Icons.mic_outlined, 'Voice Note', _toggleVoiceRecording),
                sub(Icons.draw_outlined, 'Drawing', () => _openDrawingCanvas()),
              ],
            ),
          );
        case 'indent':
          return Row(
            children: [
              sub(Icons.format_indent_increase_rounded, 'Indent', () {
                final text = _contentController.text;
                final sel = _contentController.selection;
                final start = sel.start < 0 ? 0 : sel.start;
                final lineStart = text.lastIndexOf('\n', start - 1) + 1;
                final newText = text.substring(0, lineStart) + '    ' + text.substring(lineStart);
                _contentController.value = TextEditingValue(
                  text: newText,
                  selection: TextSelection.collapsed(offset: start + 4),
                );
                _markDirty();
              }),
              sub(Icons.format_indent_decrease_rounded, 'Outdent', () {
                final text = _contentController.text;
                final sel = _contentController.selection;
                final start = sel.start < 0 ? 0 : sel.start;
                final lineStart = text.lastIndexOf('\n', start - 1) + 1;
                final lineText = text.substring(lineStart);
                if (lineText.startsWith('    ')) {
                  final newText = text.substring(0, lineStart) + lineText.substring(4);
                  _contentController.value = TextEditingValue(
                    text: newText,
                    selection: TextSelection.collapsed(offset: (start - 4).clamp(lineStart, newText.length)),
                  );
                  _markDirty();
                }
              }),
              sub(Icons.format_line_spacing_rounded, 'Line Break', () => _insertText('\n\n', '')),
            ],
          );
      }
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: borderColor)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Group icon row
          Row(
            children: groups
                .map((g) => groupBtn(g.$1, g.$2, g.$3))
                .toList(),
          ),
          // Expanded sub-tools row
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

  // ── Custom Color Picker Helper (Fix 6) ───────────────────────────────────
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
                // Handle
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
                // Preset colors grid
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
                // Preview
                if (previewBuilder != null) ...[
                  Text('Preview', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  previewBuilder(previewColor),
                  const SizedBox(height: 16),
                ],
                // Custom hex input
                Text('Custom Color', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: previewColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: hexController,
                        decoration: InputDecoration(
                          labelText: 'Hex Color (e.g. #FF5733)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                          prefixText: '',
                        ),
                        onChanged: (val) {
                          final hex = val.trim().replaceAll('#', '');
                          if (hex.length == 6) {
                            try {
                              final color = Color(int.parse('FF$hex', radix: 16));
                              setModalState(() => previewColor = color);
                            } catch (_) {}
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      selectedColor = previewColor;
                      Navigator.pop(ctx2);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Apply Color', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    return selectedColor;
  }

  // Highlight color picker button (Fix 6)
  Widget _buildHighlightButton(ThemeData theme, bool isDark) {
    final highlights = [
      const Color(0xFFFFFF00), // Yellow
      const Color(0xFFADFF2F), // Green
      const Color(0xFF87CEEB), // Blue
      const Color(0xFFFFB6C1), // Pink
      const Color(0xFFFFD700), // Gold
      const Color(0xFFFFA07A), // Salmon
      const Color(0xFF98FB98), // Pale Green
      const Color(0xFFDDA0DD), // Plum
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
          if (color != null) {
            final hexStr = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
            _insertText('<mark style="background:$hexStr">', '</mark>');
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

  // Text color picker button (Fix 6)
  Widget _buildTextColorButton(ThemeData theme, bool isDark) {
    final textColors = [
      const Color(0xFFEF4444), // Red
      const Color(0xFFF97316), // Orange
      const Color(0xFFEAB308), // Yellow
      const Color(0xFF22C55E), // Green
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFF6B7280), // Gray
      const Color(0xFF111827), // Near-black
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF14B8A6), // Teal
      const Color(0xFFF59E0B), // Amber
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
          if (color != null) {
            final hexStr = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
            _insertText('<span style="color:$hexStr">', '</span>');
          }
        },
        child: const Padding(
          padding: EdgeInsets.all(6.0),
          child: Icon(Icons.format_color_text, size: 18),
        ),
      ),
    );
  }



  Widget _toolbarButton({required IconData icon, required String tooltip, required VoidCallback onPressed}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          icon: Icon(icon, size: 20),
          onPressed: onPressed,
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  // ── Full-screen toggle ────────────────────────────────────────────────────
  void _toggleFullScreen() {
    final newValue = !_isFullScreen;
    setState(() => _isFullScreen = newValue);
    if (newValue) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  // ── Focus mode body (Zen / simple writing) ────────────────────────────────
  Widget _buildFocusModeBody() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090B16) : const Color(0xFFF8F6FF),
      body: SafeArea(
        child: Column(
          children: [
            // Top Action Bar with all options
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
                          // Voice Note button
                          IconButton(
                            icon: Icon(
                              _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                              color: _isRecording ? const Color(0xFFF87171) : const Color(0xFF8B5CF6),
                            ),
                            tooltip: _isRecording ? 'Stop Recording' : 'Record Voice Note',
                            onPressed: _toggleVoiceRecording,
                          ),
                          // Drawing button
                          IconButton(
                            icon: const Icon(Icons.draw_rounded, color: Color(0xFF8B5CF6)),
                            tooltip: 'Open Drawing Canvas',
                            onPressed: _openDrawingCanvas,
                          ),
                          // Calendar / Reminder button
                          IconButton(
                            icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF8B5CF6)),
                            tooltip: 'Calendar & Reminders',
                            onPressed: () => context.push('/calendar'),
                          ),
                          // Focus mode exit
                          TextButton.icon(
                            onPressed: () => setState(() => _isFocusMode = false),
                            icon: const Icon(Icons.grid_view_rounded, size: 16),
                            label: const Text('Block Editor'),
                            style: TextButton.styleFrom(
                              foregroundColor: isDark ? const Color(0xFF6B5F8A) : const Color(0xFFAA9ECC),
                              textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          // Fullscreen button
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
            // Formatting toolbar
            _buildMarkdownToolbar(),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
              child: TextField(
                controller: _titleController,
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
            // Content (single block)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 4, 28, 0),
                child: TextField(
                  controller: _contentController,
                  focusNode: _editorFocusNode,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15.5,
                    color: isDark ? const Color(0xFFCDD6F4) : const Color(0xFF374151),
                    height: 1.65,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Start writing…',
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15.5,
                      color: isDark ? const Color(0xFF3D3557) : const Color(0xFFD1CBE8),
                      height: 1.65,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) {
                    if (_noteType == NoteType.mixed) {
                      _blocks = _parseMarkdownToBlocks(_contentController.text);
                    }
                    _markDirty();
                  },
                ),
              ),
            ),
            // ── Bottom action bar ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D0B18) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF1E1A30) : const Color(0xFFEDE9FE),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Scrollable image buttons
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _focusActionButton(
                            icon: Icons.photo_library_outlined,
                            label: 'Gallery',
                            isDark: isDark,
                            onTap: () => _pickAndInsertLocalImage(ImageSource.gallery, 'medium', 'center'),
                          ),
                          const SizedBox(width: 8),
                          _focusActionButton(
                            icon: Icons.camera_alt_outlined,
                            label: 'Camera',
                            isDark: isDark,
                            onTap: () => _pickAndInsertLocalImage(ImageSource.camera, 'medium', 'center'),
                          ),
                          const SizedBox(width: 8),
                          _focusActionButton(
                            icon: Icons.add_photo_alternate_outlined,
                            label: 'Insert',
                            isDark: isDark,
                            onTap: _insertImageDialog,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Word count (fixed right side)
                  Text(
                    '${(_blocks.isNotEmpty ? _blocks.first.controller.text : _contentController.text).trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length} words',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: isDark ? const Color(0xFF3D3557) : const Color(0xFFAA9ECC),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _focusActionButton({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1628) : const Color(0xFFF3F0FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF2E2845) : const Color(0xFFD4C8F5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF8B5CF6)),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B5CF6),
              ),
            ),
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
            // Background image layer
            if (_previewBgImagePath != null)
              Positioned.fill(
                child: Image.file(io.File(_previewBgImagePath!), fit: BoxFit.cover),
              ),
            // Overlay layer
            if (_previewOverlayOpacity > 0.0)
              Positioned.fill(
                child: ColoredBox(
                    color: _previewOverlayColor.withOpacity(_previewOverlayOpacity)),
              ),
            // Preview style layer
            if (_previewStyle != PreviewStyle.plain)
              Positioned.fill(
                child: CustomPaint(painter: _PreviewStylePainter(_previewStyle)),
              ),

            // Content column
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
                            // Painter lives ONLY inside the content area so y=0 = text start
                            if (_previewStyle != PreviewStyle.plain)
                              Positioned.fill(
                                child: CustomPaint(painter: _PreviewStylePainter(_previewStyle)),
                              ),
                            Padding(
                              padding: _styleContentPadding(_previewStyle),
                              child: MarkdownWidget(
                                data: _contentController.text.isEmpty
                                    ? '*Empty*'
                                    : _contentController.text,
                                attachments: _attachments,
                              ),
                            ),
                          ],
                        )
                      : _buildEditorBody(context),
                ),
              ],
            ),

            // Floating top-right controls
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
                top: 52, right: 8,
                child: _buildBgColorPicker(theme),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBgColorPicker(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final colors = <Color?>[
      null, Colors.white, const Color(0xFFF8F6FF), const Color(0xFFFFF8F0),
      const Color(0xFFF0FFF4), const Color(0xFFF0F8FF), const Color(0xFF1E1B2E),
      const Color(0xFF0D1117), const Color(0xFF1A1A2E),
    ];
    final overlayColors = [
      Colors.black, Colors.white, const Color(0xFF8B5CF6),
      const Color(0xFF1E3A5F), const Color(0xFF3B0764), const Color(0xFF064E3B),
    ];

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(18),
      color: isDark ? const Color(0xFF13111C) : Colors.white,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? const Color(0xFF252234) : const Color(0xFFE9E6F5)),
        ),
        child: DefaultTabController(
          length: 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                tabs: const [
                  Tab(text: 'Color'),
                  Tab(text: 'Image'),
                  Tab(text: 'Overlay'),
                ],
                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                indicatorColor: const Color(0xFF8B5CF6),
                labelColor: const Color(0xFF8B5CF6),
                unselectedLabelColor: Colors.grey,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 185,
                child: TabBarView(
                  children: [
                    // ── Color Tab ────────────────────────────────────────────
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: colors.map((c) {
                              final isSelected = _previewBgColor == c && _previewBgImagePath == null;
                              return GestureDetector(
                                onTap: () => setState(() {
                                  _previewBgColor = c;
                                  _previewBgImagePath = null;
                                }),
                                child: Container(
                                  width: 30, height: 30,
                                  decoration: BoxDecoration(
                                    color: c ?? (isDark ? const Color(0xFF13111C) : const Color(0xFFF5F5F5)),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF8B5CF6)
                                          : (isDark ? const Color(0xFF3D3557) : Colors.grey.shade300),
                                      width: isSelected ? 2.5 : 1,
                                    ),
                                  ),
                                  child: isSelected ? const Icon(Icons.check, size: 14, color: Color(0xFF8B5CF6)) : null,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          // Custom hex color input (Fix 6)
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Custom hex e.g. #F3E8FF',
                              hintStyle: const TextStyle(fontSize: 10, color: Colors.grey),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 11),
                            onSubmitted: (val) {
                              final hex = val.trim().replaceAll('#', '');
                              if (hex.length == 6) {
                                try {
                                  final color = Color(int.parse('FF$hex', radix: 16));
                                  setState(() {
                                    _previewBgColor = color;
                                    _previewBgImagePath = null;
                                  });
                                } catch (_) {}
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    // ── Image Tab ─────────────────────────────────────────────
                    SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_previewBgImagePath != null && !kIsWeb)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                io.File(_previewBgImagePath!),
                                height: 60, width: double.infinity, fit: BoxFit.cover,
                              ),
                            )
                          else if (_previewBgImagePath != null && kIsWeb)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _previewBgImagePath!,
                                height: 60, width: double.infinity, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 32, color: Colors.grey),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final picker = ImagePicker();
                                  final img = await picker.pickImage(source: ImageSource.gallery);
                                  if (img != null) {
                                    if (kIsWeb) {
                                      // Web: read as bytes and create a data URL (Fix 7)
                                      final bytes = await img.readAsBytes();
                                      final ext = img.name.split('.').last.toLowerCase();
                                      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
                                      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
                                      setState(() {
                                        _previewBgImagePath = dataUrl;
                                        _previewBgColor = null;
                                        _showBgPicker = false;
                                      });
                                    } else {
                                      // Native: copy to app docs dir (Fix 7)
                                      final appDir = await getApplicationDocumentsDirectory();
                                      final ext = img.name.split('.').last.toLowerCase();
                                      final fileName = 'bg_${const Uuid().v4()}.$ext';
                                      final savedFile = io.File('${appDir.path}/$fileName');
                                      final bytes = await img.readAsBytes();
                                      await savedFile.writeAsBytes(bytes);
                                      setState(() {
                                        _previewBgImagePath = savedFile.path;
                                        _previewBgColor = null;
                                        _showBgPicker = false;
                                      });
                                    }
                                  }
                                },
                                icon: const Icon(Icons.photo_library_outlined, size: 16),
                                label: const Text('Pick Image', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF8B5CF6)),
                                  foregroundColor: const Color(0xFF8B5CF6),
                                ),
                              ),
                              if (_previewBgImagePath != null) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFFF87171)),
                                  onPressed: () => setState(() => _previewBgImagePath = null),
                                  tooltip: 'Remove image',
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Overlay Tab ───────────────────────────────────────────
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Overlay Color',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: overlayColors.map((c) {
                            final isSelected = _previewOverlayColor == c;
                            return GestureDetector(
                              onTap: () => setState(() => _previewOverlayColor = c),
                              child: Container(
                                width: 26, height: 26,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade400,
                                    width: isSelected ? 2.5 : 1,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Opacity', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Expanded(
                              child: Slider(
                                value: _previewOverlayOpacity,
                                min: 0, max: 0.85,
                                activeColor: const Color(0xFF8B5CF6),
                                inactiveColor: Colors.grey.shade300,
                                onChanged: (v) => setState(() => _previewOverlayOpacity = v),
                              ),
                            ),
                            Text('${(_previewOverlayOpacity * 100).round()}%',
                                style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final folders = ref.watch(foldersProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = theme.brightness == Brightness.dark;
    
    // Ensure the WYSIWYG controller uses the active user settings for the code theme
    _contentController.activeCodeTheme = settings.activeCodeTheme;


    // Removed: no longer auto-activate focus mode for empty notes
    // Users can manually switch to focus mode via the toolbar button

    // ── FULLSCREEN MODE ───────────────────────────────────────────────────────
    if (_isFullScreen) {
      return _buildFullScreenBody();
    }

    // ── FOCUS MODE ────────────────────────────────────────────────────────────
    if (_isFocusMode) {
      return _buildFocusModeBody();
    }

    final colors = [
      '#FFFFFF', // White
      '#FEE2E2', // Light Red
      '#FEF3C7', // Light Amber
      '#ECFDF5', // Light Emerald
      '#E0F2FE', // Light Blue
      '#F3E8FF', // Light Purple
      '#FDF4FF', // Light Pink
    ];

    return GentleScaffold(
      title: _isEditMode ? 'Edit Note' : 'New Note',
      showBackButton: true,
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
                    // Voice Note button
                    IconButton(
                      icon: Icon(
                        _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        color: _isRecording ? const Color(0xFFF87171) : const Color(0xFF8B5CF6),
                      ),
                      tooltip: _isRecording ? 'Stop Recording' : 'Record Voice Note',
                      onPressed: _toggleVoiceRecording,
                    ),
                    // Drawing button
                    IconButton(
                      icon: const Icon(Icons.draw_rounded, color: Color(0xFF8B5CF6)),
                      tooltip: 'Open Drawing Canvas',
                      onPressed: _openDrawingCanvas,
                    ),
                    // Calendar / Reminder button
                    IconButton(
                      icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF8B5CF6)),
                      tooltip: 'Calendar & Reminders',
                      onPressed: () => context.push('/calendar'),
                    ),
                    // Preview Style button
                    PopupMenuButton<PreviewStyle>(
                      tooltip: 'Preview Style',
                      icon: const Icon(Icons.style_rounded, color: Color(0xFF8B5CF6)),
                      onSelected: (style) => setState(() => _previewStyle = style),
                      itemBuilder: (ctx) => [
                        _previewStyleMenuItem(PreviewStyle.plain, Icons.article_outlined, 'Plain'),
                        _previewStyleMenuItem(PreviewStyle.notebook, Icons.menu_book_outlined, 'Notebook Lines'),
                        _previewStyleMenuItem(PreviewStyle.grid, Icons.grid_on_rounded, 'Graph Paper'),
                        _previewStyleMenuItem(PreviewStyle.leaf, Icons.eco_outlined, 'Aged Paper'),
                        _previewStyleMenuItem(PreviewStyle.spiral, Icons.view_agenda_outlined, 'Spiral Notebook'),
                        _previewStyleMenuItem(PreviewStyle.dark, Icons.nights_stay_outlined, 'Dark Parchment'),
                      ],
                    ),
                    // Preview toggle button (Fix 2)
                    IconButton(
                      icon: Icon(
                        _isPreviewMode ? Icons.edit_note_rounded : Icons.preview_rounded,
                        color: _isPreviewMode ? const Color(0xFF10B981) : const Color(0xFF8B5CF6),
                      ),
                      tooltip: _isPreviewMode ? 'Back to Editor' : 'Preview (Reader View)',
                      onPressed: () => setState(() => _isPreviewMode = !_isPreviewMode),
                    ),
                    // Focus mode button
                    IconButton(
                      icon: const Icon(Icons.spa_rounded),
                      tooltip: 'Focus Mode (Zen Writing)',
                      color: const Color(0xFF8B5CF6),
                      onPressed: () => setState(() => _isFocusMode = true),
                    ),
                    // Fullscreen button
                    IconButton(
                      icon: Icon(_isFullScreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded),
                      tooltip: _isFullScreen ? 'Exit Fullscreen' : 'Fullscreen',
                      onPressed: _toggleFullScreen,
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
          // 1. Title Input & Controls (Folder, Color, Note Type Selector)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'Note Title...',
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    fillColor: Colors.transparent,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Metadata Row: Folder, Note Type, Color Hex
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Folder Dropdown
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

                      // Note Type Dropdown
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

                      // Background Color Circle Selector
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
              ],
            ),
          ),
          
          const Divider(height: 1),

          // 2. Note editor pane
          Expanded(
            child: _buildEditorBody(context),
          ),
          
          const Divider(height: 1),

          // 3. Tags Input Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Icon(Icons.local_offer_outlined, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _tagController,
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
      if (_showPasteOptions)
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: _buildPasteOptionsBanner(),
        ),
    ]),
  );
}

  Widget _buildEditorBody(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ── PREVIEW MODE (Fix 2) — User-facing rendered view, no markdown syntax ──
    if (_isPreviewMode) {
      final bgColor = _previewBgColor ?? theme.scaffoldBackgroundColor;
      return Stack(
        children: [
          // Background
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
              child: CustomPaint(painter: _PreviewStylePainter(_previewStyle)),
            ),
          // Note title + content
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
                        child: CustomPaint(painter: _PreviewStylePainter(_previewStyle)),
                      ),
                    Padding(
                      padding: _styleContentPadding(_previewStyle),
                      child: MarkdownWidget(
                        data: _contentController.text.isEmpty ? '*Nothing here yet…*' : _contentController.text,
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

    // A. CODE SNIPPET MODE
    if (_noteType == NoteType.code) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _contentController,
          maxLines: null,
          expands: true,
          style: const TextStyle(fontFamily: 'Courier', fontSize: 14, height: 1.4),
          decoration: const InputDecoration(
            hintText: '// Paste or write code snippet here...',
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            fillColor: Colors.transparent,
          ),
        ),
      );
    }

    // B. CHECKLIST MODE
    if (_noteType == NoteType.checklist) {
      final lines = _contentController.text.split('\n');
      return Column(
        children: [
          // Checklist Interactive Quick Editor
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lines.length,
              itemBuilder: (context, index) {
                final line = lines[index];
                final isUnchecked = line.startsWith('- [ ]') || line.startsWith('[ ]');
                final isChecked = line.startsWith('- [x]') || line.startsWith('[x]') || line.startsWith('- [X]') || line.startsWith('[X]');

                if (isChecked || isUnchecked) {
                  final text = line
                      .replaceFirst('- [ ]', '')
                      .replaceFirst('[ ]', '')
                      .replaceFirst('- [x]', '')
                      .replaceFirst('- [X]', '')
                      .replaceFirst('[x]', '')
                      .replaceFirst('[X]', '')
                      .trim();

                  return CheckboxListTile(
                    value: isChecked,
                    title: Text(
                      text,
                      style: TextStyle(
                        decoration: isChecked ? TextDecoration.lineThrough : null,
                        color: isChecked ? theme.colorScheme.onSurface.withOpacity(0.4) : null,
                      ),
                    ),
                    onChanged: (val) {
                      if (val != null) {
                        _toggleChecklistItem(index, isChecked);
                      }
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  );
                }

                // If standard text line, show standard bullet
                return ListTile(
                  leading: const Icon(Icons.radio_button_unchecked, size: 8),
                  title: Text(line),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Simple Textbox input to add checklist items easily
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onSubmitted: (val) {
                      final item = val.trim();
                      if (item.isEmpty) return;
                      final prefix = _contentController.text.isEmpty ? '' : '\n';
                      setState(() {
                        _contentController.text += '$prefix- [ ] $item';
                        _isDirty = true;
                      });
                      _saveNote(isAutoSave: true);
                    },
                    decoration: const InputDecoration(
                      hintText: 'Add new checklist item...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // C. MARKDOWN DOCUMENT MODE (pure markdown text editor)
    if (_noteType == NoteType.markdown) {
      final theme2 = Theme.of(context);
      final bgColor = _previewBgColor ?? theme2.scaffoldBackgroundColor;
      final editingPane = Stack(
        children: [
          if (_previewBgImagePath != null)
            Positioned.fill(
              child: _previewBgImagePath!.startsWith('data:image')
                  ? Image.memory(
                      base64Decode(_previewBgImagePath!.split(',').last),
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      io.File(_previewBgImagePath!),
                      fit: BoxFit.cover,
                    ),
            )
          else
            Positioned.fill(child: ColoredBox(color: bgColor)),
          if (_previewOverlayOpacity > 0.0)
            Positioned.fill(
              child: ColoredBox(color: _previewOverlayColor.withOpacity(_previewOverlayOpacity)),
            ),
          if (_previewStyle != PreviewStyle.plain)
            Positioned.fill(
              child: CustomPaint(painter: _PreviewStylePainter(_previewStyle)),
            ),
          Column(
            children: [
              _buildMarkdownToolbar(),
              Expanded(
                child: Padding(
                  padding: _styleContentPadding(_previewStyle).add(const EdgeInsets.all(16.0)),
                  child: TextField(
                    controller: _contentController,
                    focusNode: _editorFocusNode,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                    decoration: const InputDecoration(
                      hintText: 'Start writing...',
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      fillColor: Colors.transparent,
                    ),
                    onChanged: (_) {
                      _blocks = _parseMarkdownToBlocks(_contentController.text);
                      _markDirty();
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      );

      final previewPane = Stack(
        children: [
          // Background image (if set) or solid color (Fix 7)
          if (_previewBgImagePath != null)
            Positioned.fill(
              child: _previewBgImagePath!.startsWith('data:image')
                  ? Image.memory(
                      base64Decode(_previewBgImagePath!.split(',').last),
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      io.File(_previewBgImagePath!),
                      fit: BoxFit.cover,
                    ),
            )
          else
            Positioned.fill(child: ColoredBox(color: bgColor)),

          // Overlay color + opacity
          if (_previewOverlayOpacity > 0.0)
            Positioned.fill(
              child: ColoredBox(
                  color: _previewOverlayColor.withOpacity(_previewOverlayOpacity)),
            ),

          // Preview style painter (notebook lines, grid etc.)
          if (_previewStyle != PreviewStyle.plain)
            Positioned.fill(
              child: CustomPaint(painter: _PreviewStylePainter(_previewStyle)),
            ),

          // Actual content
          Padding(
            padding: _styleContentPadding(_previewStyle),
            child: MarkdownWidget(
              data: _contentController.text.isEmpty ? '*Empty Preview*' : _contentController.text,
              attachments: _attachments,
            ),
          ),
          // Background color picker button
          Positioned(
            bottom: 12,
            right: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_showBgPicker) _buildBgColorPicker(theme2),
                const SizedBox(height: 6),
                FloatingActionButton.small(
                  heroTag: 'bgColorBtn',
                  onPressed: () => setState(() => _showBgPicker = !_showBgPicker),
                  backgroundColor: theme2.colorScheme.surfaceVariant,
                  foregroundColor: _previewBgColor != null
                      ? theme2.colorScheme.primary
                      : theme2.colorScheme.onSurfaceVariant,
                  tooltip: 'Background Color',
                  child: const Icon(Icons.palette_outlined, size: 18),
                ),
              ],
            ),
          ),
        ],
      );

      return Column(
        children: [
          _buildLayoutSelector(),
          const Divider(height: 1),
          Expanded(
            child: _markdownLayout == MarkdownLayoutMode.editOnly
                ? editingPane
                : _markdownLayout == MarkdownLayoutMode.previewOnly
                    ? previewPane
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 720) {
                            return Row(
                              children: [
                                Expanded(child: editingPane),
                                const VerticalDivider(width: 1, thickness: 1),
                                Expanded(child: previewPane),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                Expanded(child: editingPane),
                                const Divider(height: 1, thickness: 1),
                                Expanded(child: previewPane),
                              ],
                            );
                          }
                        },
                      ),
          ),
        ],
      );
    }

    // D. GENTLE NOTE — WYSIWYG paper editor (NoteType.mixed)
    if (_noteType == NoteType.mixed) {
      final theme2 = Theme.of(context);
      final bgColor = _previewBgColor ?? theme2.scaffoldBackgroundColor;
      final isDark = theme2.brightness == Brightness.dark;
      return Stack(
        children: [
          // ── Background ────────────────────────────────────────────────────
          if (_previewBgImagePath != null)
            Positioned.fill(
              child: _previewBgImagePath!.startsWith('data:image')
                  ? Image.memory(
                      base64Decode(_previewBgImagePath!.split(',').last),
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      io.File(_previewBgImagePath!),
                      fit: BoxFit.cover,
                    ),
            )
          else
            Positioned.fill(child: ColoredBox(color: bgColor)),
          if (_previewOverlayOpacity > 0.0)
            Positioned.fill(
              child: ColoredBox(color: _previewOverlayColor.withOpacity(_previewOverlayOpacity)),
            ),
          if (_previewStyle != PreviewStyle.plain)
            Positioned.fill(
              child: CustomPaint(painter: _PreviewStylePainter(_previewStyle)),
            ),
          // ── Editor column ─────────────────────────────────────────────────
          Column(
            children: [
              _buildGentleNoteToolbar(theme2, isDark),
              Expanded(
                child: Padding(
                  padding: _styleContentPadding(_previewStyle).add(const EdgeInsets.fromLTRB(20, 12, 20, 16)),
                  child: TextField(
                    controller: _contentController,
                    focusNode: _editorFocusNode,
                    maxLines: null,
                    expands: true,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.75,
                      color: isDark ? Colors.white.withOpacity(0.92) : const Color(0xFF1A1A2E),
                      fontFamily: 'Georgia',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Write something beautiful...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white.withOpacity(0.25) : Colors.black.withOpacity(0.25),
                        fontStyle: FontStyle.italic,
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      fillColor: Colors.transparent,
                    ),
                    onChanged: (_) {
                      _blocks = _parseMarkdownToBlocks(_contentController.text);
                      _markDirty();
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // E. PLAIN TEXT (DEFAULT)
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _contentController,
        maxLines: null,
        expands: true,
        style: const TextStyle(fontSize: 15, height: 1.5),
        decoration: const InputDecoration(
          hintText: 'Write something here...',
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }

  // ── Voice Note Recording ──────────────────────────────────────────────────
  Future<void> _toggleVoiceRecording() async {
    if (_isRecording) {
      // Stop recording
      _recordingTimer?.cancel();
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordingPath = path;
      });
      if (path != null) {
        _showVoiceNotePreviewDialog(path);
      }
    } else {
      // Start recording
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Microphone permission required'),
            backgroundColor: Color(0xFFF87171),
          ));
        }
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'voice_${const Uuid().v4()}.m4a';
      final filePath = '${dir.path}/$fileName';
      await _audioRecorder.start(const RecordConfig(), path: filePath);
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _recordingDuration += const Duration(seconds: 1));
      });
    }
  }

  void _showVoiceNotePreviewDialog(String path) {
    final minutes = _recordingDuration.inMinutes.toString().padLeft(2, '0');
    final seconds = (_recordingDuration.inSeconds % 60).toString().padLeft(2, '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Voice Note Recorded'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic_rounded, size: 48, color: Color(0xFF8B5CF6)),
            const SizedBox(height: 8),
            Text('Duration: $minutes:$seconds',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow_rounded, size: 32, color: Color(0xFF8B5CF6)),
                  onPressed: () => _audioPlayer.play(DeviceFileSource(path)),
                ),
                IconButton(
                  icon: const Icon(Icons.stop_rounded, size: 28, color: Colors.grey),
                  onPressed: () => _audioPlayer.stop(),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Discard'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
            onPressed: () async {
              Navigator.pop(ctx);
              // Save as attachment
              final attachmentId = const Uuid().v4();
              final newAttachment = AttachmentModel(
                id: attachmentId,
                noteId: _noteId,
                type: AttachmentType.audio,
                name: 'Voice Note ($minutes:$seconds)',
                pathOrUrl: path,
                createdAt: DateTime.now(),
              );
              setState(() {
                _attachments = [..._attachments, newAttachment];
                _isDirty = true;
              });
              // Insert a voice note marker at cursor position (Fix 5)
              _insertText('\n\n[🎤 Voice Note: ${newAttachment.name}](audio://${newAttachment.id})\n\n', '');
              _saveNote(isAutoSave: true);
            },
            child: const Text('Attach to Note'),
          ),
        ],
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
              // Save the PNG as an attachment
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
                // Insert image reference at cursor position (Fix 5)
                _insertText('\n\n![Drawing | size=full | align=center](attachment://$attachmentId)\n\n', '');
                _saveNote(isAutoSave: true);
              }
            }
          },
        ),
      ),
    );
  }

  // ── Preview Style ─────────────────────────────────────────────────────────
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
      painter: _PreviewStylePainter(_previewStyle),
      child: content,
    );
  }


}

// Lightweight Markdown view wrapper to render markup
// Custom Markdown formatting handling and rendering system
class MarkdownWidget extends ConsumerWidget {
  final String data;
  final List<AttachmentModel> attachments;

  const MarkdownWidget({super.key, required this.data, required this.attachments});

  List<_CustomBlock> _parseContent(String content) {
    final List<_CustomBlock> blocks = [];
    final lines = content.split('\n');

    bool inCodeBlock = false;
    String codeLanguage = '';
    final List<String> currentCodeBlockLines = [];

    List<List<String>> currentTableRows = [];
    bool inTable = false;

    bool inMathBlock = false;
    final List<String> currentMathBlockLines = [];

    bool inDetails = false;
    String detailsSummary = 'Click to expand';
    final List<String> currentDetailsLines = [];

    final RegExp imageRegex = RegExp(r'!\[(.*?)\]\((.*?)\)');
    final RegExp hrRegex = RegExp(r'^\s*(\*|-|_)\s*\1\s*\1\s*(\1|\s)*$');

    for (var line in lines) {
      final trimmed = line.trim();

      // HTML details summary block
      if (trimmed.startsWith('<details>')) {
        inDetails = true;
        detailsSummary = 'Click to expand';
        continue;
      }
      if (inDetails) {
        if (trimmed.startsWith('<summary>') && trimmed.endsWith('</summary>')) {
          detailsSummary = trimmed.substring(9, trimmed.length - 10).trim();
          continue;
        }
        if (trimmed.startsWith('</details>')) {
          blocks.add(_CustomBlock(
            type: _BlockType.details,
            text: currentDetailsLines.join('\n'),
            altText: detailsSummary,
          ));
          currentDetailsLines.clear();
          inDetails = false;
          continue;
        }
        currentDetailsLines.add(line);
        continue;
      }

      // Block Math $$
      if (trimmed == '\$\$' || (trimmed.startsWith('\$\$') && trimmed.endsWith('\$\$') && trimmed.length > 2)) {
        if (inMathBlock) {
          blocks.add(_CustomBlock(
            type: _BlockType.math,
            text: currentMathBlockLines.join('\n'),
          ));
          currentMathBlockLines.clear();
          inMathBlock = false;
        } else {
          if (trimmed.startsWith('\$\$') && trimmed.endsWith('\$\$') && trimmed.length > 4) {
            final formula = trimmed.substring(2, trimmed.length - 2).trim();
            blocks.add(_CustomBlock(
              type: _BlockType.math,
              text: formula,
            ));
          } else {
            inMathBlock = true;
          }
        }
        continue;
      }

      if (inMathBlock) {
        currentMathBlockLines.add(line);
        continue;
      }

      // Fenced Code Blocks
      if (trimmed.startsWith('```')) {
        if (inCodeBlock) {
          blocks.add(_CustomBlock(
            type: _BlockType.code,
            text: currentCodeBlockLines.join('\n'),
            altText: codeLanguage,
          ));
          currentCodeBlockLines.clear();
          inCodeBlock = false;
        } else {
          inCodeBlock = true;
          codeLanguage = trimmed.substring(3).trim();
          if (codeLanguage.isEmpty) codeLanguage = 'code';
        }
        continue;
      }

      if (inCodeBlock) {
        currentCodeBlockLines.add(line);
        continue;
      }

      // Tables
      final isTableRow = trimmed.startsWith('|') && trimmed.endsWith('|');
      if (isTableRow) {
        if (!inTable) {
          inTable = true;
          currentTableRows = [];
        }
        final isDelimiter = RegExp(r'^\s*\|(?:\s*:?-+:?\s*\|)+\s*$').hasMatch(line);
        if (!isDelimiter) {
          final rawCells = line.split('|');
          if (rawCells.length > 2) {
            final cells = rawCells
                .sublist(1, rawCells.length - 1)
                .map((c) => c.trim())
                .toList();
            currentTableRows.add(cells);
          }
        }
        continue;
      } else {
        if (inTable) {
          if (currentTableRows.isNotEmpty) {
            blocks.add(_CustomBlock(
              type: _BlockType.table,
              text: '',
              tableData: List.from(currentTableRows),
            ));
          }
          currentTableRows.clear();
          inTable = false;
        }
      }

      // Horizontal Rules
      if (hrRegex.hasMatch(line)) {
        blocks.add(_CustomBlock(type: _BlockType.divider, text: ''));
        continue;
      }

      // Embedded HTML div block styling
      if (trimmed.startsWith('<div') && trimmed.endsWith('</div>')) {
        final content = trimmed.replaceAll(RegExp(r'<[^>]+>'), '').trim();
        blocks.add(_CustomBlock(type: _BlockType.paragraph, text: content));
        continue;
      }

      // Images
      final imageMatch = imageRegex.firstMatch(line);
      if (imageMatch != null) {
        final alt = imageMatch.group(1) ?? '';
        final url = imageMatch.group(2) ?? '';
        blocks.add(_CustomBlock(
          type: _BlockType.image,
          text: url,
          altText: alt,
        ));
        continue;
      }

      // Headings
      if (line.startsWith('# ')) {
        blocks.add(_CustomBlock(type: _BlockType.heading1, text: line.substring(2)));
      } else if (line.startsWith('## ')) {
        blocks.add(_CustomBlock(type: _BlockType.heading2, text: line.substring(3)));
      } else if (line.startsWith('### ')) {
        blocks.add(_CustomBlock(type: _BlockType.heading3, text: line.substring(4)));
      } else if (line.startsWith('#### ')) {
        blocks.add(_CustomBlock(type: _BlockType.heading4, text: line.substring(5)));
      } else if (line.startsWith('##### ')) {
        blocks.add(_CustomBlock(type: _BlockType.heading5, text: line.substring(6)));
      } else if (line.startsWith('###### ')) {
        blocks.add(_CustomBlock(type: _BlockType.heading6, text: line.substring(7)));
      }
      // Blockquotes
      else if (trimmed.startsWith('>')) {
        var content = trimmed;
        int level = 0;
        while (content.startsWith('>')) {
          level++;
          content = content.substring(1).trim();
        }
        blocks.add(_CustomBlock(
          type: _BlockType.blockquote,
          text: content,
          level: level,
        ));
      }
      // Checklists
      else if (trimmed.startsWith('- [ ]') || trimmed.startsWith('[ ]')) {
        final text = line.replaceFirst('- [ ]', '').replaceFirst('[ ]', '').trim();
        blocks.add(_CustomBlock(
          type: _BlockType.checklist,
          text: text,
          isChecked: false,
        ));
      } else if (trimmed.startsWith('- [x]') || trimmed.startsWith('[x]') || trimmed.startsWith('- [X]') || trimmed.startsWith('[X]')) {
        final text = line.replaceFirst('- [x]', '').replaceFirst('[x]', '').replaceFirst('- [X]', '').replaceFirst('[X]', '').trim();
        blocks.add(_CustomBlock(
          type: _BlockType.checklist,
          text: text,
          isChecked: true,
        ));
      }
      // Bullet lists
      else if (line.trimLeft().startsWith('- ') || line.trimLeft().startsWith('* ')) {
        final leadingSpaces = line.length - line.trimLeft().length;
        final text = line.trimLeft().substring(2);
        blocks.add(_CustomBlock(
          type: _BlockType.bullet,
          text: text,
          level: (leadingSpaces / 2).floor() + 1,
        ));
      }
      // Ordered lists
      else if (RegExp(r'^\s*(\d+)\.\s+(.*)').hasMatch(line)) {
        final match = RegExp(r'^\s*(\d+)\.\s+(.*)').firstMatch(line)!;
        final leadingSpaces = line.length - line.trimLeft().length;
        final num = match.group(1)!;
        final text = match.group(2)!;
        blocks.add(_CustomBlock(
          type: _BlockType.ordered,
          text: text,
          level: (leadingSpaces / 2).floor() + 1,
          altText: num,
        ));
      }
      // General paragraph
      else {
        if (trimmed.isEmpty) continue;
        blocks.add(_CustomBlock(type: _BlockType.paragraph, text: line));
      }
    }

    if (inTable && currentTableRows.isNotEmpty) {
      blocks.add(_CustomBlock(
        type: _BlockType.table,
        text: '',
        tableData: List.from(currentTableRows),
      ));
    }

    if (inCodeBlock && currentCodeBlockLines.isNotEmpty) {
      blocks.add(_CustomBlock(
        type: _BlockType.code,
        text: currentCodeBlockLines.join('\n'),
        altText: codeLanguage,
      ));
    }

    if (inMathBlock && currentMathBlockLines.isNotEmpty) {
      blocks.add(_CustomBlock(
        type: _BlockType.math,
        text: currentMathBlockLines.join('\n'),
      ));
    }

    return blocks;
  }

  Widget _buildBlockWidget(BuildContext context, _CustomBlock block, String activeCodeTheme, ThemeData theme) {
    final isDarkTheme = activeCodeTheme.contains('dark') || activeCodeTheme == 'monokai';

    switch (block.type) {
      case _BlockType.heading1:
        return Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: _renderInlineText(context, block.text, theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        );
      case _BlockType.heading2:
        return Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: _renderInlineText(context, block.text, theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        );
      case _BlockType.heading3:
        return Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: _renderInlineText(context, block.text, theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        );
      case _BlockType.heading4:
        return Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: _renderInlineText(context, block.text, theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        );
      case _BlockType.heading5:
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: _renderInlineText(context, block.text, theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        );
      case _BlockType.heading6:
        return Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 4),
          child: _renderInlineText(context, block.text, theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        );
      case _BlockType.divider:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Divider(thickness: 1.5, color: theme.colorScheme.outlineVariant),
        );
      case _BlockType.blockquote:
        return Padding(
          padding: EdgeInsets.only(left: 12.0 * block.level, top: 8, bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.5),
                  width: 3.5,
                ),
              ),
              color: theme.colorScheme.surfaceVariant.withOpacity(0.15),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _renderInlineText(context, block.text, theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant)),
          ),
        );
      case _BlockType.bullet:
        return Padding(
          padding: EdgeInsets.only(left: 16.0 * block.level, top: 4, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6, right: 8),
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: _renderInlineText(context, block.text, theme.textTheme.bodyMedium),
              ),
            ],
          ),
        );
      case _BlockType.ordered:
        return Padding(
          padding: EdgeInsets.only(left: 16.0 * block.level, top: 4, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${block.altText}. ', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              Expanded(
                child: _renderInlineText(context, block.text, theme.textTheme.bodyMedium),
              ),
            ],
          ),
        );
      case _BlockType.checklist:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                block.isChecked! ? Icons.check_box : Icons.check_box_outline_blank,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _renderInlineText(
                  context,
                  block.text,
                  theme.textTheme.bodyMedium?.copyWith(
                    decoration: block.isChecked! ? TextDecoration.lineThrough : null,
                    color: block.isChecked! ? theme.colorScheme.onSurface.withOpacity(0.5) : null,
                  ),
                ),
              ),
            ],
          ),
        );
      case _BlockType.math:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calculate_outlined, size: 14, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text(
                        'FORMULA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: isDarkTheme ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: block.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Formula copied to clipboard!'),
                          duration: Duration(seconds: 1),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    },
                    child: Text(
                      'COPY',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isDarkTheme ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: SelectableText(
                  block.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Georgia',
                    color: isDarkTheme ? Colors.white : Colors.black,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      case _BlockType.details:
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: ExpansionTile(
            title: Text(
              block.altText ?? 'Click to expand',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SelectionArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _parseContent(block.text).map((subBlock) {
                      return _buildBlockWidget(context, subBlock, activeCodeTheme, theme);
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      case _BlockType.code:
        final codeText = block.text;
        final language = block.altText ?? 'code';
        final highlighter = GentleSyntaxHighlighter(context, activeCodeTheme);
        final formattedSpan = highlighter.format(codeText);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDarkTheme ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      language.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: isDarkTheme ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: codeText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code copied to clipboard!'),
                            duration: Duration(seconds: 1),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.copy_rounded,
                            size: 12,
                            color: isDarkTheme ? Colors.grey.shade400 : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'COPY',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isDarkTheme ? Colors.grey.shade400 : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText.rich(
                    formattedSpan,
                  ),
                ),
              ),
            ],
          ),
        );
      case _BlockType.table:
        if (block.tableData == null || block.tableData!.isEmpty) return const SizedBox();
        final headers = block.tableData!.first;
        final rows = block.tableData!.skip(1).toList();

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(theme.colorScheme.surfaceVariant.withOpacity(0.3)),
              columns: headers.map((h) {
                return DataColumn(
                  label: _renderInlineText(context, h, theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                );
              }).toList(),
              rows: rows.map((row) {
                return DataRow(
                  cells: row.map((cell) {
                    return DataCell(
                      _renderInlineText(context, cell, theme.textTheme.bodyMedium),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        );
      case _BlockType.image:
        return _buildImageBlock(block);
      case _BlockType.paragraph:
      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: _renderInlineText(context, block.text, theme.textTheme.bodyMedium),
        );
    }
  }

  Widget _renderInlineText(BuildContext context, String text, TextStyle? baseStyle, {TextAlign textAlign = TextAlign.start}) {
    // Parse alignment from <div align="..."> HTML wrapper (Fix 4)
    TextAlign align = textAlign;
    String processedText = text;
    final divAlignMatch = RegExp(r'<div\s+align="(left|center|right|justify)">([\s\S]*?)</div>', caseSensitive: false).firstMatch(text);
    if (divAlignMatch != null) {
      final alignStr = divAlignMatch.group(1)!;
      processedText = divAlignMatch.group(2)!;
      switch (alignStr) {
        case 'center': align = TextAlign.center; break;
        case 'right': align = TextAlign.right; break;
        case 'justify': align = TextAlign.justify; break;
        default: align = TextAlign.left;
      }
    }
    final spans = _parseInlineSpans(context, processedText, baseStyle ?? const TextStyle());
    return RichText(
      text: TextSpan(children: spans),
      textAlign: align,
      textWidthBasis: TextWidthBasis.parent,
    );
  }

  List<InlineSpan> _parseInlineSpans(BuildContext context, String text, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];
    // Extended regex: adds <mark>, <span style="color:">, <u>, ~~, **, *, `, links
    final RegExp inlineRegex = RegExp(
      r'(\*\*\*.*?\*\*\*|\*\*.*?\*\*|\*.*?\*|~~.*?~~|`.*?`|<u>.*?</u>|<mark[^>]*>.*?</mark>|<span[^>]*>.*?</span>|\[.*?\]\(.*?\)|https?://\S+)',
      dotAll: true,
    );

    int lastIndex = 0;
    for (final match in inlineRegex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      final token = match.group(1)!;

      if (token.startsWith('***') && token.endsWith('***')) {
        spans.addAll(_parseInlineSpans(
          context,
          token.substring(3, token.length - 3),
          baseStyle.copyWith(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
        ));
      } else if (token.startsWith('**') && token.endsWith('**')) {
        spans.addAll(_parseInlineSpans(
          context,
          token.substring(2, token.length - 2),
          baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (token.startsWith('*') && token.endsWith('*')) {
        spans.addAll(_parseInlineSpans(
          context,
          token.substring(1, token.length - 1),
          baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (token.startsWith('~~') && token.endsWith('~~')) {
        spans.addAll(_parseInlineSpans(
          context,
          token.substring(2, token.length - 2),
          baseStyle.copyWith(decoration: TextDecoration.lineThrough),
        ));
      } else if (token.startsWith('`') && token.endsWith('`')) {
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: (baseStyle.fontSize ?? 14) - 1,
            backgroundColor: Colors.grey.shade200,
            color: Colors.red.shade800,
          ),
        ));
      } else if (token.startsWith('<u>') && token.endsWith('</u>')) {
        spans.addAll(_parseInlineSpans(
          context,
          token.substring(3, token.length - 4),
          baseStyle.copyWith(decoration: TextDecoration.underline),
        ));
      } else if (token.startsWith('<mark')) {
        // Parse: <mark style="background:#HEX">text</mark>
        final bgMatch = RegExp(r'background[:\s]*([#\w]+)').firstMatch(token);
        final innerMatch = RegExp(r'<mark[^>]*>(.*?)</mark>', dotAll: true).firstMatch(token);
        final innerText = innerMatch?.group(1) ?? token;
        Color bgColor = const Color(0xFFFFFF00);
        if (bgMatch != null) {
          final hexStr = bgMatch.group(1)!.replaceAll('#', '');
          if (hexStr.length == 6) bgColor = Color(int.parse('FF$hexStr', radix: 16));
        }
        spans.addAll(_parseInlineSpans(
          context, 
          innerText, 
          baseStyle.copyWith(backgroundColor: bgColor),
        ));
      } else if (token.startsWith('<span')) {
        // Parse: <span style="color:#HEX">text</span>
        final colorMatch = RegExp(r'color[:\s]*([#\w]+)').firstMatch(token);
        final innerMatch = RegExp(r'<span[^>]*>(.*?)</span>', dotAll: true).firstMatch(token);
        final innerText = innerMatch?.group(1) ?? token;
        Color textColor = baseStyle.color ?? Colors.black;
        if (colorMatch != null) {
          final hexStr = colorMatch.group(1)!.replaceAll('#', '');
          if (hexStr.length == 6) textColor = Color(int.parse('FF$hexStr', radix: 16));
        }
        spans.addAll(_parseInlineSpans(
          context, 
          innerText, 
          baseStyle.copyWith(color: textColor),
        ));
      } else if (token.startsWith('[') && token.contains('](')) {
        final closingBrace = token.indexOf(']');
        final label = token.substring(1, closingBrace);
        final url = token.substring(closingBrace + 2, token.length - 1);
        if (url.startsWith('audio://')) {
          final attachmentId = url.replaceFirst('audio://', '');
          final attachment = attachments.cast<AttachmentModel?>().firstWhere(
                (a) => a?.id == attachmentId,
                orElse: () => null,
              );
          if (attachment != null) {
            spans.add(WidgetSpan(
              child: InlineAudioPlayer(
                filePath: attachment.pathOrUrl,
                name: attachment.name,
              ),
            ));
          } else {
            spans.add(TextSpan(
              text: label,
              style: baseStyle.copyWith(color: Colors.red, decoration: TextDecoration.lineThrough),
            ));
          }
        } else {
          spans.add(WidgetSpan(
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening Link: $url'),
                    backgroundColor: Colors.blue,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Text(
                label,
                style: baseStyle.copyWith(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ));
        }
      } else {
        spans.add(WidgetSpan(
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening Link: $token'),
                  backgroundColor: Colors.blue,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Text(
              token,
              style: baseStyle.copyWith(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return spans;
  }

  Widget _buildImageBlock(_CustomBlock block) {
    var uriStr = block.text;

    if (uriStr.startsWith('attachment://')) {
      final attachmentId = uriStr.replaceFirst('attachment://', '');
      final attachment = attachments.cast<AttachmentModel?>().firstWhere(
            (a) => a?.id == attachmentId,
            orElse: () => null,
          );
      if (attachment != null) {
        uriStr = attachment.pathOrUrl;
      }
    }

    final altTextRaw = block.altText ?? '';
    String size = 'medium';
    String align = 'center';

    if (altTextRaw.contains('|')) {
      final parts = altTextRaw.split('|');
      for (var part in parts.skip(1)) {
        final trimmed = part.trim();
        if (trimmed.startsWith('size=')) {
          size = trimmed.substring('size='.length).trim();
        } else if (trimmed.startsWith('align=')) {
          align = trimmed.substring('align='.length).trim();
        }
      }
    }

    double? width;
    double? height;
    if (size == 'small') {
      width = 200;
      height = 150;
    } else if (size == 'large') {
      width = double.infinity;
    } else {
      width = 400;
      height = 300;
    }

    Alignment alignment = Alignment.center;
    if (align == 'left') {
      alignment = Alignment.centerLeft;
    } else if (align == 'right') {
      alignment = Alignment.centerRight;
    }

    Widget imageWidget;

    if (uriStr.startsWith('data:image')) {
      try {
        final base64Str = uriStr.split(',').last;
        final bytes = base64Decode(base64Str);
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey);
            },
          ),
        );
      } catch (e) {
        imageWidget = const Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey);
      }
    } else if (uriStr.startsWith('file://')) {
      final filePath = uriStr.replaceFirst('file://', '');
      if (kIsWeb) {
        imageWidget = const Text('[Local Image (Unavailable on Web)]');
      } else {
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            io.File(filePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey);
            },
          ),
        );
      }
    } else {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          uriStr,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey);
          },
        ),
      );
    }

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          width: width,
          height: size == 'large' ? null : height,
          constraints: size == 'large' ? const BoxConstraints(maxHeight: 450) : null,
          child: imageWidget,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final activeCodeTheme = settings.activeCodeTheme;
    final theme = Theme.of(context);

    final blocks = _parseContent(data);

    return SelectionArea(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: blocks.length,
        itemBuilder: (context, index) {
          final block = blocks[index];
          return _buildBlockWidget(context, block, activeCodeTheme, theme);
        },
      ),
    );
  }
}

enum _BlockType {
  paragraph,
  heading1,
  heading2,
  heading3,
  heading4,
  heading5,
  heading6,
  code,
  bullet,
  ordered,
  checklist,
  image,
  divider,
  blockquote,
  table,
  details,
  math;
}

class _CustomBlock {
  final _BlockType type;
  final String text;
  final String? altText;
  final bool? isChecked;
  final int level;
  final List<List<String>>? tableData;

  _CustomBlock({
    required this.type,
    required this.text,
    this.altText,
    this.isChecked,
    this.level = 0,
    this.tableData,
  });
}

enum NoteBlockType {
  paragraph,
  h1,
  h2,
  h3,
  h4,
  h5,
  h6,
  code,
  bullet,
  ordered,
  checklist,
  image,
  divider,
  blockquote,
  table,
  details,
  math;

  String get displayName {
    switch (this) {
      case NoteBlockType.paragraph: return 'Paragraph';
      case NoteBlockType.h1: return 'Heading 1';
      case NoteBlockType.h2: return 'Heading 2';
      case NoteBlockType.h3: return 'Heading 3';
      case NoteBlockType.h4: return 'Heading 4';
      case NoteBlockType.h5: return 'Heading 5';
      case NoteBlockType.h6: return 'Heading 6';
      case NoteBlockType.code: return 'Code Snippet';
      case NoteBlockType.bullet: return 'Bullet List';
      case NoteBlockType.ordered: return 'Numbered List';
      case NoteBlockType.checklist: return 'To-Do List';
      case NoteBlockType.image: return 'Image URL';
      case NoteBlockType.divider: return 'Divider';
      case NoteBlockType.blockquote: return 'Quote Block';
      case NoteBlockType.table: return 'Table Grid';
      case NoteBlockType.details: return 'Collapsible Group';
      case NoteBlockType.math: return 'Math Formula';
    }
  }

  IconData get icon {
    switch (this) {
      case NoteBlockType.paragraph: return Icons.notes;
      case NoteBlockType.h1: return Icons.title_rounded;
      case NoteBlockType.h2: return Icons.subtitles_rounded;
      case NoteBlockType.h3: return Icons.text_fields_rounded;
      case NoteBlockType.h4: return Icons.text_fields_rounded;
      case NoteBlockType.h5: return Icons.text_fields_rounded;
      case NoteBlockType.h6: return Icons.text_fields_rounded;
      case NoteBlockType.code: return Icons.code_rounded;
      case NoteBlockType.bullet: return Icons.format_list_bulleted_rounded;
      case NoteBlockType.ordered: return Icons.format_list_numbered_rounded;
      case NoteBlockType.checklist: return Icons.check_box_outlined;
      case NoteBlockType.image: return Icons.image_outlined;
      case NoteBlockType.divider: return Icons.horizontal_rule_rounded;
      case NoteBlockType.blockquote: return Icons.format_quote_rounded;
      case NoteBlockType.table: return Icons.table_chart_outlined;
      case NoteBlockType.details: return Icons.expand_more_rounded;
      case NoteBlockType.math: return Icons.calculate_outlined;
    }
  }
}

class NoteBlock {
  final String id;
  NoteBlockType type;
  late TextEditingController controller;
  late TextEditingController summaryController;
  late FocusNode focusNode;
  String? language; // For code blocks
  bool? isChecked; // For checklists
  int level; // For blockquotes/lists level
  List<List<String>>? tableData; // For tables
  String? url; // For images
  String? altText; // For images
  String? summary; // For details

  NoteBlock({
    required this.id,
    required this.type,
    required String text,
    this.language,
    this.isChecked,
    this.level = 1,
    this.tableData,
    this.url,
    this.altText,
    this.summary,
  }) {
    controller = TextEditingController(text: text);
    summaryController = TextEditingController(text: summary ?? '');
    focusNode = FocusNode();
  }
}

// Extension methods on _NoteEditorScreenState for the Block Editor
extension NoteEditorScreenBlockEditing on _NoteEditorScreenState {
  void _syncBlocksToContent() {
    final newContent = _serializeBlocksToMarkdown(_blocks);
    if (_contentController.text != newContent) {
      _contentController.text = newContent;
      _isDirty = true;
    }
  }

  void _insertBlock(int index, NoteBlockType type, {String text = ''}) {
    final newBlock = NoteBlock(
      id: const Uuid().v4(),
      type: type,
      text: text,
    );
    setState(() {
      _blocks.insert(index, newBlock);
      _isDirty = true;
    });
    _syncBlocksToContent();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      newBlock.focusNode.requestFocus();
    });
  }

  NoteBlock? _findFocusedBlock() {
    for (final block in _blocks) {
      if (block.focusNode.hasFocus) {
        return block;
      }
    }
    return null;
  }

  Widget _buildBlockEditor(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _blocks.length + 1, // +1 for "add block" button at bottom
      itemBuilder: (context, index) {
        if (index == _blocks.length) {
          // "Add Block" button at the bottom
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: TextButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add Block'),
                onPressed: () => _insertBlock(_blocks.length, NoteBlockType.paragraph),
              ),
            ),
          );
        }
        final block = _blocks[index];
        return _buildBlockEditorRow(context, block, index);
      },
    );
  }

  Widget _buildBlockEditorRow(BuildContext context, NoteBlock block, int index) {
    final theme = Theme.of(context);
    final textStyle = _getTextStyleForBlock(block, theme);
    final isDark = theme.brightness == Brightness.dark;

    final typeMenu = PopupMenuButton<NoteBlockType>(
      icon: Icon(block.type.icon, size: 18, color: theme.colorScheme.primary),
      tooltip: 'Change block type',
      onSelected: (NoteBlockType newType) {
        setState(() {
          block.type = newType;
          _isDirty = true;
          if (newType == NoteBlockType.code && block.language == null) {
            block.language = 'javascript';
          }
          if (newType == NoteBlockType.checklist && block.isChecked == null) {
            block.isChecked = false;
          }
          if (newType == NoteBlockType.table && block.tableData == null) {
            block.tableData = [
              ['Col 1', 'Col 2'],
              ['Cell A', 'Cell B'],
            ];
          }
          if (newType == NoteBlockType.image && block.url == null) {
            block.url = 'https://picsum.photos/400/300';
            block.altText = 'Placeholder Image';
          }
        });
        _syncBlocksToContent();
      },
      itemBuilder: (context) => NoteBlockType.values
          .map((type) => PopupMenuItem<NoteBlockType>(
                value: type,
                child: Row(
                  children: [
                    Icon(type.icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(type.displayName),
                  ],
                ),
              ))
          .toList(),
    );

    Widget inputWidget;
    switch (block.type) {
      case NoteBlockType.divider:
        inputWidget = Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: const Divider(thickness: 1.5),
        );
        break;

      case NoteBlockType.math:
        inputWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: block.controller,
              focusNode: block.focusNode,
              maxLines: null,
              style: const TextStyle(fontFamily: 'Courier', fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'LaTeX Formula (e.g. E = mc^2)...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (_) => _syncBlocksToContent(),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  block.controller.text.isEmpty ? 'Preview empty' : block.controller.text,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Georgia',
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        );
        break;

      case NoteBlockType.code:
        inputWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DropdownButton<String>(
                  value: block.language ?? 'javascript',
                  items: ['javascript', 'python', 'cpp', 'java', 'html', 'css', 'sql', 'yaml', 'bash', 'markdown']
                      .map((lang) => DropdownMenuItem(
                            value: lang,
                            child: Text(lang.toUpperCase(), style: const TextStyle(fontSize: 11)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      block.language = val;
                      _isDirty = true;
                    });
                    _syncBlocksToContent();
                  },
                ),
              ],
            ),
            TextField(
              controller: block.controller,
              focusNode: block.focusNode,
              maxLines: null,
              style: const TextStyle(fontFamily: 'Courier', fontSize: 13, height: 1.3),
              decoration: const InputDecoration(
                hintText: '// Paste or write code snippet here...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (_) => _syncBlocksToContent(),
            ),
          ],
        );
        break;

      case NoteBlockType.table:
        inputWidget = _buildTableEditorWidget(block);
        break;

      case NoteBlockType.image:
        inputWidget = _buildImageEditorWidget(block);
        break;

      case NoteBlockType.details:
        inputWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: block.summaryController,
              decoration: const InputDecoration(
                hintText: 'Collapsible Summary Title...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
              onChanged: (val) {
                block.summary = val;
                _syncBlocksToContent();
              },
            ),
            const SizedBox(height: 6),
            TextField(
              controller: block.controller,
              focusNode: block.focusNode,
              maxLines: null,
              style: textStyle,
              decoration: const InputDecoration(
                hintText: 'Collapsible content...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
              onChanged: (_) => _syncBlocksToContent(),
            ),
          ],
        );
        break;

      case NoteBlockType.checklist:
        inputWidget = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: block.isChecked ?? false,
              onChanged: (val) {
                setState(() {
                  block.isChecked = val;
                  _isDirty = true;
                });
                _syncBlocksToContent();
              },
            ),
            Expanded(
              child: TextField(
                controller: block.controller,
                focusNode: block.focusNode,
                maxLines: null,
                style: textStyle.copyWith(
                  decoration: (block.isChecked ?? false) ? TextDecoration.lineThrough : null,
                  color: (block.isChecked ?? false) ? theme.colorScheme.onSurface.withOpacity(0.4) : null,
                ),
                decoration: const InputDecoration(
                  hintText: 'To-do item...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (_) => _syncBlocksToContent(),
              ),
            ),
          ],
        );
        break;

      case NoteBlockType.blockquote:
        inputWidget = Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 3)),
          ),
          padding: const EdgeInsets.only(left: 8),
          child: TextField(
            controller: block.controller,
            focusNode: block.focusNode,
            maxLines: null,
            style: textStyle,
            decoration: const InputDecoration(
              hintText: 'Quote...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
            ),
            onChanged: (_) => _syncBlocksToContent(),
          ),
        );
        break;

      default:
        inputWidget = KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
              if (block.controller.text.isEmpty && index > 0) {
                setState(() {
                  _blocks.removeAt(index);
                  _isDirty = true;
                });
                _syncBlocksToContent();
                _blocks[index - 1].focusNode.requestFocus();
              }
            }
          },
          child: TextField(
            controller: block.controller,
            focusNode: block.focusNode,
            maxLines: null,
            style: textStyle,
            decoration: InputDecoration(
              hintText: '${block.type.displayName}...',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
            ),
            onSubmitted: (_) {
              _insertBlock(index + 1, NoteBlockType.paragraph);
            },
            onChanged: (_) => _syncBlocksToContent(),
          ),
        );
        break;
    }

    return Container(
      key: ValueKey(block.id),
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13111C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF7C3AED).withValues(alpha: 0.18)
              : const Color(0xFFE9E6F5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF7C3AED).withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag & type icon
            Padding(
              padding: const EdgeInsets.only(top: 10.0, left: 4),
              child: Icon(
                Icons.drag_indicator_rounded,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
              ),
            ),
            typeMenu,
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: inputWidget,
              ),
            ),
            // Inline actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    size: 16,
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  ),
                  tooltip: 'Add block below',
                  constraints: const BoxConstraints(maxWidth: 32, maxHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: () => _insertBlock(index + 1, NoteBlockType.paragraph),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: Color(0xFFF87171),
                  ),
                  tooltip: 'Delete block',
                  constraints: const BoxConstraints(maxWidth: 32, maxHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      _blocks.removeAt(index);
                      if (_blocks.isEmpty) {
                        _blocks.add(NoteBlock(id: const Uuid().v4(), type: NoteBlockType.paragraph, text: ''));
                      }
                      _isDirty = true;
                    });
                    _syncBlocksToContent();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableEditorWidget(NoteBlock block) {
    final theme = Theme.of(context);
    if (block.tableData == null || block.tableData!.isEmpty) {
      block.tableData = [
        ['Col 1', 'Col 2'],
        ['A', 'B']
      ];
    }
    final table = block.tableData!;
    final numCols = table.first.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            border: TableBorder.all(color: theme.colorScheme.outlineVariant),
            defaultColumnWidth: const FixedColumnWidth(120),
            children: List.generate(table.length, (rIndex) {
              final row = table[rIndex];
              return TableRow(
                children: List.generate(row.length, (cIndex) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: TextFormField(
                      key: ValueKey('table_${block.id}_${rIndex}_$cIndex'),
                      initialValue: row[cIndex],
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      ),
                      onChanged: (val) {
                        row[cIndex] = val;
                        _syncBlocksToContent();
                      },
                    ),
                  );
                }),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add Row', style: TextStyle(fontSize: 11)),
              onPressed: () {
                setState(() {
                  table.add(List.generate(numCols, (_) => ''));
                  _isDirty = true;
                });
                _syncBlocksToContent();
              },
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add Col', style: TextStyle(fontSize: 11)),
              onPressed: () {
                setState(() {
                  for (var row in table) {
                    row.add('');
                  }
                  _isDirty = true;
                });
                _syncBlocksToContent();
              },
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const Icon(Icons.remove, size: 14, color: Colors.red),
              label: const Text('Remove Row', style: TextStyle(fontSize: 11, color: Colors.red)),
              onPressed: () {
                if (table.length > 1) {
                  setState(() {
                    table.removeLast();
                    _isDirty = true;
                  });
                  _syncBlocksToContent();
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageEditorWidget(NoteBlock block) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: TextEditingController(text: block.url),
          decoration: const InputDecoration(
            labelText: 'Image URL',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
          onChanged: (val) {
            block.url = val;
            _syncBlocksToContent();
          },
        ),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(text: block.altText),
          decoration: const InputDecoration(
            labelText: 'Alt Text',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
          onChanged: (val) {
            block.altText = val;
            _syncBlocksToContent();
          },
        ),
        const SizedBox(height: 8),
        if (block.url != null && block.url!.isNotEmpty)
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Image.network(
              block.url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 36, color: Colors.grey)),
            ),
          ),
      ],
    );
  }

  TextStyle _getTextStyleForBlock(NoteBlock block, ThemeData theme) {
    switch (block.type) {
      case NoteBlockType.h1:
        return theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold) ?? const TextStyle();
      case NoteBlockType.h2:
        return theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold) ?? const TextStyle();
      case NoteBlockType.h3:
        return theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold) ?? const TextStyle();
      case NoteBlockType.h4:
        return theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold) ?? const TextStyle();
      case NoteBlockType.h5:
        return theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold) ?? const TextStyle();
      case NoteBlockType.h6:
        return theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold) ?? const TextStyle();
      case NoteBlockType.blockquote:
        return theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic) ?? const TextStyle();
      default:
        return theme.textTheme.bodyMedium ?? const TextStyle();
    }
  }

  List<NoteBlock> _parseMarkdownToBlocks(String content) {
    final List<NoteBlock> blocks = [];
    final lines = content.split('\n');

    bool inCodeBlock = false;
    String codeLanguage = '';
    final List<String> currentCodeBlockLines = [];

    List<List<String>> currentTableRows = [];
    bool inTable = false;

    bool inMathBlock = false;
    final List<String> currentMathBlockLines = [];

    bool inDetails = false;
    String detailsSummary = 'Click to expand';
    final List<String> currentDetailsLines = [];

    final RegExp imageRegex = RegExp(r'!\[(.*?)\]\((.*?)\)');
    final RegExp hrRegex = RegExp(r'^\s*(\*|-|_)\s*\1\s*\1\s*(\1|\s)*$');

    for (var line in lines) {
      final trimmed = line.trim();

      // HTML details summary block
      if (trimmed.startsWith('<details>')) {
        inDetails = true;
        detailsSummary = 'Click to expand';
        continue;
      }
      if (inDetails) {
        if (trimmed.startsWith('<summary>') && trimmed.endsWith('</summary>')) {
          detailsSummary = trimmed.substring(9, trimmed.length - 10).trim();
          continue;
        }
        if (trimmed.startsWith('</details>')) {
          blocks.add(NoteBlock(
            id: const Uuid().v4(),
            type: NoteBlockType.details,
            text: currentDetailsLines.join('\n'),
            summary: detailsSummary,
          ));
          currentDetailsLines.clear();
          inDetails = false;
          continue;
        }
        currentDetailsLines.add(line);
        continue;
      }

      // Block Math $$
      if (trimmed == '\$\$' || (trimmed.startsWith('\$\$') && trimmed.endsWith('\$\$') && trimmed.length > 2)) {
        if (inMathBlock) {
          blocks.add(NoteBlock(
            id: const Uuid().v4(),
            type: NoteBlockType.math,
            text: currentMathBlockLines.join('\n'),
          ));
          currentMathBlockLines.clear();
          inMathBlock = false;
        } else {
          if (trimmed.startsWith('\$\$') && trimmed.endsWith('\$\$') && trimmed.length > 4) {
            final formula = trimmed.substring(2, trimmed.length - 2).trim();
            blocks.add(NoteBlock(
              id: const Uuid().v4(),
              type: NoteBlockType.math,
              text: formula,
            ));
          } else {
            inMathBlock = true;
          }
        }
        continue;
      }

      if (inMathBlock) {
        currentMathBlockLines.add(line);
        continue;
      }

      // Fenced Code Blocks
      if (trimmed.startsWith('```')) {
        if (inCodeBlock) {
          blocks.add(NoteBlock(
            id: const Uuid().v4(),
            type: NoteBlockType.code,
            text: currentCodeBlockLines.join('\n'),
            language: codeLanguage,
          ));
          currentCodeBlockLines.clear();
          inCodeBlock = false;
        } else {
          inCodeBlock = true;
          codeLanguage = trimmed.substring(3).trim();
          if (codeLanguage.isEmpty) codeLanguage = 'javascript';
        }
        continue;
      }

      if (inCodeBlock) {
        currentCodeBlockLines.add(line);
        continue;
      }

      // Tables
      final isTableRow = trimmed.startsWith('|') && trimmed.endsWith('|');
      if (isTableRow) {
        if (!inTable) {
          inTable = true;
          currentTableRows = [];
        }
        final isDelimiter = RegExp(r'^\s*\|(?:\s*:?-+:?\s*\|)+\s*$').hasMatch(line);
        if (!isDelimiter) {
          final rawCells = line.split('|');
          if (rawCells.length > 2) {
            final cells = rawCells
                .sublist(1, rawCells.length - 1)
                .map((c) => c.trim())
                .toList();
            currentTableRows.add(cells);
          }
        }
        continue;
      } else {
        if (inTable) {
          if (currentTableRows.isNotEmpty) {
            blocks.add(NoteBlock(
              id: const Uuid().v4(),
              type: NoteBlockType.table,
              text: '',
              tableData: List.from(currentTableRows),
            ));
          }
          currentTableRows.clear();
          inTable = false;
        }
      }

      // Horizontal Rules
      if (hrRegex.hasMatch(line)) {
        blocks.add(NoteBlock(id: const Uuid().v4(), type: NoteBlockType.divider, text: ''));
        continue;
      }

      // Embedded HTML div block styling
      if (trimmed.startsWith('<div') && trimmed.endsWith('</div>')) {
        final content = trimmed.replaceAll(RegExp(r'<[^>]+>'), '').trim();
        blocks.add(NoteBlock(id: const Uuid().v4(), type: NoteBlockType.paragraph, text: content));
        continue;
      }

      // Images
      final imageMatch = imageRegex.firstMatch(line);
      if (imageMatch != null) {
        final alt = imageMatch.group(1) ?? '';
        final url = imageMatch.group(2) ?? '';
        blocks.add(NoteBlock(
          id: const Uuid().v4(),
          type: NoteBlockType.image,
          text: url,
          url: url,
          altText: alt,
        ));
        continue;
      }

      // Headings
      if (line.startsWith('# ')) {
        blocks.add(NoteBlock(id: const Uuid().v4(), type: NoteBlockType.h1, text: line.substring(2)));
      } else if (line.startsWith('## ')) {
        blocks.add(NoteBlock(id: const Uuid().v4(), type: NoteBlockType.h2, text: line.substring(3)));
      } else if (line.startsWith('### ')) {
        blocks.add(NoteBlock(id: const Uuid().v4(), type: NoteBlockType.h3, text: line.substring(4)));
      } else if (line.startsWith('#### ')) {
        blocks.add(NoteBlock(id: const Uuid().v4(), type: NoteBlockType.h4, text: line.substring(5)));
      } else if (line.startsWith('##### ')) {
        blocks.add(NoteBlock(id: const Uuid().v4(), type: NoteBlockType.h5, text: line.substring(6)));
      } else if (line.startsWith('###### ')) {
        blocks.add(NoteBlock(id: const Uuid().v4(), type: NoteBlockType.h6, text: line.substring(7)));
      }
      // Blockquotes
      else if (trimmed.startsWith('>')) {
        var content = trimmed;
        int level = 0;
        while (content.startsWith('>')) {
          level++;
          content = content.substring(1).trim();
        }
        blocks.add(NoteBlock(
          id: const Uuid().v4(),
          type: NoteBlockType.blockquote,
          text: content,
          level: level,
        ));
      }
      // Checklists
      else if (trimmed.startsWith('- [ ]') || trimmed.startsWith('[ ]')) {
        final text = line.replaceFirst('- [ ]', '').replaceFirst('[ ]', '').trim();
        blocks.add(NoteBlock(
          id: const Uuid().v4(),
          type: NoteBlockType.checklist,
          text: text,
          isChecked: false,
        ));
      } else if (trimmed.startsWith('- [x]') || trimmed.startsWith('[x]') || trimmed.startsWith('- [X]') || trimmed.startsWith('[X]')) {
        final text = line.replaceFirst('- [x]', '').replaceFirst('[x]', '').replaceFirst('- [X]', '').replaceFirst('[X]', '').trim();
        blocks.add(NoteBlock(
          id: const Uuid().v4(),
          type: NoteBlockType.checklist,
          text: text,
          isChecked: true,
        ));
      }
      // Bullet lists
      else if (line.trimLeft().startsWith('- ') || line.trimLeft().startsWith('* ')) {
        final leadingSpaces = line.length - line.trimLeft().length;
        final text = line.trimLeft().substring(2);
        blocks.add(NoteBlock(
          id: const Uuid().v4(),
          type: NoteBlockType.bullet,
          text: text,
          level: (leadingSpaces / 2).floor() + 1,
        ));
      }
      // Ordered lists
      else if (RegExp(r'^\s*(\d+)\.\s+(.*)').hasMatch(line)) {
        final match = RegExp(r'^\s*(\d+)\.\s+(.*)').firstMatch(line)!;
        final leadingSpaces = line.length - line.trimLeft().length;
        final text = match.group(2)!;
        blocks.add(NoteBlock(
          id: const Uuid().v4(),
          type: NoteBlockType.ordered,
          text: text,
          level: (leadingSpaces / 2).floor() + 1,
        ));
      }
      // General paragraph
      else {
        if (trimmed.isEmpty) {
          blocks.add(NoteBlock(id: const Uuid().v4(), type: NoteBlockType.paragraph, text: ''));
        } else {
          blocks.add(NoteBlock(id: const Uuid().v4(), type: NoteBlockType.paragraph, text: line));
        }
      }
    }

    if (inTable && currentTableRows.isNotEmpty) {
      blocks.add(NoteBlock(
        id: const Uuid().v4(),
        type: NoteBlockType.table,
        text: '',
        tableData: List.from(currentTableRows),
      ));
    }

    if (inCodeBlock && currentCodeBlockLines.isNotEmpty) {
      blocks.add(NoteBlock(
        id: const Uuid().v4(),
        type: NoteBlockType.code,
        text: currentCodeBlockLines.join('\n'),
        language: codeLanguage,
      ));
    }

    if (inMathBlock && currentMathBlockLines.isNotEmpty) {
      blocks.add(NoteBlock(
        id: const Uuid().v4(),
        type: NoteBlockType.math,
        text: currentMathBlockLines.join('\n'),
      ));
    }

    if (inDetails && currentDetailsLines.isNotEmpty) {
      blocks.add(NoteBlock(
        id: const Uuid().v4(),
        type: NoteBlockType.details,
        text: currentDetailsLines.join('\n'),
        summary: detailsSummary,
      ));
    }

    if (blocks.isEmpty) {
      blocks.add(NoteBlock(id: const Uuid().v4(), type: NoteBlockType.paragraph, text: ''));
    }

    return blocks;
  }

  String _serializeBlocksToMarkdown(List<NoteBlock> blocks) {
    final List<String> lines = [];
    for (final block in blocks) {
      final text = block.controller.text;
      switch (block.type) {
        case NoteBlockType.paragraph:
          lines.add(text);
          break;
        case NoteBlockType.h1:
          lines.add('# $text');
          break;
        case NoteBlockType.h2:
          lines.add('## $text');
          break;
        case NoteBlockType.h3:
          lines.add('### $text');
          break;
        case NoteBlockType.h4:
          lines.add('#### $text');
          break;
        case NoteBlockType.h5:
          lines.add('##### $text');
          break;
        case NoteBlockType.h6:
          lines.add('###### $text');
          break;
        case NoteBlockType.code:
          lines.add('```${block.language ?? "javascript"}');
          lines.add(text);
          lines.add('```');
          break;
        case NoteBlockType.bullet:
          final prefix = '  ' * (block.level - 1);
          lines.add('$prefix- $text');
          break;
        case NoteBlockType.ordered:
          final prefix = '  ' * (block.level - 1);
          lines.add('${prefix}1. $text');
          break;
        case NoteBlockType.checklist:
          final check = block.isChecked == true ? 'x' : ' ';
          lines.add('- [$check] $text');
          break;
        case NoteBlockType.image:
          final alt = block.altText ?? '';
          final url = block.url ?? text;
          lines.add('![$alt]($url)');
          break;
        case NoteBlockType.divider:
          lines.add('---');
          break;
        case NoteBlockType.blockquote:
          final prefix = '>' * block.level;
          lines.add('$prefix $text');
          break;
        case NoteBlockType.table:
          if (block.tableData != null && block.tableData!.isNotEmpty) {
            final headers = block.tableData!.first;
            final headerStr = '| ${headers.join(' | ')} |';
            lines.add(headerStr);
            final separatorStr = '| ${headers.map((_) => '---').join(' | ')} |';
            lines.add(separatorStr);
            for (final row in block.tableData!.skip(1)) {
              lines.add('| ${row.join(' | ')} |');
            }
          }
          break;
        case NoteBlockType.details:
          lines.add('<details>');
          lines.add('<summary>${block.summary ?? "Click to expand"}</summary>');
          lines.add(text);
          lines.add('</details>');
          break;
        case NoteBlockType.math:
          lines.add('\$\$');
          lines.add(text);
          lines.add('\$\$');
          break;
      }
    }
    return lines.join('\n');
  }
}

enum MarkdownLayoutMode {
  editOnly,
  splitView,
  previewOnly,
}



// ─── Preview Style Enum ────────────────────────────────────────────────────────
enum PreviewStyle { plain, notebook, grid, leaf, spiral, dark }

// ─── Preview Style Painter ─────────────────────────────────────────────────────
// NOTE: This painter is intentionally placed only over the *content* area
// (below the note title/divider), so y=0 here corresponds to where text begins.
class _PreviewStylePainter extends CustomPainter {
  final PreviewStyle style;
  _PreviewStylePainter(this.style);

  // Line spacing matches body text: 14px font × height:2.0 = 28px per line
  static const double _lineSpacing = 28.0;

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case PreviewStyle.plain:
        break;

      case PreviewStyle.notebook:
        _paintNotebookLines(canvas, size);
        break;

      case PreviewStyle.grid:
        _paintGridPaper(canvas, size);
        break;

      case PreviewStyle.leaf:
        _paintAgedPaper(canvas, size);
        break;

      case PreviewStyle.spiral:
        _paintNotebookLines(canvas, size, isSpiralMode: true);
        _paintSpiralBinding(canvas, size);
        break;

      case PreviewStyle.dark:
        _paintDarkParchment(canvas, size);
        break;
    }
  }

  void _paintNotebookLines(Canvas canvas, Size size, {bool isSpiralMode = false}) {
    // Margin line position: 64px for notebook, 72px for spiral (past the binding)
    final marginX = isSpiralMode ? 72.0 : 64.0;

    // Red margin line
    final marginPaint = Paint()
      ..color = const Color(0xFFEF9A9A).withOpacity(0.7)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(marginX, 0), Offset(marginX, size.height), marginPaint);

    // Blue ruled lines — start at first line offset, repeat every _lineSpacing px
    final linePaint = Paint()
      ..color = const Color(0xFF90CAF9).withOpacity(0.45)
      ..strokeWidth = 0.8;

    // First line sits 4px from top so text baseline lands on the line
    for (double y = _lineSpacing; y < size.height; y += _lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  void _paintGridPaper(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF90CAF9).withOpacity(0.35)
      ..strokeWidth = 0.5;

    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Bold grid every 5 cells
    final boldPaint = Paint()
      ..color = const Color(0xFF90CAF9).withOpacity(0.5)
      ..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += spacing * 5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), boldPaint);
    }
    for (double y = 0; y < size.height; y += spacing * 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), boldPaint);
    }
  }

  void _paintAgedPaper(Canvas canvas, Size size) {
    // Warm aged paper gradient-like tint
    final paint = Paint()..color = const Color(0xFFF5E6C8).withOpacity(0.18);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Subtle vignette corners
    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.2,
        colors: [Colors.transparent, const Color(0xFF8B6914).withOpacity(0.08)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignette);
  }

  void _paintSpiralBinding(Canvas canvas, Size size) {
    const ringRadius = 9.0;
    const ringSpacing = _lineSpacing * 2; // one ring every two ruled lines
    const bindingX = 28.0;

    final holePaint = Paint()
      ..color = const Color(0xFFEEEEEE).withOpacity(0.95)
      ..style = PaintingStyle.fill;
    final ringPaint = Paint()
      ..color = const Color(0xFF9E9E9E).withOpacity(0.75)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    // Shadow behind ring
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (double y = ringSpacing / 2; y < size.height; y += ringSpacing) {
      canvas.drawCircle(Offset(bindingX, y), ringRadius + 1, shadowPaint);
      canvas.drawCircle(Offset(bindingX, y), ringRadius, holePaint);
      canvas.drawCircle(Offset(bindingX, y), ringRadius, ringPaint);
    }

    // Binding strip background
    final stripPaint = Paint()
      ..color = const Color(0xFFBDBDBD).withOpacity(0.15);
    canvas.drawRect(Rect.fromLTWH(0, 0, bindingX * 2 + 4, size.height), stripPaint);
  }

  void _paintDarkParchment(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1A1209).withOpacity(0.15);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Light scan lines for parchment feel
    final scanPaint = Paint()
      ..color = const Color(0xFFFFF8E1).withOpacity(0.03)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanPaint);
    }
  }

  @override
  bool shouldRepaint(_PreviewStylePainter old) => old.style != style;
}

/// Returns the content padding that ensures text sits inside the ruled/margin area.
/// Left padding pushes text past the margin line; top/right/bottom are standard.
EdgeInsets _styleContentPadding(PreviewStyle style) {
  switch (style) {
    case PreviewStyle.notebook:
      // Margin line at x=64, leave 10px gutter → left = 76
      return const EdgeInsets.fromLTRB(76, 10, 16, 16);
    case PreviewStyle.spiral:
      // Binding ~56px wide, margin at x=72, leave 10px gutter → left = 84
      return const EdgeInsets.fromLTRB(84, 10, 16, 16);
    default:
      return const EdgeInsets.all(16.0);
  }
}

class InlineAudioPlayer extends StatefulWidget {
  final String filePath;
  final String name;
  final VoidCallback? onDelete;

  const InlineAudioPlayer({super.key, required this.filePath, required this.name, this.onDelete});

  @override
  State<InlineAudioPlayer> createState() => _InlineAudioPlayerState();
}

class _InlineAudioPlayerState extends State<InlineAudioPlayer> with SingleTickerProviderStateMixin {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late AnimationController _waveController;

  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _waveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    
    _player.setSource(DeviceFileSource(widget.filePath)).catchError((e) {
      debugPrint('Error setting source: $e');
    });

    _durationSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _positionSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (_isPlaying) {
            _waveController.repeat(reverse: true);
          } else {
            _waveController.stop();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _stateSub?.cancel();
    _waveController.dispose();
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2D1F5E), const Color(0xFF1E1A30)]
              : [const Color(0xFFF0EBFF), const Color(0xFFE8F4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Play/Pause button
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      if (_isPlaying) {
                        _player.pause();
                      } else {
                        _player.play(DeviceFileSource(widget.filePath));
                      }
                    },
                    icon: Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(maxWidth: 36, maxHeight: 36),
                  ),
                ),
                const SizedBox(width: 10),
                // Waveform animation bars (decorative, Fix 5)
                if (_isPlaying)
                  AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, _) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final heights = [10.0, 16.0, 12.0, 18.0, 10.0];
                          final offset = (i * 0.2 + _waveController.value) % 1.0;
                          final h = heights[i] * (0.5 + 0.5 * offset);
                          return Container(
                            width: 3,
                            height: h,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      );
                    },
                  )
                else
                  // Static bars when paused
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [8.0, 12.0, 6.0, 14.0, 8.0].map((h) => Container(
                      width: 3,
                      height: h,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF4C3882) : const Color(0xFFCBB8FF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )).toList(),
                  ),
                const SizedBox(width: 8),
                // Name and times
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.mic_rounded, size: 11, color: Color(0xFF8B5CF6)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                                color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF3D1F8A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                        style: TextStyle(
                          fontSize: 9,
                          fontFamily: 'Inter',
                          color: isDark ? Colors.white.withValues(alpha: 0.45) : const Color(0xFF7C5ABF),
                        ),
                      ),
                    ],
                  ),
                ),
                // Delete button
                if (widget.onDelete != null)
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, color: Color(0xFFF87171), size: 22),
                              SizedBox(width: 8),
                              Text('Delete Voice Note', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                          content: const Text('Remove this voice note from the note?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF87171)),
                              onPressed: () {
                                Navigator.pop(ctx);
                                widget.onDelete!();
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFF87171)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(maxWidth: 28, maxHeight: 28),
                    tooltip: 'Delete voice note',
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(
                    height: 4,
                    color: isDark ? const Color(0xFF3D2B6B) : const Color(0xFFD6C9FF),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 4,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Seekable slider (invisible but functional on top of progress bar)
            SizedBox(
              height: 16,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 0,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
                  overlayShape: SliderComponentShape.noOverlay,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                ),
                child: Slider(
                  value: _duration.inMilliseconds > 0
                      ? _position.inMilliseconds.toDouble()
                      : 0.0,
                  min: 0.0,
                  max: _duration.inMilliseconds > 0
                      ? _duration.inMilliseconds.toDouble()
                      : 1.0,
                  onChanged: (val) {
                    _player.seek(Duration(milliseconds: val.toInt()));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
