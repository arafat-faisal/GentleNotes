import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class DoodleLine {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DoodleLine({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

class StickerCreatorController {
  StickerCreatorController._();

  static const List<Color> curatedColors = [
    Color(0xFFEF4444), // Red
    Color(0xFFF97316), // Orange
    Color(0xFFFACC15), // Yellow
    Color(0xFF10B981), // Green
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF1F2937), // Dark Gray/Black
    Color(0xFFFFFFFF), // White
    Color(0xFFFCA5A5), // Pastel Red
    Color(0xFFFED7AA), // Pastel Orange
    Color(0xFFFEF08A), // Pastel Yellow
    Color(0xFFA7F3D0), // Pastel Green
    Color(0xFFBFDBFE), // Pastel Blue
    Color(0xFFDDD6FE), // Pastel Purple
  ];

  static const List<List<Color>> cardGradients = [
    [Color(0xFF8B5CF6), Color(0xFFEC4899)], // Lavender Mist
    [Color(0xFFF97316), Color(0xFFEF4444)], // Sunset Glow
    [Color(0xFF06B6D4), Color(0xFF3B82F6)], // Ocean Wave
    [Color(0xFF10B981), Color(0xFF059669)], // Forest Mint
    [Color(0xFF1F2937), Color(0xFF111827)], // Cyber Dark
    [Colors.white, Colors.white], // Pure White
  ];

  static Future<Uint8List> renderDoodleToBytes(List<DoodleLine> lines, Size size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final line in lines) {
      if (line.points.isEmpty) continue;
      
      if (line.color == Colors.transparent) {
        paint.blendMode = BlendMode.clear;
        paint.color = Colors.black;
      } else {
        paint.blendMode = BlendMode.srcOver;
        paint.color = line.color;
      }
      paint.strokeWidth = line.strokeWidth * 2;

      final path = Path();
      final scale = size.width / 140.0;
      
      path.moveTo(line.points.first.dx * scale, line.points.first.dy * scale);
      for (int i = 1; i < line.points.length; i++) {
        path.lineTo(line.points[i].dx * scale, line.points[i].dy * scale);
      }
      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static Future<Uint8List> renderTextCardToBytes({
    required String text,
    required Color textColor,
    required double cornerRadius,
    required List<Color> gradientColors,
    required Color borderColor,
    required double borderWidth,
    required Size size,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius * 2));

    final bgPaint = Paint();
    if (gradientColors.length == 1) {
      bgPaint.color = gradientColors.first;
    } else {
      bgPaint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors,
      ).createShader(rect);
    }
    canvas.drawRRect(rrect, bgPaint);

    if (borderWidth > 0) {
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth * 2;
      canvas.drawRRect(rrect, borderPaint);
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(maxWidth: size.width - 48);

    final textX = (size.width - textPainter.width) / 2;
    final textY = (size.height - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(textX, textY));

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static Future<Uint8List> renderMaskedPhotoToBytes({
    required ui.Image image,
    required String maskShape,
    required double borderWidth,
    required Color borderColor,
    required Size size,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path();

    if (maskShape == 'circle') {
      path.addOval(rect);
    } else if (maskShape == 'rrect') {
      path.addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(48)));
    } else if (maskShape == 'heart') {
      final w = size.width;
      final h = size.height;
      path.moveTo(w * 0.5, h * 0.25);
      path.cubicTo(w * 0.2, h * 0.05, w * 0.0, h * 0.25, w * 0.0, h * 0.5);
      path.cubicTo(w * 0.0, h * 0.75, w * 0.25, h * 0.9, w * 0.5, h);
      path.cubicTo(w * 0.75, h * 0.9, w * 1.0, h * 0.75, w * 1.0, h * 0.5);
      path.cubicTo(w * 1.0, h * 0.25, w * 0.8, h * 0.05, w * 0.5, h * 0.25);
      path.close();
    } else if (maskShape == 'star') {
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

    canvas.save();
    canvas.clipPath(path);

    paintImage(
      canvas: canvas,
      rect: rect,
      image: image,
      fit: BoxFit.cover,
    );
    canvas.restore();

    if (borderWidth > 0) {
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth * 2;
        
      if (maskShape == 'circle') {
        canvas.drawOval(rect, borderPaint);
      } else if (maskShape == 'rrect') {
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(48)), borderPaint);
      } else {
        canvas.drawPath(path, borderPaint);
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
