import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum DrawingTool { pencil, pen, highlighter, eraser, select }

class DrawingStroke {
  final List<Offset> points;
  final DrawingTool tool;
  final Color color;
  final double strokeWidth;
  final double opacity;

  DrawingStroke({
    required this.points,
    required this.tool,
    required this.color,
    required this.strokeWidth,
    required this.opacity,
  });
}

class DrawingCanvasScreen extends StatefulWidget {
  final List<DrawingStroke>? initialStrokes;
  final Function(List<DrawingStroke> strokes, Uint8List? pngBytes)? onSave;

  const DrawingCanvasScreen({
    super.key,
    this.initialStrokes,
    this.onSave,
  });

  @override
  State<DrawingCanvasScreen> createState() => _DrawingCanvasScreenState();
}

class _DrawingCanvasScreenState extends State<DrawingCanvasScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  List<DrawingStroke> _strokes = [];
  List<DrawingStroke> _undoStack = [];
  DrawingStroke? _currentStroke;

  DrawingTool _activeTool = DrawingTool.pen;
  Color _activeColor = Colors.black;
  double _strokeWidth = 3.0;
  Color _canvasBgColor = Colors.white;
  bool _showColorPicker = false;
  bool _isDraggingSlider = false;

  final List<Color> _colorPalette = [
    Colors.black,
    Colors.white,
    const Color(0xFF8B5CF6),
    const Color(0xFF3B82F6),
    const Color(0xFF10B981),
    const Color(0xFFEF4444),
    const Color(0xFFF97316),
    const Color(0xFFEAB308),
    const Color(0xFFEC4899),
    const Color(0xFF6B7280),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialStrokes != null) {
      _strokes = List.from(widget.initialStrokes!);
    }
  }

  void _startStroke(Offset position) {
    if (_activeTool == DrawingTool.eraser) {
      _currentStroke = DrawingStroke(
        points: [position],
        tool: DrawingTool.eraser,
        color: _canvasBgColor,
        strokeWidth: _strokeWidth * 4,
        opacity: 1.0,
      );
    } else {
      _currentStroke = DrawingStroke(
        points: [position],
        tool: _activeTool,
        color: _activeColor,
        strokeWidth: _activeTool == DrawingTool.pencil
            ? _strokeWidth * 0.7
            : _activeTool == DrawingTool.highlighter
                ? _strokeWidth * 5
                : _strokeWidth,
        opacity: _activeTool == DrawingTool.highlighter ? 0.4 : 1.0,
      );
    }
    setState(() {});
  }

  void _addPoint(Offset position) {
    if (_currentStroke == null) return;
    _currentStroke!.points.add(position);
    setState(() {});
  }

  void _endStroke() {
    if (_currentStroke != null && _currentStroke!.points.length > 1) {
      setState(() {
        _strokes.add(_currentStroke!);
        _undoStack.clear();
        _currentStroke = null;
      });
    } else {
      setState(() => _currentStroke = null);
    }
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _undoStack.add(_strokes.removeLast());
      });
    }
  }

  void _redo() {
    if (_undoStack.isNotEmpty) {
      setState(() {
        _strokes.add(_undoStack.removeLast());
      });
    }
  }

  void _clearCanvas() {
    setState(() {
      _strokes.clear();
      _undoStack.clear();
      _currentStroke = null;
    });
  }

  Future<Uint8List?> _exportToPng() async {
    try {
      final boundary = _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveAndClose() async {
    final pngBytes = await _exportToPng();
    widget.onSave?.call(List.from(_strokes), pngBytes);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B18),
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP TOOLBAR ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF13111C) : const Color(0xFF1E1B2E),
                border: const Border(bottom: BorderSide(color: Color(0xFF252234))),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Close
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close without saving',
                    ),
                    const SizedBox(width: 8),
                    const Text('Drawing Canvas',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
                    const SizedBox(width: 16),
                    // Undo
                    IconButton(
                      icon: const Icon(Icons.undo_rounded, color: Colors.white70, size: 20),
                      onPressed: _strokes.isEmpty ? null : _undo,
                      tooltip: 'Undo',
                    ),
                    // Redo
                    IconButton(
                      icon: const Icon(Icons.redo_rounded, color: Colors.white70, size: 20),
                      onPressed: _undoStack.isEmpty ? null : _redo,
                      tooltip: 'Redo',
                    ),
                    // Clear
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFF87171), size: 20),
                      onPressed: _strokes.isEmpty ? null : () => _showClearDialog(),
                      tooltip: 'Clear all',
                    ),
                    const SizedBox(width: 8),
                    // Save
                    FilledButton.icon(
                      onPressed: _saveAndClose,
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Save'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── CANVAS AREA ───────────────────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  // Canvas
                  GestureDetector(
                    onPanStart: (d) => _startStroke(d.localPosition),
                    onPanUpdate: (d) => _addPoint(d.localPosition),
                    onPanEnd: (_) => _endStroke(),
                    child: RepaintBoundary(
                      key: _canvasKey,
                      child: CustomPaint(
                        painter: _DrawingPainter(
                          strokes: _strokes,
                          currentStroke: _currentStroke,
                          backgroundColor: _canvasBgColor,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),

                  // Color picker overlay
                  if (_showColorPicker)
                    Positioned(
                      bottom: 90,
                      left: 16,
                      child: _buildColorPickerPanel(),
                    ),
                    
                  // Brush size preview overlay
                  if (_isDraggingSlider)
                    Center(
                      child: Container(
                        width: _activeTool == DrawingTool.highlighter ? _strokeWidth * 5 :
                               _activeTool == DrawingTool.eraser ? _strokeWidth * 4 :
                               _activeTool == DrawingTool.pencil ? _strokeWidth * 0.7 : _strokeWidth,
                        height: _activeTool == DrawingTool.highlighter ? _strokeWidth * 5 :
                                _activeTool == DrawingTool.eraser ? _strokeWidth * 4 :
                                _activeTool == DrawingTool.pencil ? _strokeWidth * 0.7 : _strokeWidth,
                        decoration: BoxDecoration(
                          color: _activeTool == DrawingTool.eraser 
                              ? Colors.black12 
                              : _activeTool == DrawingTool.highlighter
                                  ? _activeColor.withOpacity(0.4)
                                  : _activeColor,
                          shape: BoxShape.circle,
                          border: _activeTool == DrawingTool.eraser 
                              ? Border.all(color: Colors.white54, width: 2) 
                              : Border.all(color: Colors.white24, width: 1),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 12, spreadRadius: 2)
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── BOTTOM TOOLBAR ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF13111C) : const Color(0xFF1E1B2E),
                border: const Border(top: BorderSide(color: Color(0xFF252234))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Color dot
                  GestureDetector(
                    onTap: () => setState(() => _showColorPicker = !_showColorPicker),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _activeColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30, width: 2),
                      ),
                    ),
                  ),

                  // Tool buttons
                  _toolButton(DrawingTool.pencil, Icons.edit_outlined, 'Pencil'),
                  _toolButton(DrawingTool.pen, Icons.create_rounded, 'Pen'),
                  _toolButton(DrawingTool.highlighter, Icons.highlight_rounded, 'Highlighter'),
                  _toolButton(DrawingTool.eraser, Icons.auto_fix_normal_rounded, 'Eraser'),

                  // Stroke width slider
                  SizedBox(
                    width: 100,
                    child: Slider(
                      value: _strokeWidth,
                      min: 1.0,
                      max: 20.0,
                      activeColor: const Color(0xFF8B5CF6),
                      inactiveColor: Colors.white12,
                      onChangeStart: (_) => setState(() => _isDraggingSlider = true),
                      onChangeEnd: (_) => setState(() => _isDraggingSlider = false),
                      onChanged: (v) => setState(() => _strokeWidth = v),
                    ),
                  ),

                  // Canvas bg toggle
                  IconButton(
                    icon: Icon(
                      _canvasBgColor == Colors.white
                          ? Icons.brightness_2_outlined
                          : Icons.brightness_7_outlined,
                      color: Colors.white70,
                      size: 20,
                    ),
                    tooltip: 'Toggle canvas background',
                    onPressed: () => setState(() {
                      _canvasBgColor =
                          _canvasBgColor == Colors.white ? const Color(0xFF1E1B2E) : Colors.white;
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolButton(DrawingTool tool, IconData icon, String label) {
    final isActive = _activeTool == tool;
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: () => setState(() {
          _activeTool = tool;
          _showColorPicker = false;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF8B5CF6).withOpacity(0.25) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? const Color(0xFF8B5CF6) : Colors.transparent,
            ),
          ),
          child: Icon(icon, color: isActive ? const Color(0xFF8B5CF6) : Colors.white60, size: 22),
        ),
      ),
    );
  }

  Widget _buildColorPickerPanel() {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF13111C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF252234)),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Color', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorPalette.map((c) {
                final isSelected = _activeColor == c;
                return GestureDetector(
                  onTap: () => setState(() {
                    _activeColor = c;
                    _showColorPicker = false;
                  }),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF8B5CF6) : Colors.white24,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13111C),
        title: const Text('Clear Canvas', style: TextStyle(color: Colors.white)),
        content: const Text('This will erase all strokes. Are you sure?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF87171)),
            onPressed: () {
              Navigator.pop(ctx);
              _clearCanvas();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;
  final Color backgroundColor;

  _DrawingPainter({
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
  bool shouldRepaint(_DrawingPainter oldDelegate) => true;
}
