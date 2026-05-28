import 'package:flutter/material.dart';

// ─── Markdown Layout Mode Enum ──────────────────────────────────────────────────
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
class PreviewStylePainter extends CustomPainter {
  final PreviewStyle style;
  PreviewStylePainter(this.style);

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
  bool shouldRepaint(PreviewStylePainter old) => old.style != style;
}

/// Returns the content padding that ensures text sits inside the ruled/margin area.
/// Left padding pushes text past the margin line; top/right/bottom are standard.
EdgeInsets styleContentPadding(PreviewStyle style) {
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
