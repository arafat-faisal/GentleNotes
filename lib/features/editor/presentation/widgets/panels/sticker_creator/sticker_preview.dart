import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'sticker_creator_controller.dart';

class StickerPreview extends StatelessWidget {
  final int tabIndex;
  final bool isDark;
  
  // Doodle Preview params
  final List<DoodleLine> doodleLines;
  final DoodleLine? currentDoodleLine;

  // Text Card Preview params
  final String cardText;
  final Color cardTextColor;
  final double cardCornerRadius;
  final double cardBorderWidth;
  final Color cardBorderColor;
  final List<Color> cardGradientColors;

  // Photo Mask Preview params
  final String? photoPath;
  final String photoMask;
  final double photoBorderWidth;
  final Color photoBorderColor;

  const StickerPreview({
    super.key,
    required this.tabIndex,
    required this.isDark,
    required this.doodleLines,
    this.currentDoodleLine,
    required this.cardText,
    required this.cardTextColor,
    required this.cardCornerRadius,
    required this.cardBorderWidth,
    required this.cardBorderColor,
    required this.cardGradientColors,
    required this.photoPath,
    required this.photoMask,
    required this.photoBorderWidth,
    required this.photoBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1B28) : const Color(0xFFF7F5FC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2740) : const Color(0xFFECE9F3),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          width: 140,
          height: 140,
          child: _buildPreviewContent(),
        ),
      ),
    );
  }

  Widget _buildPreviewContent() {
    if (tabIndex == 0) {
      // Doodle Preview
      return CustomPaint(
        painter: DoodlePainter(
          lines: doodleLines,
          currentLine: currentDoodleLine,
        ),
      );
    } else if (tabIndex == 1) {
      // Text Card Preview
      final grad = cardGradientColors;
      final hasGrad = grad.length > 1;

      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: hasGrad ? null : grad.first,
            gradient: hasGrad ? LinearGradient(colors: grad) : null,
            borderRadius: BorderRadius.circular(cardCornerRadius / 2),
            border: cardBorderWidth > 0
                ? Border.all(color: cardBorderColor, width: cardBorderWidth / 2)
                : null,
          ),
          child: IntrinsicWidth(
            child: Center(
              child: Text(
                cardText.isEmpty ? 'Sample' : cardText,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cardTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    } else {
      // Photo Mask Preview
      if (photoPath == null) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_outlined, size: 36, color: Colors.grey),
              SizedBox(height: 6),
              Text('No Image Selected', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        );
      }

      Widget imgWidget = kIsWeb
          ? Image.network(
              photoPath!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
          : Image.file(
              File(photoPath!),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            );

      if (photoMask != 'original') {
        imgWidget = ClipPath(
          clipper: ShapeMaskClipper(photoMask),
          child: imgWidget,
        );
      }

      return Stack(
        children: [
          Positioned.fill(child: imgWidget),
          if (photoBorderWidth > 0)
            Positioned.fill(
              child: CustomPaint(
                painter: BorderShapePainter(
                  shape: photoMask,
                  borderColor: photoBorderColor,
                  borderWidth: photoBorderWidth,
                ),
              ),
            ),
        ],
      );
    }
  }
}

// ── Doodle Painter ─────────────────────────────────────────────────
class DoodlePainter extends CustomPainter {
  final List<DoodleLine> lines;
  final DoodleLine? currentLine;

