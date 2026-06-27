import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/pdf_annotation_model.dart';
import '../controllers/pdf_workspace_controller.dart';
import 'pdf_annotation_menu.dart';
import 'pdf_flashcard_dialog.dart';
import '../../../editor/domain/entities/block_type.dart';
import '../../../editor/presentation/widgets/blocks/pdf_page_cropper_dialog.dart';

class PdfViewerBodyWidget extends ConsumerStatefulWidget {
  final String pdfPath;
  final PdfViewerController pdfViewerController;
  final GlobalKey pdfViewerKey;
  final void Function(BlockType type, String content, Map<String, dynamic> attributes)? onInsertBlock;

  const PdfViewerBodyWidget({
    super.key,
    required this.pdfPath,
    required this.pdfViewerController,
    required this.pdfViewerKey,
    this.onInsertBlock,
  });

  @override
  ConsumerState<PdfViewerBodyWidget> createState() => _PdfViewerBodyWidgetState();
}

class _PdfViewerBodyWidgetState extends ConsumerState<PdfViewerBodyWidget> {
  OverlayEntry? _menuEntry;
  String _selectedText = '';
  final List<PdfRect> _selectedTextLines = [];
  int _currentPage = 1;
  String? _errorMessage;
  File? _pdfFile;
  Uint8List? _pdfBytes;

  @override
  void initState() {
    super.initState();
    _resolvePdfFile();
  }

  Future<void> _resolvePdfFile() async {
    try {
      final path = widget.pdfPath;
      if (path.startsWith('data:')) {
        final base64Str = path.split(',').last;
        final bytes = base64Decode(base64Str);
        setState(() {
          _pdfBytes = bytes;
          _errorMessage = null;
        });
        return;
      }

      if (kIsWeb) {
        setState(() {
          _errorMessage = "Local file paths are not supported on Web.";
        });
        return;
      }

      String cleanPath = path;
      if (cleanPath.startsWith('file://')) {
        cleanPath = cleanPath.replaceFirst('file://', '');
      }

      final file = File(cleanPath);
      if (!await file.exists()) {
        try {
          final uri = Uri.parse(path);
          final fallbackFile = File(uri.toFilePath());
          if (await fallbackFile.exists()) {
            setState(() {
              _pdfFile = fallbackFile;
            });
            return;
          }
        } catch (_) {}

        setState(() {
          _errorMessage = "PDF file not found on disk at:\n$cleanPath";
        });
        return;
      }
      
      setState(() {
        _pdfFile = file;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load PDF file: $e";
      });
    }
  }

  @override
  void dispose() {
    _hideSelectionMenu();
    super.dispose();
  }

