import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class PdfPageCropperDialog extends StatefulWidget {
  final ui.Image image;
  final Rect? initialCrop;

  const PdfPageCropperDialog({
    super.key,
    required this.image,
    this.initialCrop,
  });

  @override
  State<PdfPageCropperDialog> createState() => _PdfPageCropperDialogState();
}

class _PdfPageCropperDialogState extends State<PdfPageCropperDialog> {
  late double _left;
  late double _top;
  late double _width;
  late double _height;

  @override
  void initState() {
    super.initState();
    final crop = widget.initialCrop ?? const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);
    _left = crop.left.clamp(0.0, 1.0);
    _top = crop.top.clamp(0.0, 1.0);
    _width = crop.width.clamp(0.1, 1.0 - _left);
    _height = crop.height.clamp(0.1, 1.0 - _top);
  }

  Widget _buildHandle({required Function(double dx, double dy) onDrag}) {
    return GestureDetector(
      onPanUpdate: (details) => onDrag(details.delta.dx, details.delta.dy),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageAspect = widget.image.width / widget.image.height;

    return AlertDialog(
      title: const Text('Crop Page'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Drag the handles to crop the page, or drag the center box to reposition the window.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 350, maxWidth: 300),
                child: AspectRatio(
                  aspectRatio: imageAspect,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double w = constraints.maxWidth;
                      final double h = constraints.maxHeight;

                      final boxLeft = _left * w;
                      final boxTop = _top * h;
                      final boxWidth = _width * w;
                      final boxHeight = _height * h;

                      const handleOffset = 12.0; // Half of 24.0 handle size

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Underlying Page Image
                          Positioned.fill(
                            child: RawImage(
                              image: widget.image,
                              fit: BoxFit.fill,
                            ),
                          ),

                          // Custom barrier overlay
                          Positioned.fill(
                            child: CustomPaint(
                              painter: CropperOverlayPainter(
                                cropRect: Rect.fromLTWH(_left, _top, _width, _height),
                              ),
                            ),
                          ),

                          // Draggable center box for panning the crop window
                          Positioned(
                            left: boxLeft,
                            top: boxTop,
                            width: boxWidth,
                            height: boxHeight,
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                setState(() {
                                  final dx = details.delta.dx / w;
                                  final dy = details.delta.dy / h;
                                  _left = (_left + dx).clamp(0.0, 1.0 - _width);
                                  _top = (_top + dy).clamp(0.0, 1.0 - _height);
                                });
                              },
                              child: Container(
                                color: Colors.transparent,
                              ),
                            ),
                          ),

                          // Top-Left Handle
                          Positioned(
                            left: boxLeft - handleOffset,
                            top: boxTop - handleOffset,
                            child: _buildHandle(
                              onDrag: (dx, dy) {
                                setState(() {
                                  final newLeft = (_left + dx / w).clamp(0.0, _left + _width - 0.1);
                                  final deltaW = _left - newLeft;
                                  _left = newLeft;
                                  _width = (_width + deltaW).clamp(0.1, 1.0 - _left);

                                  final newTop = (_top + dy / h).clamp(0.0, _top + _height - 0.1);
                                  final deltaH = _top - newTop;
                                  _top = newTop;
                                  _height = (_height + deltaH).clamp(0.1, 1.0 - _top);
                                });
                              },
                            ),
                          ),

                          // Top-Right Handle
                          Positioned(
                            left: boxLeft + boxWidth - handleOffset,
                            top: boxTop - handleOffset,
                            child: _buildHandle(
                              onDrag: (dx, dy) {
                                setState(() {
                                  _width = (_width + dx / w).clamp(0.1, 1.0 - _left);

                                  final newTop = (_top + dy / h).clamp(0.0, _top + _height - 0.1);
                                  final deltaH = _top - newTop;
                                  _top = newTop;
                                  _height = (_height + deltaH).clamp(0.1, 1.0 - _top);
                                });
                              },
                            ),
                          ),

                          // Bottom-Left Handle
                          Positioned(
                            left: boxLeft - handleOffset,
                            top: boxTop + boxHeight - handleOffset,
                            child: _buildHandle(
                              onDrag: (dx, dy) {
                                setState(() {
                                  final newLeft = (_left + dx / w).clamp(0.0, _left + _width - 0.1);
                                  final deltaW = _left - newLeft;
                                  _left = newLeft;
                                  _width = (_width + deltaW).clamp(0.1, 1.0 - _left);

                                  _height = (_height + dy / h).clamp(0.1, 1.0 - _top);
                                });
                              },
                            ),
                          ),

                          // Bottom-Right Handle
                          Positioned(
                            left: boxLeft + boxWidth - handleOffset,
                            top: boxTop + boxHeight - handleOffset,
                            child: _buildHandle(
                              onDrag: (dx, dy) {
                                setState(() {
                                  _width = (_width + dx / w).clamp(0.1, 1.0 - _left);
                                  _height = (_height + dy / h).clamp(0.1, 1.0 - _top);
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, Rect.zero),
          child: const Text('Reset Crop', style: TextStyle(color: Colors.orange)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              Rect.fromLTWH(_left, _top, _width, _height),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class CropperOverlayPainter extends CustomPainter {
  final Rect cropRect;
  final Color barrierColor;

  CropperOverlayPainter({
    required this.cropRect,
    this.barrierColor = const Color(0x99000000),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = barrierColor;

    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final targetRect = Rect.fromLTWH(
      cropRect.left * size.width,
      cropRect.top * size.height,
      cropRect.width * size.width,
      cropRect.height * size.height,
    );

    final path = Path()
      ..addRect(fullRect)
      ..addRect(targetRect);
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(targetRect, borderPaint);
  }

  @override
  bool shouldRepaint(CropperOverlayPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect || oldDelegate.barrierColor != barrierColor;
  }
}