  DoodlePainter({
    required this.lines,
    this.currentLine,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void drawSingleLine(DoodleLine line) {
      if (line.points.isEmpty) return;
      paint.color = line.color;
      paint.strokeWidth = line.strokeWidth;
      
      if (line.color == Colors.transparent) {
        paint.blendMode = BlendMode.clear;
      } else {
        paint.blendMode = BlendMode.srcOver;
      }

      final path = Path();
      path.moveTo(line.points.first.dx, line.points.first.dy);
      for (int i = 1; i < line.points.length; i++) {
        path.lineTo(line.points[i].dx, line.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    for (final line in lines) {
      drawSingleLine(line);
    }

    if (currentLine != null) {
      drawSingleLine(currentLine!);
    }
  }

  @override
  bool shouldRepaint(covariant DoodlePainter oldDelegate) => true;
}

// ── Shape Mask Clipper ──────────────────────────────────────────────
class ShapeMaskClipper extends CustomClipper<Path> {
  final String shape;
  ShapeMaskClipper(this.shape);

  @override
  Path getClip(Size size) {
    final path = Path();
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    if (shape == 'circle') {
      path.addOval(rect);
    } else if (shape == 'rrect') {
      path.addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(24)));
    } else if (shape == 'heart') {
      final w = size.width;
      final h = size.height;
      path.moveTo(w * 0.5, h * 0.25);
      path.cubicTo(w * 0.2, h * 0.05, w * 0.0, h * 0.25, w * 0.0, h * 0.5);
      path.cubicTo(w * 0.0, h * 0.75, w * 0.25, h * 0.9, w * 0.5, h);
      path.cubicTo(w * 0.75, h * 0.9, w * 1.0, h * 0.75, w * 1.0, h * 0.5);
      path.cubicTo(w * 1.0, h * 0.25, w * 0.8, h * 0.05, w * 0.5, h * 0.25);
      path.close();
    } else if (shape == 'star') {
      final double cx = size.width / 2;
      final double cy = size.height / 2;
      final int points = 5;
      final double outerRadius = size.width / 2;
      final double innerRadius = size.width / 4;
      double angle = -3.141592653589793 / 2;
      final double step = 3.141592653589793 / points;

      path.moveTo(cx + outerRadius * cos(angle), cy + outerRadius * sin(angle));
      for (int i = 0; i < points; i++) {
        angle += step;
        path.lineTo(cx + innerRadius * cos(angle), cy + innerRadius * sin(angle));
        angle += step;
        path.lineTo(cx + outerRadius * cos(angle), cy + outerRadius * sin(angle));
      }
      path.close();
    } else {
      path.addRect(rect);
    }
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

// ── Border Shape Painter ───────────────────────────────────────────
class BorderShapePainter extends CustomPainter {
  final String shape;
  final Color borderColor;
  final double borderWidth;

  BorderShapePainter({
    required this.shape,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth / 2
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path();

    if (shape == 'circle') {
      canvas.drawOval(rect, paint);
    } else if (shape == 'rrect') {
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(24)), paint);
    } else if (shape == 'heart') {
      final w = size.width;
      final h = size.height;
      path.moveTo(w * 0.5, h * 0.25);
      path.cubicTo(w * 0.2, h * 0.05, w * 0.0, h * 0.25, w * 0.0, h * 0.5);
      path.cubicTo(w * 0.0, h * 0.75, w * 0.25, h * 0.9, w * 0.5, h);
      path.cubicTo(w * 0.75, h * 0.9, w * 1.0, h * 0.75, w * 1.0, h * 0.5);
      path.cubicTo(w * 1.0, h * 0.25, w * 0.8, h * 0.05, w * 0.5, h * 0.25);
      path.close();
      canvas.drawPath(path, paint);
    } else if (shape == 'star') {
      final double cx = size.width / 2;
      final double cy = size.height / 2;
      final int points = 5;
      final double outerRadius = size.width / 2;
      final double innerRadius = size.width / 4;
      double angle = -3.141592653589793 / 2;
      final double step = 3.141592653589793 / points;

      path.moveTo(cx + outerRadius * cos(angle), cy + outerRadius * sin(angle));
      for (int i = 0; i < points; i++) {
        angle += step;
        path.lineTo(cx + innerRadius * cos(angle), cy + innerRadius * sin(angle));
        angle += step;
        path.lineTo(cx + outerRadius * cos(angle), cy + outerRadius * sin(angle));
      }
      path.close();
      canvas.drawPath(path, paint);
    } else {
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BorderShapePainter oldDelegate) => true;
}
