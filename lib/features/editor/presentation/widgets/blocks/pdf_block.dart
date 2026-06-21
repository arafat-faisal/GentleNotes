import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;
import 'package:pdfrx/pdfrx.dart';
import 'package:path_provider/path_provider.dart';

import '../../../domain/entities/block_entity.dart';
import '../../../domain/entities/block_type.dart';
import '../../controllers/editor_block_controller.dart';
import 'pdf_pages_manager_dialog.dart';
import 'pdf_raster_page_widget.dart';
import '../../../../pdf_viewer/presentation/screens/pdf_reader_workspace_screen.dart';

/// Data model for one rendered PDF page (indexed, with image bytes).
class PdfPageModel {
  final int index; // 0-based page index in the original document
  final Uint8List bytes; // PNG bytes for rendering
  final double width;
  final double height;

  const PdfPageModel({
    required this.index,
    required this.bytes,
    required this.width,
    required this.height,
  });
}

class PdfBlock extends ConsumerStatefulWidget {
  final BlockEntity block;
  final VoidCallback onRemoved;
  final bool readOnly;
  final void Function(List<int> pages, Map<String, dynamic> crops, String layout)? onUpdate;
  final void Function(BlockType type, String content, Map<String, dynamic> attributes)? onInsertBlock;

  const PdfBlock({
    super.key,
    required this.block,
    required this.onRemoved,
    required this.readOnly,
    this.onUpdate,
    this.onInsertBlock,
  });

  @override
  ConsumerState<PdfBlock> createState() => _PdfBlockState();
}

class _PdfBlockState extends ConsumerState<PdfBlock> {
  PdfDocument? _document;
  List<PdfPageModel> _rasterPages = [];
  int _totalPages = 0;
  bool _isLoading = true;
  String? _errorMessage;

  int _carouselIndex = 0;
  int _polaroidIndex = 0;
  bool _showSettings = false;

  int _loadId = 0;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  @override
  void didUpdateWidget(PdfBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPages = oldWidget.block.data['pages'] as List?;
    final newPages = widget.block.data['pages'] as List?;
    final oldCrops = oldWidget.block.data['crops'] as Map?;
    final newCrops = widget.block.data['crops'] as Map?;

    final changed = oldWidget.block.content != widget.block.content ||
        !listEquals(oldPages, newPages) ||
        !mapEquals(oldCrops, newCrops) ||
        oldWidget.block.attributes['layout'] != widget.block.attributes['layout'];
    if (changed) {
      _clearThumbnailCache().then((_) {
        if (mounted) _loadPdf();
      });
    }
  }

