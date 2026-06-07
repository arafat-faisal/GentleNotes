import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import '../../../../../models/models.dart';
import '../../../../notes/presentation/controllers/notes_controller.dart';

class PdfReaderScreen extends ConsumerStatefulWidget {
  final String pdfPath;

  const PdfReaderScreen({super.key, required this.pdfPath});

  @override
  ConsumerState<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen> {
  PdfControllerPinch? _pdfController;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  String? _errorMessage;
  
  bool _showUI = true;
  bool _nightMode = false;
  int _rotationTurns = 0;

  static const ColorFilter _invertFilter = ColorFilter.matrix(<double>[
    -1, 0, 0, 0, 255,
     0, -1, 0, 0, 255,
     0, 0, -1, 0, 255,
     0, 0, 0, 1, 0,
  ]);

  static const ColorFilter _identityFilter = ColorFilter.matrix(<double>[
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final file = File(widget.pdfPath);
      if (!await file.exists()) {
        throw Exception('PDF file not found at:\n${widget.pdfPath}');
      }
      
      final document = await PdfDocument.openFile(widget.pdfPath);
      final pageCount = document.pagesCount;
      await document.close();

      final controller = PdfControllerPinch(
        document: PdfDocument.openFile(widget.pdfPath),
      );

      if (mounted) {
        setState(() {
          _pdfController = controller;
          _totalPages = pageCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  String get _pdfName {
    final parts = widget.pdfPath.replaceAll('\\', '/').split('/');
    return parts.isNotEmpty ? parts.last : 'PDF Document';
  }

  Future<void> _importToNotes() async {
    final name = _pdfName;
    final noteId = const Uuid().v4();
    final now = DateTime.now();
    final safePath = widget.pdfPath.replaceAll('\\', '/');
    final content =
        '[{"insert":{"pdf":{"path":"$safePath","name":"$name","pages":[],"crops":{}}}},{"insert":"\\n"}]';

    final note = NoteModel(
      id: noteId,
      title: name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '') + ' Note',
      content: content,
      noteType: NoteType.mixed,
      tags: ['imported-pdf'],
      attachments: [],
      colorHex: '#FFFFFF',
      isFavorite: false,
      isPinned: false,
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(notesProvider.notifier).addNote(note);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved "$name" as a note in GentleNotes!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showJumpToPageDialog() {
    final txtController = TextEditingController(text: _currentPage.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jump to Page'),
        content: TextField(
          controller: txtController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: '1 - $_totalPages',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            _jump(value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _jump(txtController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  void _jump(String value) {
    final page = int.tryParse(value);
    if (page != null && page >= 1 && page <= _totalPages) {
      _pdfController?.jumpToPage(page);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // In immersive mode, we want a black background for the PDF if night mode is on.
    final bgColor = _nightMode || isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF4F4F8);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          _buildPdfContent(theme, isDark),
          
          // Top App Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: _showUI ? 0 : -100,
            left: 0,
            right: 0,
            child: _buildTopAppBar(theme, isDark),
          ),

          // Bottom Scrubber Bar
          if (_totalPages > 0)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _showUI ? 0 : -120,
              left: 0,
              right: 0,
              child: _buildBottomScrubber(theme, isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildTopAppBar(ThemeData theme, bool isDark) {
    return Container(
      color: isDark ? const Color(0xE01A1A2E) : Colors.white.withValues(alpha: 0.95),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 4,
        right: 4,
        bottom: 8,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _pdfName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _nightMode ? 'Night Mode Active' : 'Document Viewer',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.rotate_right_rounded),
            color: theme.colorScheme.onSurface,
            tooltip: 'Rotate Document',
            onPressed: () => setState(() => _rotationTurns = (_rotationTurns + 1) % 4),
          ),
          IconButton(
            icon: Icon(
              _nightMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: _nightMode ? Colors.orangeAccent : theme.colorScheme.onSurface,
            ),
            tooltip: 'Toggle Night Mode',
            onPressed: () => setState(() => _nightMode = !_nightMode),
          ),
          if (!_isLoading && _errorMessage == null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _importToNotes,
                icon: const Icon(Icons.note_add_outlined, size: 18),
                label: const Text('Save to Notes', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomScrubber(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xE01A1A2E) : Colors.white.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _showJumpToPageDialog,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                '$_currentPage',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: theme.colorScheme.primary,
                inactiveTrackColor: theme.colorScheme.outlineVariant,
                thumbColor: theme.colorScheme.primary,
                trackHeight: 4,
              ),
              child: Slider(
                min: 1,
                max: _totalPages.toDouble(),
                value: _currentPage.toDouble().clamp(1.0, _totalPages.toDouble()),
                onChanged: (val) {
                  _pdfController?.jumpToPage(val.toInt());
                },
              ),
            ),
          ),
          InkWell(
            onTap: _showJumpToPageDialog,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                '$_totalPages',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfContent(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: theme.colorScheme.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text('Opening PDF...', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 48),
              ),
              const SizedBox(height: 20),
              Text('Could not open PDF',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _pdfController;
    if (controller == null) return const SizedBox.shrink();

    Widget pdfView = PdfViewPinch(
      controller: controller,
      onPageChanged: (page) {
        setState(() => _currentPage = page);
      },
      onDocumentError: (error) {
        setState(() => _errorMessage = error.toString());
      },
      builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (_) => Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
        pageLoaderBuilder: (_) => Container(
          color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
          child: Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary, strokeWidth: 2),
          ),
        ),
        errorBuilder: (_, error) => Center(
          child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );

    // Always maintain the same widget tree depth so the controller doesn't get detached.
    pdfView = RotatedBox(
      quarterTurns: _rotationTurns,
      child: ColorFiltered(
        colorFilter: _nightMode ? _invertFilter : _identityFilter,
        child: pdfView,
      ),
    );

    return GestureDetector(
      onTap: () {
        setState(() => _showUI = !_showUI);
      },
      child: Container(
        color: Colors.transparent,
        child: pdfView,
      ),
    );
  }
}
