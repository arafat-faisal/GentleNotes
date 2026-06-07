import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';

import '../../../domain/entities/block_entity.dart';
import '../../controllers/editor_block_controller.dart';
import 'pdf_page_cropper_dialog.dart';
import 'pdf_block.dart'; // PdfPageModel

class PdfPagesManagerDialog extends StatefulWidget {
  final String pdfPath;
  final int totalPages;
  final BlockEntity block;
  final WidgetRef ref;
  final void Function(List<int> pages, Map<String, dynamic> crops, String layout)? onUpdate;

  const PdfPagesManagerDialog({
    super.key,
    required this.pdfPath,
    required this.totalPages,
    required this.block,
    required this.ref,
    this.onUpdate,
  });

  @override
  State<PdfPagesManagerDialog> createState() => _PdfPagesManagerDialogState();
}

class _PdfPagesManagerDialogState extends State<PdfPagesManagerDialog> {
  PdfDocument? _document;
  final List<PdfPageModel> _thumbnails = [];
  bool _loading = true;
  late Set<int> _selectedPages;
  late Map<String, dynamic> _crops;

  @override
  void initState() {
    super.initState();
    final List<dynamic> pagesRaw = widget.block.data['pages'] ?? [];
    _selectedPages = Set<int>.from(pagesRaw.cast<int>());
    _crops = Map<String, dynamic>.from(widget.block.data['crops'] ?? {});
    _loadThumbnails();
  }

  @override
  void dispose() {
    _document?.close();
    super.dispose();
  }

  Future<void> _loadThumbnails() async {
    try {
      final doc = await PdfDocument.openData(await File(widget.pdfPath).readAsBytes());
      _document = doc;

      for (int i = 0; i < doc.pagesCount; i++) {
        if (!mounted) return;
        final pageNum = i + 1; // pdfx is 1-based
        final page = await doc.getPage(pageNum);

        // Render at low resolution for thumbnails
        final thumbWidth = (page.width * 0.25).clamp(80.0, 300.0);
        final thumbHeight = page.height * (thumbWidth / page.width);

        final img = await page.render(
          width: thumbWidth,
          height: thumbHeight,
          format: PdfPageImageFormat.png,
          backgroundColor: '#FFFFFF',
        );
        await page.close();

        if (img == null || !mounted) continue;

        setState(() {
          _thumbnails.add(PdfPageModel(
            index: i,
            bytes: img.bytes,
            width: thumbWidth,
            height: thumbHeight,
          ));
        });
      }
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Opens a higher-resolution version of the page for cropping.
  Future<void> _openCropper(BuildContext ctx, PdfPageModel thumb) async {
    // Show loading indicator while we render the high-res page
    if (!ctx.mounted) return;
    showDialog(
      context: ctx,
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
                Text('Loading page for cropping…'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final doc = _document;
      if (doc == null) return;
      final page = await doc.getPage(thumb.index + 1);
      final hiWidth = (page.width * 0.8).clamp(300.0, 900.0);
      final hiHeight = page.height * (hiWidth / page.width);

      final hiImg = await page.render(
        width: hiWidth,
        height: hiHeight,
        format: PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
      );
      await page.close();

      if (!ctx.mounted) return;
      Navigator.pop(ctx); // Dismiss spinner

      if (hiImg == null) return;

      // Decode to ui.Image for the cropper widget
      final codec = await ui.instantiateImageCodec(hiImg.bytes);
      final frame = await codec.getNextFrame();
      final uiImage = frame.image;

      if (!ctx.mounted) return;

      final cropKey = thumb.index.toString();
      final initialCropMap = _crops[cropKey] as Map<String, dynamic>?;
      Rect? initialCrop;
      if (initialCropMap != null) {
        initialCrop = Rect.fromLTWH(
          (initialCropMap['left'] as num).toDouble(),
          (initialCropMap['top'] as num).toDouble(),
          (initialCropMap['width'] as num).toDouble(),
          (initialCropMap['height'] as num).toDouble(),
        );
      }

      final Rect? result = await showDialog<Rect?>(
        context: ctx,
        builder: (c) => PdfPageCropperDialog(image: uiImage, initialCrop: initialCrop),
      );

      if (result != null) {
        setState(() {
          if (result == Rect.zero) {
            _crops.remove(cropKey);
          } else {
            _crops[cropKey] = {
              'left': result.left,
              'top': result.top,
              'width': result.width,
              'height': result.height,
            };
          }
        });
      }
    } catch (_) {
      if (ctx.mounted) Navigator.pop(ctx);
    }
  }

  void _saveAndClose() {
    List<int> pagesList = _selectedPages.toList()..sort();
    // If all pages are selected, store as empty (= show all)
    if (pagesList.length == widget.totalPages) pagesList = [];

    if (widget.onUpdate != null) {
      widget.onUpdate!(pagesList, _crops, widget.block.attributes['layout'] ?? 'grid');
    } else {
      widget.ref
          .read(editorBlockControllerProvider.notifier)
          .updateBlockData(widget.block.id, {
            ...widget.block.data,
            'pages': pagesList,
            'crops': _crops,
          });
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.totalPages;

    return AlertDialog(
      title: const Text('Manage PDF Pages'),
      content: SizedBox(
        width: 450,
        height: 500,
        child: _loading && _thumbnails.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Colors.red))
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: _thumbnails.length,
                itemBuilder: (context, i) {
                  final page = _thumbnails[i];
                  final isSelected =
                      _selectedPages.isEmpty || _selectedPages.contains(page.index);
                  final hasCrop = _crops.containsKey(page.index.toString());

                  return Card(
                    elevation: 0,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.red
                            : theme.colorScheme.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Stack(children: [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 36, 8, 44),
                          child: Image.memory(page.bytes, fit: BoxFit.contain),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Row(children: [
                          Checkbox(
                            activeColor: Colors.red,
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (_selectedPages.isEmpty) {
                                  _selectedPages
                                      .addAll(List.generate(total, (i) => i));
                                }
                                if (val == true) {
                                  _selectedPages.add(page.index);
                                } else {
                                  _selectedPages.remove(page.index);
                                }
                              });
                            },
                          ),
                          Text(
                            'Page ${page.index + 1}',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ]),
                      ),
                      if (isSelected)
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: ElevatedButton.icon(
                            onPressed: () => _openCropper(context, page),
                            icon: Icon(
                              hasCrop ? Icons.check_box_outlined : Icons.crop,
                              size: 14,
                            ),
                            label: Text(
                              hasCrop ? 'Cropped' : 'Crop',
                              style: const TextStyle(fontSize: 11),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              backgroundColor: hasCrop
                                  ? Colors.green.shade50.withValues(alpha: 0.9)
                                  : Colors.red.shade50.withValues(alpha: 0.9),
                              foregroundColor: hasCrop
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              elevation: 0,
                            ),
                          ),
                        ),
                    ]),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveAndClose,
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
