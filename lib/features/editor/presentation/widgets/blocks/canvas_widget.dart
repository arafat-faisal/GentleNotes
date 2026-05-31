import 'package:flutter/material.dart';
import 'drawing_controller.dart';

class CanvasWidget extends StatelessWidget {
  final DrawingController controller;
  final GlobalKey canvasKey;

  const CanvasWidget({
    super.key,
    required this.controller,
    required this.canvasKey,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return GestureDetector(
          onPanStart: (d) => controller.startStroke(d.localPosition),
          onPanUpdate: (d) => controller.addPoint(d.localPosition),
          onPanEnd: (_) => controller.endStroke(),
          child: RepaintBoundary(
            key: canvasKey,
            child: CustomPaint(
              painter: DrawingPainter(
                strokes: controller.strokes,
                currentStroke: controller.currentStroke,
                backgroundColor: controller.canvasBgColor,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;
  final Color backgroundColor;

  DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );

    // Save layer to allow BlendMode.clear to work correctly on strokes
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Draw all strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    // Draw current active stroke
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }

    canvas.restore();
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.length < 2) return;

    final paint = Paint()
      ..color = stroke.color.withOpacity(stroke.opacity)
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (stroke.tool == DrawingTool.eraser) {
      paint.blendMode = BlendMode.clear;
    }

    final path = Path();
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

    for (int i = 1; i < stroke.points.length; i++) {
      final p0 = stroke.points[i - 1];
      final p1 = stroke.points[i];
      // Smooth curve
      final midX = (p0.dx + p1.dx) / 2;
      final midY = (p0.dy + p1.dy) / 2;
      path.quadraticBezierTo(p0.dx, p0.dy, midX, midY);
    }
    path.lineTo(stroke.points.last.dx, stroke.points.last.dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