  Future<void> _clearThumbnailCache() async {
    if (kIsWeb) return;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${docDir.path}/pdf_thumbnails');
      if (await cacheDir.exists()) {
        final oldFiles = cacheDir.listSync().whereType<File>().where((f) {
          final name = f.path.split(Platform.pathSeparator).last;
          return name.startsWith('pdf_thumb_${widget.block.id}_');
        });
        for (final f in oldFiles) {
          await f.delete();
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _document?.dispose();
    super.dispose();
  }

  String get _normalizedPath {
    var path = widget.block.content;
    if (path.startsWith('file://')) path = path.replaceFirst('file://', '');
    return path.replaceAll(r'\\', '/');
  }

  String get _layout => widget.block.attributes['layout'] ?? 'grid';

  Future<void> _loadPdf() async {
    if (!mounted) return;
    
    final currentLoadId = ++_loadId;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _rasterPages = [];
    });

    try {
      final path = _normalizedPath;
      if (path.isEmpty) throw Exception('PDF file path is empty.');

      // --- CHECK PER-BLOCK IMAGE CACHE ---
      if (!kIsWeb) {
        final docDir = await getApplicationDocumentsDirectory();
        final cacheDir = Directory('${docDir.path}/pdf_thumbnails');
        if (!await cacheDir.exists()) {
          await cacheDir.create(recursive: true);
        }

        final List<dynamic> rawPages = widget.block.data['pages'] ?? [];
        final List<int> selectedPages = List<int>.from(rawPages);
        const maxPagesToPreview = 3;
        final pagesToRender = selectedPages.isEmpty ? [0] : selectedPages.take(maxPagesToPreview).toList();

        final List<PdfPageModel> cachedPages = [];
        bool allCached = true;

        for (final pageIdx in pagesToRender) {
          final List<FileSystemEntity> files = cacheDir.listSync().where((f) {
            final name = f.path.split(Platform.pathSeparator).last;
            return name.startsWith('pdf_thumb_${widget.block.id}_${pageIdx}_') && name.endsWith('.png');
          }).toList();

          if (files.isNotEmpty) {
            final file = files.first as File;
            final name = file.path.split(Platform.pathSeparator).last;
            final parts = name.replaceAll('.png', '').split('_');
            if (parts.length >= 6) {
              final width = double.tryParse(parts[4]) ?? 100.0;
              final height = double.tryParse(parts[5]) ?? 140.0;
              final bytes = await file.readAsBytes();
              cachedPages.add(PdfPageModel(
                index: pageIdx,
                bytes: bytes,
                width: width,
                height: height,
              ));
            } else {
              allCached = false;
              break;
            }
          } else {
            allCached = false;
            break;
          }
        }

        if (allCached && cachedPages.isNotEmpty) {
          if (mounted && currentLoadId == _loadId) {
            setState(() {
              _rasterPages = cachedPages;
              _isLoading = false;
            });
          }
          return;
        }
      }
      // ------------------------------------

      await _document?.dispose();
      if (currentLoadId != _loadId) return;
      _document = null;

      final Uint8List pdfBytes;
      if (path.startsWith('data:')) {
        final base64Str = path.split(',').last;
        pdfBytes = base64Decode(base64Str);
      } else {
        if (kIsWeb) {
          throw Exception('Local file paths are not supported on Web.');
        }
        pdfBytes = await File(path).readAsBytes();
      }

      final doc = await PdfDocument.openData(pdfBytes);
      if (currentLoadId != _loadId) {
        await doc.dispose();
        return;
      }
      _document = doc;
      _totalPages = doc.pages.length;

      final List<dynamic> rawPages = widget.block.data['pages'] ?? [];
      final List<int> selectedPages = List<int>.from(rawPages);

      // Limit to max 3 pages to render inside the note preview, default to 1 page if empty
      const maxPagesToPreview = 3;
      final pagesToRender = selectedPages.isEmpty
          ? List<int>.generate(math.min(1, doc.pages.length), (i) => i)
          : selectedPages.take(maxPagesToPreview).toList();

      for (final pageIdx in pagesToRender) {
        if (!mounted || currentLoadId != _loadId) break;
        final pageNum = pageIdx + 1; // pdfx is 1-based
        if (pageNum < 1 || pageNum > doc.pages.length) continue;

        final page = doc.pages[pageNum - 1]; // pdfrx pages are 0-indexed in the array, but the length is correct.
        
        // Render at a very low resolution (blurry thumbnail preview) to speed up loading
        final renderWidth = (page.width * 0.15).clamp(60.0, 120.0);
        final renderHeight = page.height * (renderWidth / page.width);

        final img = await page.render(
          fullWidth: renderWidth,
          fullHeight: renderHeight,
          backgroundColor: 0xFFFFFFFF,
        );
        
        if (img == null || !mounted || currentLoadId != _loadId) continue;
        
        final uiImage = await img.createImage();
        final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
        img.dispose();
        
        if (byteData == null || !mounted || currentLoadId != _loadId) continue;
        final bytes = byteData.buffer.asUint8List();

        setState(() {
          _rasterPages = [
            ..._rasterPages,
            PdfPageModel(
              index: pageIdx,
              bytes: bytes,
              width: renderWidth,
              height: renderHeight,
            ),
          ];
        });
      }

      // Save all rendered thumbnails to file system cache
      if (!kIsWeb) {
        try {
          final docDir = await getApplicationDocumentsDirectory();
          final cacheDir = Directory('${docDir.path}/pdf_thumbnails');
          if (await cacheDir.exists()) {
            for (final rPage in _rasterPages) {
              final cacheFile = File('${cacheDir.path}/pdf_thumb_${widget.block.id}_${rPage.index}_${rPage.width.toInt()}_${rPage.height.toInt()}.png');
              await cacheFile.writeAsBytes(rPage.bytes);
            }
          }
        } catch (_) {}
      }

      if (mounted && currentLoadId == _loadId) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted && currentLoadId == _loadId) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _updateLayout(String layout) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (widget.onUpdate != null) {
      final List<dynamic> rawPages = widget.block.data['pages'] ?? [];
      final List<int> selectedPages = List<int>.from(rawPages);
      final crops = widget.block.data['crops'] as Map<String, dynamic>? ?? {};
      widget.onUpdate!(selectedPages, crops, layout);
    } else {
      final newAttrs = Map<String, dynamic>.from(widget.block.attributes)
        ..['layout'] = layout;
      ref
          .read(editorBlockControllerProvider.notifier)
          .updateBlockAttributes(widget.block.id, newAttrs);
    }
  }

  Future<void> _openPagesManager(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final doc = _document;
    if (doc == null) return;

    await showDialog(
      context: context,
      builder: (ctx) => PdfPagesManagerDialog(
        pdfPath: _normalizedPath,
        totalPages: doc.pages.length,
        block: widget.block,
        ref: ref,
        onUpdate: widget.onUpdate,
      ),
    );
    _loadPdf();
  }