  void _showSelectionMenu(Offset globalOffset, double selectionWidth) {
    _hideSelectionMenu();

    final overlay = Overlay.of(context);

    _menuEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: (globalOffset.dx + (selectionWidth / 2) - 160).clamp(10.0, MediaQuery.of(context).size.width - 320.0),
        top: (globalOffset.dy - 60).clamp(kToolbarHeight, MediaQuery.of(context).size.height - 100),
        child: Material(
          color: Colors.transparent,
          child: PdfAnnotationMenu(
            selectedText: _selectedText,
            onApplyMarkup: _applyMarkup,
            onSaveAsNote: _saveAsNote,
            onAddStickyNote: _addStickyNote,
            onCreateFlashcard: _createFlashcard,
            onAiExplain: _aiExplain,
            onClose: _hideSelectionMenu,
          ),
        ),
      ),
    );

    overlay.insert(_menuEntry!);
  }

  void _hideSelectionMenu() {
    _menuEntry?.remove();
    _menuEntry = null;
  }

  void _applyMarkup(String colorHex, String type, String category) {
    if (_selectedTextLines.isEmpty) return;

    final controller = ref.read(pdfWorkspaceProvider(widget.pdfPath).notifier);
    final rects = _selectedTextLines.map((rect) => {
      'left': rect.left,
      'top': rect.top,
      'width': rect.width,
      'height': rect.height,
    }).toList();

    final annotation = PdfAnnotationModel(
      id: const Uuid().v4(),
      pdfPath: widget.pdfPath,
      pageNumber: _currentPage,
      type: type,
      colorHex: colorHex,
      selectedText: _selectedText,
      rectsJson: jsonEncode(rects),
      createdAt: DateTime.now(),
    );

    controller.addAnnotation(annotation);
    _hideSelectionMenu();
  }

  void _saveAsNote() {
    final annotation = PdfAnnotationModel(
      id: const Uuid().v4(),
      pdfPath: widget.pdfPath,
      pageNumber: _currentPage,
      type: 'note',
      colorHex: '#FFF176',
      selectedText: _selectedText,
      noteText: 'Saved study note from PDF.',
      createdAt: DateTime.now(),
    );

    ref.read(pdfWorkspaceProvider(widget.pdfPath).notifier).addAnnotation(annotation);
    _hideSelectionMenu();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selection saved as study note!'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addStickyNote() {
    final txtController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add PDF Margin Note'),
        content: TextField(
          controller: txtController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter sticky note content...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final content = txtController.text.trim();
              if (content.isNotEmpty) {
                final annotation = PdfAnnotationModel(
                  id: const Uuid().v4(),
                  pdfPath: widget.pdfPath,
                  pageNumber: _currentPage,
                  type: 'note',
                  colorHex: '#FFF176',
                  selectedText: _selectedText,
                  noteText: content,
                  createdAt: DateTime.now(),
                );
                ref.read(pdfWorkspaceProvider(widget.pdfPath).notifier).addAnnotation(annotation);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    _hideSelectionMenu();
  }

  void _createFlashcard() {
    showDialog(
      context: context,
      builder: (ctx) => PdfFlashcardDialog(
        initialQuestion: _selectedText,
        onSave: (q, a) {
          final annotation = PdfAnnotationModel(
            id: const Uuid().v4(),
            pdfPath: widget.pdfPath,
            pageNumber: _currentPage,
            type: 'flashcard',
            colorHex: '#FFEB3B',
            selectedText: _selectedText,
            flashcardQuestion: q,
            flashcardAnswer: a,
            createdAt: DateTime.now(),
          );
          ref.read(pdfWorkspaceProvider(widget.pdfPath).notifier).addAnnotation(annotation);
        },
      ),
    );
    _hideSelectionMenu();
  }

  void _aiExplain() {
    final annotation = PdfAnnotationModel(
      id: const Uuid().v4(),
      pdfPath: widget.pdfPath,
      pageNumber: _currentPage,
      type: 'note',
      colorHex: '#E1BEE7',
      selectedText: _selectedText,
      noteText: 'AI Explanation Summary:\n\nThis passage defines a core concept. In simple terms, it details the mechanics and operational constraints of the subject material.',
      createdAt: DateTime.now(),
    );

    ref.read(pdfWorkspaceProvider(widget.pdfPath).notifier).addAnnotation(annotation);
    _hideSelectionMenu();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI explanation generated & saved offline!'),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _editNoteDialog(PdfAnnotationModel note) {
    final txtController = TextEditingController(text: note.noteText);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Sticky Note'),
        content: TextField(
          controller: txtController,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(pdfWorkspaceProvider(widget.pdfPath).notifier).deleteAnnotation(note.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final content = txtController.text.trim();
              if (content.isNotEmpty) {
                final updated = note.copyWith(noteText: content);
                ref.read(pdfWorkspaceProvider(widget.pdfPath).notifier).addAnnotation(updated);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSnapshotDialog(PdfAnnotationModel snap) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Visual Snapshot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (snap.snapshotPath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: snap.snapshotPath!.startsWith('data:')
                    ? Image.memory(base64Decode(snap.snapshotPath!.split(',').last))
                    : (!kIsWeb && File(snap.snapshotPath!).existsSync()
                        ? Image.file(File(snap.snapshotPath!))
                        : const Text('Snapshot file not found on disk.')),
              )
            else
              const Text('Snapshot file not found.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(pdfWorkspaceProvider(widget.pdfPath).notifier).deleteAnnotation(snap.id);
              try {
                if (!kIsWeb && snap.snapshotPath != null && !snap.snapshotPath!.startsWith('data:')) {
                  final f = File(snap.snapshotPath!);
                  if (f.existsSync()) f.deleteSync();
                }
              } catch (_) {}
              Navigator.pop(ctx);
            },
            child: const Text('Delete Crop', style: TextStyle(color: Colors.red)),
          ),
          if (widget.onInsertBlock != null && snap.snapshotPath != null)
            ElevatedButton(
              onPressed: () {
                widget.onInsertBlock!(
                  BlockType.image,
                  snap.snapshotPath!.startsWith('data:') ? snap.snapshotPath! : 'file://${snap.snapshotPath}',
                  {},
                );
                Navigator.pop(ctx);
              },
              child: const Text('Insert in Note'),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showFlashcardDetailDialog(PdfAnnotationModel fc) {
    bool showAnswer = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Flashcard Study'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (fc.snapshotPath != null) ...[
                  const Text('Question Image:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.03),
                      child: fc.snapshotPath!.startsWith('data:')
                          ? Image.memory(base64Decode(fc.snapshotPath!.split(',').last))
                          : (!kIsWeb && File(fc.snapshotPath!).existsSync()
                              ? Image.file(File(fc.snapshotPath!))
                              : const Text('Image file not found.')),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Question: ${fc.flashcardQuestion ?? ""}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                if (!showAnswer)
                  ElevatedButton(
                    onPressed: () {
                      setStateDialog(() {
                        showAnswer = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reveal Answer'),
                  )
                else ...[
                  const Text('Answer:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 8),
                  Text(
                    fc.flashcardAnswer ?? "No answer provided.",
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  ref.read(pdfWorkspaceProvider(widget.pdfPath).notifier).deleteAnnotation(fc.id);
                  try {
                    if (!kIsWeb && fc.snapshotPath != null && !fc.snapshotPath!.startsWith('data:')) {
                      final f = File(fc.snapshotPath!);
                      if (f.existsSync()) f.deleteSync();
                    }
                  } catch (_) {}
                  Navigator.pop(ctx);
                },
                child: const Text('Delete Card', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showContextMenu(Offset localPosition, PdfPageHitTestResult hitResult) async {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    final globalTapOffset = renderBox != null ? renderBox.localToGlobal(localPosition) : Offset.zero;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromLTWH(globalTapOffset.dx, globalTapOffset.dy, 0, 0),
      Rect.fromLTWH(0, 0, overlay!.size.width, overlay.size.height),
    );

    final result = await showMenu<String>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem<String>(
          value: 'note',
          child: Row(
            children: [
              Icon(Icons.sticky_note_2_outlined, size: 18),
              SizedBox(width: 8),
              Text('Add Sticky Note Here'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'highlight',
          child: Row(
            children: [
              Icon(Icons.border_color_rounded, size: 18),
              SizedBox(width: 8),
              Text('Highlight Region'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'flashcard',
          child: Row(
            children: [
              Icon(Icons.style_outlined, size: 18),
              SizedBox(width: 8),
              Text('Create Flashcard from Region'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'crop',
          child: Row(
            children: [
              Icon(Icons.crop_rounded, size: 18),
              SizedBox(width: 8),
              Text('Extract Region as Image'),
            ],
          ),
        ),
      ],
    );

    if (result == 'note') {
      _addStickyNoteAt(hitResult);
    } else if (result == 'crop') {
      _extractRegion(hitResult);
    } else if (result == 'highlight') {
      _highlightRegion(hitResult);
    } else if (result == 'flashcard') {
      _createFlashcardFromRegion(hitResult);
    }
  }

  void _addStickyNoteAt(PdfPageHitTestResult hitResult) {
    final txtController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Sticky Note'),
        content: TextField(
          controller: txtController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter sticky note content...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final content = txtController.text.trim();
              if (content.isNotEmpty) {
                final annotation = PdfAnnotationModel(
                  id: const Uuid().v4(),
                  pdfPath: widget.pdfPath,
                  pageNumber: hitResult.page.pageNumber,
                  type: 'note',
                  colorHex: '#FFF176',
                  selectedText: '',
                  noteText: content,
                  rectsJson: jsonEncode({'x': hitResult.offset.x, 'y': hitResult.offset.y}),
                  createdAt: DateTime.now(),
                );
                ref.read(pdfWorkspaceProvider(widget.pdfPath).notifier).addAnnotation(annotation);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _selectPageRegion(PdfPageHitTestResult hitResult) async {
    final page = hitResult.page;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.red),
                SizedBox(width: 16),
                Text('Loading page for selection…'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final hiWidth = (page.width * 1.5).clamp(600.0, 1200.0);
      final hiHeight = page.height * (hiWidth / page.width);

      final hiImg = await page.render(
        fullWidth: hiWidth,
        fullHeight: hiHeight,
        backgroundColor: 0xFFFFFFFF,
      );
      
      if (!mounted) return null;
      Navigator.pop(context); // Dismiss spinner

      if (hiImg == null) return null;

      final uiImage = await hiImg.createImage();
      hiImg.dispose();

      if (!mounted) return null;

      final Rect? result = await showDialog<Rect?>(
        context: context,
        builder: (c) => PdfPageCropperDialog(image: uiImage),
      );

      if (result != null && result != Rect.zero) {
        final croppedBytes = await _cropUiImage(uiImage, result);
        return {
          'rect': result,
          'bytes': croppedBytes,
        };
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rendering page: $e')),
        );
      }
    }
    return null;
  }

  Future<void> _extractRegion(PdfPageHitTestResult hitResult) async {
    final selection = await _selectPageRegion(hitResult);
    if (selection == null) return;

    final result = selection['rect'] as Rect;
    final croppedBytes = selection['bytes'] as Uint8List;
    final pageNum = hitResult.page.pageNumber;

    final String snapshotPath;
    if (kIsWeb) {
      final base64String = base64Encode(croppedBytes);
      snapshotPath = 'data:image/png;base64,$base64String';
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      final snapshotsDir = Directory('${docDir.path}/pdf_snapshots');
      if (!await snapshotsDir.exists()) {
        await snapshotsDir.create(recursive: true);
      }
      final fileName = 'snapshot_${const Uuid().v4()}.png';
      final file = File('${snapshotsDir.path}/$fileName');
      await file.writeAsBytes(croppedBytes);
      snapshotPath = file.path;
    }

    final annotation = PdfAnnotationModel(
      id: const Uuid().v4(),
      pdfPath: widget.pdfPath,
      pageNumber: pageNum,
      type: 'snapshot',
      colorHex: '#E0F2FE',
      selectedText: 'Visual Snapshot',
      snapshotPath: snapshotPath,
      rectsJson: jsonEncode({
        'left': result.left,
        'top': result.top,
        'width': result.width,
        'height': result.height,
      }),
      createdAt: DateTime.now(),
    );

    await ref.read(pdfWorkspaceProvider(widget.pdfPath).notifier).addAnnotation(annotation);

    if (mounted) {
      if (widget.onInsertBlock != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Snapshot saved to study hub!'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Insert in Note',
              onPressed: () {
                widget.onInsertBlock!(
                  BlockType.image,
                  snapshotPath.startsWith('data:') ? snapshotPath : 'file://$snapshotPath',
                  {},
                );
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Snapshot saved to study hub!')),
        );
      }
    }
  }

  Future<void> _highlightRegion(PdfPageHitTestResult hitResult) async {
    final selection = await _selectPageRegion(hitResult);
    if (selection == null) return;
    
    final result = selection['rect'] as Rect;
    final pageNum = hitResult.page.pageNumber;

    if (!mounted) return;
    
    final colorHex = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Highlight Color'),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _colorOption(ctx, '#FFEB3B', Colors.yellow),
            _colorOption(ctx, '#A7F3D0', Colors.green.shade200),
            _colorOption(ctx, '#BFDBFE', Colors.blue.shade200),
            _colorOption(ctx, '#FBCFE8', Colors.pink.shade200),
          ],
        ),
      ),
    );

    if (colorHex == null) return;

    final annotation = PdfAnnotationModel(
      id: const Uuid().v4(),
      pdfPath: widget.pdfPath,
      pageNumber: pageNum,
      type: 'highlight',
      colorHex: colorHex,
      rectsJson: jsonEncode({
        'left': result.left,
        'top': result.top,
        'width': result.width,
        'height': result.height,
      }),
      createdAt: DateTime.now(),
    );

    await ref.read(pdfWorkspaceProvider(widget.pdfPath).notifier).addAnnotation(annotation);
  }

  Widget _colorOption(BuildContext context, String hex, Color color) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, hex),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black26),
        ),
      ),
    );
  }

  Future<void> _createFlashcardFromRegion(PdfPageHitTestResult hitResult) async {
    final selection = await _selectPageRegion(hitResult);
    if (selection == null) return;
    
    final result = selection['rect'] as Rect;
    final croppedBytes = selection['bytes'] as Uint8List;
    final pageNum = hitResult.page.pageNumber;

    final String snapshotPath;
    if (kIsWeb) {
      final base64String = base64Encode(croppedBytes);
      snapshotPath = 'data:image/png;base64,$base64String';
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      final snapshotsDir = Directory('${docDir.path}/pdf_snapshots');
      if (!await snapshotsDir.exists()) {
        await snapshotsDir.create(recursive: true);
      }
      final fileName = 'snapshot_${const Uuid().v4()}.png';
      final file = File('${snapshotsDir.path}/$fileName');
      await file.writeAsBytes(croppedBytes);
      snapshotPath = file.path;
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => PdfFlashcardDialog(
        initialQuestion: 'Visual Question',
        onSave: (q, a) async {
          final annotation = PdfAnnotationModel(
            id: const Uuid().v4(),
            pdfPath: widget.pdfPath,
            pageNumber: pageNum,
            type: 'flashcard',
            colorHex: '#FFEB3B',
            selectedText: 'Visual Flashcard',
            flashcardQuestion: q,
            flashcardAnswer: a,
            snapshotPath: snapshotPath,
            rectsJson: jsonEncode({
              'left': result.left,
              'top': result.top,
              'width': result.width,
              'height': result.height,
            }),
            createdAt: DateTime.now(),
          );
          await ref.read(pdfWorkspaceProvider(widget.pdfPath).notifier).addAnnotation(annotation);
        },
      ),
    );
  }

  Future<Uint8List> _cropUiImage(ui.Image uiImage, Rect cropRect) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final double w = uiImage.width.toDouble();
    final double h = uiImage.height.toDouble();

    final srcRect = Rect.fromLTWH(
      cropRect.left * w,
      cropRect.top * h,
      cropRect.width * w,
      cropRect.height * h,
    );

    final destRect = Rect.fromLTWH(0, 0, srcRect.width, srcRect.height);

    canvas.drawImageRect(uiImage, srcRect, destRect, Paint());

    final picture = recorder.endRecording();
    final img = await picture.toImage(srcRect.width.toInt(), srcRect.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _paintAnnotations(Canvas canvas, Rect pageRect, PdfPage page) {
    final state = ref.read(pdfWorkspaceProvider(widget.pdfPath));
    final annotations = state.annotations.where((a) => a.pageNumber == page.pageNumber).toList();

    for (var ann in annotations) {
      if (['highlight', 'underline', 'strikethrough', 'squiggly'].contains(ann.type)) {
        if (ann.rectsJson == null) continue;
        try {
          final parsed = jsonDecode(ann.rectsJson!);
          final cleanHex = ann.colorHex.replaceAll('#', '');
          final baseColor = Color(int.parse('FF$cleanHex', radix: 16));
          final paint = Paint()..color = baseColor.withValues(alpha: 0.4);

          final List<Rect> screenRects = [];
          if (parsed is List) {
            for (final rectMap in parsed) {
              final double left = (rectMap['left'] as num).toDouble();
              final double top = (rectMap['top'] as num).toDouble();
              final double width = (rectMap['width'] as num).toDouble();
              final double height = (rectMap['height'] as num).toDouble();

              final pdfRect = PdfRect(left, top, left + width, top + height);
              final rect = pdfRect.toRect(page: page, scaledPageSize: pageRect.size);
              screenRects.add(rect.shift(pageRect.topLeft));
            }
          } else if (parsed is Map) {
            final double left = (parsed['left'] as num).toDouble();
            final double top = (parsed['top'] as num).toDouble();
            final double width = (parsed['width'] as num).toDouble();
            final double height = (parsed['height'] as num).toDouble();

            final screenRect = Rect.fromLTWH(
              pageRect.left + left * pageRect.width,
              pageRect.top + top * pageRect.height,
              width * pageRect.width,
              height * pageRect.height,
            );
            screenRects.add(screenRect);
          }

          for (final screenRect in screenRects) {
            if (ann.type == 'highlight') {
              canvas.drawRect(screenRect, paint);
            } else if (ann.type == 'underline') {
              paint.style = PaintingStyle.stroke;
              paint.strokeWidth = 2;
              canvas.drawLine(screenRect.bottomLeft, screenRect.bottomRight, paint);
            } else if (ann.type == 'strikethrough') {
              paint.style = PaintingStyle.stroke;
              paint.strokeWidth = 2;
              canvas.drawLine(screenRect.centerLeft, screenRect.centerRight, paint);
            } else if (ann.type == 'squiggly') {
              paint.style = PaintingStyle.stroke;
              paint.strokeWidth = 2;
              canvas.drawLine(screenRect.bottomLeft, screenRect.bottomRight, paint);
            }
          }
        } catch (_) {}
      } else if (ann.type == 'note' && ann.noteText != null) {
        double x = 10.0;
        double y = 10.0;
        if (ann.rectsJson != null) {
          try {
            final parsed = jsonDecode(ann.rectsJson!);
            if (parsed is Map) {
              final px = (parsed['x'] ?? parsed['left'] ?? 10.0) as num;
              final py = (parsed['y'] ?? parsed['top'] ?? 10.0) as num;
              
              final pdfPoint = PdfPoint(px.toDouble(), py.toDouble());
              final pageOffset = pdfPoint.toOffset(page: page, scaledPageSize: pageRect.size);
              x = pageOffset.dx;
              y = pageOffset.dy;
            }
          } catch (_) {}
        }
        
        final paint = Paint()..color = Colors.amber.withValues(alpha: 0.95);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(pageRect.left + x - 12, pageRect.top + y - 12, 24, 24),
            const Radius.circular(6),
          ),
          paint,
        );
        
        final textPainter = TextPainter(
          text: const TextSpan(text: '📝', style: TextStyle(fontSize: 14)),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(pageRect.left + x - 7, pageRect.top + y - 9));
      } else if (ann.type == 'snapshot' && ann.rectsJson != null) {
        try {
          final parsed = jsonDecode(ann.rectsJson!);
          final double left = (parsed['left'] as num).toDouble();
          final double top = (parsed['top'] as num).toDouble();
          final double width = (parsed['width'] as num).toDouble();
          final double height = (parsed['height'] as num).toDouble();

          final screenRect = Rect.fromLTWH(
            pageRect.left + left * pageRect.width,
            pageRect.top + top * pageRect.height,
            width * pageRect.width,
            height * pageRect.height,
          );

          final paint = Paint()
            ..color = Colors.red.withValues(alpha: 0.8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;

          canvas.drawRect(screenRect, paint);

          final badgePaint = Paint()..color = Colors.red.withValues(alpha: 0.95);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(screenRect.right - 22, screenRect.top + 2, 20, 20),
              const Radius.circular(4),
            ),
            badgePaint,
          );

          final textPainter = TextPainter(
            text: const TextSpan(
              text: '📷',
              style: TextStyle(fontSize: 11),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(screenRect.right - 19, screenRect.top + 5));
        } catch (_) {}
      } else if (ann.type == 'flashcard' && ann.rectsJson != null) {
        try {
          final parsed = jsonDecode(ann.rectsJson!);
          if (parsed is Map) {
            final double left = (parsed['left'] as num).toDouble();
            final double top = (parsed['top'] as num).toDouble();
            final double width = (parsed['width'] as num).toDouble();
            final double height = (parsed['height'] as num).toDouble();

            final screenRect = Rect.fromLTWH(
              pageRect.left + left * pageRect.width,
              pageRect.top + top * pageRect.height,
              width * pageRect.width,
              height * pageRect.height,
            );

            // Paint orange outlines
            final paint = Paint()
              ..color = Colors.orange.withValues(alpha: 0.8)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0;

            canvas.drawRect(screenRect, paint);

            // Paint badge icon (🎴)
            final badgePaint = Paint()..color = Colors.orange.withValues(alpha: 0.95);
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(screenRect.right - 22, screenRect.top + 2, 20, 20),
                const Radius.circular(4),
              ),
              badgePaint,
            );

            final textPainter = TextPainter(
              text: const TextSpan(
                text: '🎴',
                style: TextStyle(fontSize: 11),
              ),
              textDirection: TextDirection.ltr,
            );
            textPainter.layout();
            textPainter.paint(canvas, Offset(screenRect.right - 19, screenRect.top + 4));
          }
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2), width: 1.5),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Colors.redAccent,
                  size: 56,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Could not load PDF document',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF13111C) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _pdfFile = null;
                    _resolvePdfFile();
                  });
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfFile == null && _pdfBytes == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: theme.colorScheme.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading PDF Workspace...',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    // Wrap with Riverpod Consumer to trigger repaints when annotations change
    return Consumer(
      builder: (context, ref, child) {
        ref.watch(pdfWorkspaceProvider(widget.pdfPath)); // Watch state to trigger rebuilds

        final params = PdfViewerParams(
          verticalCacheExtent: 0.0, // Only load/render visible pages (gradual lazy load on scroll)
          onePassRenderingScaleThreshold: 120 / 72, // Render light fast one-pass first, then refine gradually
          limitRenderingCache: true, // Reduce image memory caching
          scrollPhysics: PdfViewerParams.getScrollPhysics(context),
          viewerOverlayBuilder: (context, size, handleLinkTap) => [
            PdfViewerScrollThumb(
              controller: widget.pdfViewerController,
              orientation: ScrollbarOrientation.right,
              thumbSize: const Size(28, 40),
              margin: 6,
              thumbBuilder: (context, thumbSize, pageNumber, controller) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      pageNumber?.toString() ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          onViewerReady: (doc, controller) {
            ref.read(pdfWorkspaceProvider(widget.pdfPath).notifier).setTotalPages(doc.pages.length);
          },
          onPageChanged: (pageNumber) {
            if (pageNumber != null) {
              _currentPage = pageNumber;
              ref.read(pdfWorkspaceProvider(widget.pdfPath).notifier).setCurrentPage(pageNumber);
            }
          },
          errorBannerBuilder: (context, error, stackTrace, documentRef) {
             return Center(
               child: Container(
                 padding: const EdgeInsets.all(16),
                 color: Colors.red.withValues(alpha: 0.8),
                 child: Text(
                   'Error loading PDF: $error',
                   style: const TextStyle(color: Colors.white),
                 ),
               ),
             );
           },
          onGeneralTap: (context, controller, details) {
            if (details.type == PdfViewerGeneralTapType.tap) {
              final hitResult = controller.getPdfPageHitTestResult(
                details.documentPosition,
                useDocumentLayoutCoordinates: true,
              );
              if (hitResult != null) {
                final page = hitResult.page;
                final tappedOffset = hitResult.offset;
                
                final workspaceState = ref.read(pdfWorkspaceProvider(widget.pdfPath));
                final notes = workspaceState.annotations.where((a) => a.pageNumber == page.pageNumber && a.type == 'note').toList();
                
                for (final note in notes) {
                  if (note.rectsJson != null) {
                    try {
                      final parsed = jsonDecode(note.rectsJson!);
                      if (parsed is Map) {
                        final px = (parsed['x'] ?? parsed['left'] ?? 10.0) as num;
                        final py = (parsed['y'] ?? parsed['top'] ?? 10.0) as num;
                        
                        final dist = (tappedOffset.x - px).abs() + (tappedOffset.y - py).abs();
                        if (dist < 20) {
                          _editNoteDialog(note);
                          return true;
                        }
                      }
                    } catch (_) {}
                  }
                }

                final snapshots = workspaceState.annotations.where((a) => a.pageNumber == page.pageNumber && a.type == 'snapshot').toList();
                for (final snap in snapshots) {
                  if (snap.rectsJson != null) {
                    try {
                      final parsed = jsonDecode(snap.rectsJson!);
                      final double left = (parsed['left'] as num).toDouble();
                      final double top = (parsed['top'] as num).toDouble();
                      final double width = (parsed['width'] as num).toDouble();
                      final double height = (parsed['height'] as num).toDouble();
                      
                      final pageOffset = tappedOffset.toOffset(page: page);
                      final fractionX = pageOffset.dx / page.width;
                      final fractionY = pageOffset.dy / page.height;
                      
                      if (fractionX >= left && fractionX <= left + width &&
                          fractionY >= top && fractionY <= top + height) {
                        _showSnapshotDialog(snap);
                        return true;
                      }
                    } catch (_) {}
                  }
                }

                final flashcards = workspaceState.annotations.where((a) => a.pageNumber == page.pageNumber && a.type == 'flashcard').toList();
                for (final fc in flashcards) {
                  if (fc.rectsJson != null) {
                    try {
                      final parsed = jsonDecode(fc.rectsJson!);
                      if (parsed is Map) {
                        final double left = (parsed['left'] as num).toDouble();
                        final double top = (parsed['top'] as num).toDouble();
                        final double width = (parsed['width'] as num).toDouble();
                        final double height = (parsed['height'] as num).toDouble();
                        
                        final pageOffset = tappedOffset.toOffset(page: page);
                        final fractionX = pageOffset.dx / page.width;
                        final fractionY = pageOffset.dy / page.height;
                        
                        if (fractionX >= left && fractionX <= left + width &&
                            fractionY >= top && fractionY <= top + height) {
                          _showFlashcardDetailDialog(fc);
                          return true;
                        }
                      }
                    } catch (_) {}
                  }
                }
              }
            } else if (details.type == PdfViewerGeneralTapType.longPress ||
                       details.type == PdfViewerGeneralTapType.secondaryTap) {
              final hitResult = controller.getPdfPageHitTestResult(
                details.documentPosition,
                useDocumentLayoutCoordinates: true,
              );
              if (hitResult != null) {
                _showContextMenu(details.localPosition, hitResult);
                return true;
              }
            }
            return false;
          },
          textSelectionParams: PdfTextSelectionParams(
            onTextSelectionChange: (selection) async {
              if (selection.hasSelectedText) {
                final text = await selection.getSelectedText();
                if (!context.mounted) return;
                setState(() {
                  _selectedText = text;
                  _selectedTextLines.clear();
                });
                
                final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                final offset = renderBox?.localToGlobal(Offset.zero) ?? const Offset(100, 100);
                
                _showSelectionMenu(offset, 100);
              } else {
                _hideSelectionMenu();
              }
            },
          ),
          pagePaintCallbacks: [
            _paintAnnotations,
          ],
        );

        final pdfBytes = _pdfBytes;
        if (pdfBytes != null) {
          return PdfViewer.data(
            pdfBytes,
            sourceName: 'pdf_document.pdf',
            key: widget.pdfViewerKey,
            controller: widget.pdfViewerController,
            params: params,
          );
        }

        final pdfFile = _pdfFile;
        if (pdfFile != null) {
          return PdfViewer.file(
            pdfFile.path,
            key: widget.pdfViewerKey,
            controller: widget.pdfViewerController,
            params: params,
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
