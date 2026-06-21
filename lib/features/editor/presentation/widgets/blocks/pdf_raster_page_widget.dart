import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'pdf_block.dart'; // PdfPageModel

/// Renders a single rasterized PDF page (from pdfx bytes),
/// applying an optional normalized crop rectangle [crop] with keys
/// left/top/width/height in the range [0, 1].
class PdfRasterPageWidget extends StatefulWidget {
  final PdfPageModel page;
  final Map<String, dynamic>? crop;

  const PdfRasterPageWidget({
    super.key,
    required this.page,
    required this.crop,
  });

  @override
  State<PdfRasterPageWidget> createState() => _PdfRasterPageWidgetState();
}

class _PdfRasterPageWidgetState extends State<PdfRasterPageWidget> {
  ui.Image? _image;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _decodeImage(widget.page.bytes);
  }

  @override
  void didUpdateWidget(PdfRasterPageWidget old) {
    super.didUpdateWidget(old);
    if (old.page.index != widget.page.index ||
        old.page.bytes != widget.page.bytes) {
      _decodeImage(widget.page.bytes);
    }
  }

  Future<void> _decodeImage(Uint8List bytes) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _image = frame.image;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 120,
        child: Center(
            child: CircularProgressIndicator(
                color: Colors.red, strokeWidth: 2)),
      );
    }

    final img = _image;
    if (img == null) {
      return const SizedBox(
        height: 120,
        child: Center(
            child: Icon(Icons.broken_image, color: Colors.grey, size: 40)),
      );
    }

    // Build normalized crop rect (defaults to full image)
    final c = widget.crop;
    Rect cropRect = const Rect.fromLTWH(0, 0, 1, 1);
    if (c != null) {
      cropRect = Rect.fromLTWH(
        (c['left'] as num?)?.toDouble() ?? 0.0,
        (c['top'] as num?)?.toDouble() ?? 0.0,
        (c['width'] as num?)?.toDouble() ?? 1.0,
        (c['height'] as num?)?.toDouble() ?? 1.0,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double cropW = cropRect.width * img.width;
        final double cropH = cropRect.height * img.height;
        final double aspect = cropW / (cropH > 0 ? cropH : 1);

        return Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.5),
            ),
          ),
          child: AspectRatio(
            aspectRatio: aspect,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
              child: CustomPaint(painter: _CropPainter(img, cropRect)),
            ),
          ),
        );
      },
    );
  }
}

class _CropPainter extends CustomPainter {
  final ui.Image image;
  final Rect cropRect;

  _CropPainter(this.image, this.cropRect);

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      cropRect.left * image.width,
      cropRect.top * image.height,
      cropRect.width * image.width,
      cropRect.height * image.height,
    );
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(_CropPainter old) =>
      old.image != image || old.cropRect != cropRect;
}