  void _openPdfReader() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfReaderWorkspaceScreen(
          pdfPath: _normalizedPath,
          onInsertBlock: widget.onInsertBlock,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading && _rasterPages.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.red),
              SizedBox(height: 12),
              Text('Rendering PDF pages...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 36),
            const SizedBox(height: 8),
            Text('Failed to render PDF:',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          ],
        ),
      );
    }

    if (_rasterPages.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.picture_as_pdf_outlined, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text('No pages selected.', style: TextStyle(color: Colors.grey)),
              if (!widget.readOnly) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _openPagesManager(context),
                  icon: const Icon(Icons.pages_outlined),
                  label: const Text('Manage Pages'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) { if (!widget.readOnly) setState(() => _showSettings = true); },
      onExit: (_)  { if (!widget.readOnly) setState(() => _showSettings = false); },
      child: GestureDetector(
        onTapDown: (_) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          if (!widget.readOnly) setState(() => _showSettings = !_showSettings);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _buildLayoutWidget(),
                    ),
                  ),
                  if (!widget.readOnly)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Material(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            setState(() => _showSettings = !_showSettings);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              _showSettings
                                  ? Icons.close_rounded
                                  : Icons.tune_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              AnimatedOpacity(
                opacity: (_showSettings && !widget.readOnly) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(
                      top: (_showSettings && !widget.readOnly) ? 12 : 0),
                  height: (_showSettings && !widget.readOnly) ? 48 : 0,
                  child: (_showSettings && !widget.readOnly)
                      ? _buildControlBar(theme, isDark)
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLayoutWidget() {
    switch (_layout) {
      case 'carousel': return _buildCarouselLayout();
      case 'collage':  return _buildCollageLayout();
      case 'polaroid': return _buildPolaroidLayout();
      case 'folder':   return _buildFolderLayout();
      case 'grid':
      default:         return _buildGridLayout();
    }
  }

  Widget _buildPageCard(PdfPageModel page, {double? height}) {
    final crops = widget.block.data['crops'] as Map<dynamic, dynamic>? ?? {};
    final pageCrop = crops[page.index.toString()] as Map<String, dynamic>?;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(fit: StackFit.expand, children: [
          GestureDetector(
            onTap: _openPdfReader,
            child: PdfRasterPageWidget(page: page, crop: pageCrop),
          ),
        ]),
      ),
    );
  }

  Widget _buildGridLayout() {
    final count = _rasterPages.length;

    if (count == 1) {
      return _buildPageCard(_rasterPages[0], height: 220);
    }
    if (count == 2) {
      return SizedBox(
        height: 180,
        child: Row(children: [
          Expanded(child: _buildPageCard(_rasterPages[0])),
          const SizedBox(width: 8),
          Expanded(child: _buildPageCard(_rasterPages[1])),
        ]),
      );
    }
    if (count == 3) {
      return SizedBox(
        height: 240,
        child: Row(children: [
          Expanded(flex: 2, child: _buildPageCard(_rasterPages[0])),
          const SizedBox(width: 8),
          Expanded(
            child: Column(children: [
              Expanded(child: _buildPageCard(_rasterPages[1])),
              const SizedBox(height: 8),
              Expanded(child: _buildPageCard(_rasterPages[2])),
            ]),
          ),
        ]),
      );
    }

    final List<dynamic> rawPages = widget.block.data['pages'] ?? [];
    final int totalRepresented = rawPages.isEmpty ? _totalPages : rawPages.length;
    final remaining = totalRepresented - 4;

    return SizedBox(
      height: 260,
      child: Column(children: [
        Expanded(
          child: Row(children: [
            Expanded(child: _buildPageCard(_rasterPages[0])),
            const SizedBox(width: 8),
            Expanded(child: _buildPageCard(_rasterPages[1])),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(children: [
            Expanded(child: _buildPageCard(_rasterPages[2])),
            const SizedBox(width: 8),
            Expanded(
              child: Stack(fit: StackFit.expand, children: [
                _buildPageCard(_rasterPages[3]),
                if (remaining > 0)
                  GestureDetector(
                    onTap: _openPdfReader,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '+$remaining',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildCarouselLayout() {
    return SizedBox(
      height: 250,
      child: Stack(children: [
        PageView.builder(
          itemCount: _rasterPages.length,
          onPageChanged: (idx) => setState(() => _carouselIndex = idx),
          itemBuilder: (_, index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: _buildPageCard(_rasterPages[index]),
          ),
        ),
        Positioned(
          bottom: 12, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _rasterPages.length,
              (idx) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                width: _carouselIndex == idx ? 16.0 : 8.0,
                height: 8.0,
                decoration: BoxDecoration(
                  color: _carouselIndex == idx ? Colors.white : Colors.white60,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildCollageLayout() {
    final crops = widget.block.data['crops'] as Map<dynamic, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPageCard(_rasterPages[0], height: 200),
        if (_rasterPages.length > 1) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _rasterPages.length - 1,
              itemBuilder: (_, index) {
                final realIdx = index + 1;
                final page = _rasterPages[realIdx];
                final pageCrop = crops[page.index.toString()] as Map<String, dynamic>?;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: _openPdfReader,
                    child: Container(
                      width: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(fit: StackFit.expand, children: [
                          PdfRasterPageWidget(page: page, crop: pageCrop),
                        ]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPolaroidLayout() {
    final crops = widget.block.data['crops'] as Map<dynamic, dynamic>? ?? {};

    return Center(
      child: SizedBox(
        height: 280,
        width: 240,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: List.generate(_rasterPages.length, (idx) {
            final page = _rasterPages[idx];
            final pageCrop = crops[page.index.toString()] as Map<String, dynamic>?;
            final offset = (idx - _polaroidIndex) % _rasterPages.length;
            final isTop  = offset == _rasterPages.length - 1;
            final angle  = isTop
                ? 0.0
                : ((idx * 8) % 15 - 7.5) * (math.pi / 180.0);

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              top: isTop ? 0 : 8.0 * (_rasterPages.length - 1 - offset),
              child: Transform.rotate(
                angle: angle,
                child: GestureDetector(
                  onTap: () => setState(
                      () => _polaroidIndex = (_polaroidIndex + 1) % _rasterPages.length),
                  onDoubleTap: _openPdfReader,
                  child: Container(
                    width: 210,
                    padding: const EdgeInsets.only(
                        top: 10, left: 10, right: 10, bottom: 25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey.shade100,
                        child: ClipRect(child: PdfRasterPageWidget(page: page, crop: pageCrop)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Page ${page.index + 1}/${_rasterPages.length}',
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 11,
                              color: Colors.black54,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ]),
                  ),
                ),
              ),
            );
          }).reversed.toList(),
        ),
      ),
    );
  }

  Widget _buildFolderLayout() {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final crops = widget.block.data['crops'] as Map<dynamic, dynamic>? ?? {};
    final docName = widget.block.attributes['name'] ?? 'PDF Document';

    return InkWell(
      onTap: _openPdfReader,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF471A1A), const Color(0xFF321818)]
                : [const Color(0xFFFFEDED), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF622C2C) : const Color(0xFFFFDADA),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF682C2C) : const Color(0xFFFFE0E0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.picture_as_pdf_rounded,
              size: 32,
              color: isDark ? const Color(0xFFFC8484) : const Color(0xFFED3A3A),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'PDF Document / Folder',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                docName,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
            ]),
          ),
          SizedBox(
            width: 50,
            height: 40,
            child: Stack(
              clipBehavior: Clip.none,
              children: List.generate(
                math.min(_rasterPages.length, 3),
                (idx) {
                  final page = _rasterPages[idx];
                  final pageCrop = crops[page.index.toString()] as Map<String, dynamic>?;
                  return Positioned(
                    right: idx * 8.0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 1.5),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: PdfRasterPageWidget(page: page, crop: pageCrop),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildControlBar(ThemeData theme, bool isDark) {
    final accent = Colors.red;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xE02A1919)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF452828) : const Color(0xFFF5DCDC),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLayoutBtn(Icons.grid_view_rounded, 'grid', 'Grid', accent, isDark),
              _buildLayoutBtn(Icons.view_carousel_rounded, 'carousel', 'Carousel', accent, isDark),
              _buildLayoutBtn(Icons.dashboard_customize_rounded, 'collage', 'Collage', accent, isDark),
              _buildLayoutBtn(Icons.style_rounded, 'polaroid', 'Polaroid', accent, isDark),
              _buildLayoutBtn(Icons.folder_shared_rounded, 'folder', 'Folder', accent, isDark),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 1,
                height: 24,
                color: isDark ? Colors.white24 : Colors.black12,
              ),
              IconButton(
                icon: Icon(Icons.pages_outlined, color: theme.colorScheme.onSurface, size: 18),
                tooltip: 'Manage Pages',
                onPressed: () => _openPagesManager(context),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                tooltip: 'Remove PDF',
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  widget.onRemoved();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLayoutBtn(IconData icon, String type, String label, Color accent, bool isDark) {
    final isSelected = _layout == type;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: () => _updateLayout(type),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withValues(alpha: isDark ? 0.2 : 0.1)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected ? accent : (isDark ? Colors.white54 : Colors.black54),
          ),
        ),
      ),
    );
  }
}
