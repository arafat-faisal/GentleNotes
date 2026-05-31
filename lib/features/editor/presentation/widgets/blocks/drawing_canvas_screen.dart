import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'drawing_controller.dart';
import 'canvas_widget.dart';

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
  late DrawingController _controller;

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
    _controller = DrawingController(initialStrokes: widget.initialStrokes);
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
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
    widget.onSave?.call(List.from(_controller.strokes), pngBytes);
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
                    IconButton(
                      icon: const Icon(Icons.undo_rounded, color: Colors.white70, size: 20),
                      onPressed: _controller.strokes.isEmpty ? null : _controller.undo,
                      tooltip: 'Undo',
                    ),
                    IconButton(
                      icon: const Icon(Icons.redo_rounded, color: Colors.white70, size: 20),
                      onPressed: _controller.undoStack.isEmpty ? null : _controller.redo,
                      tooltip: 'Redo',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFF87171), size: 20),
                      onPressed: _controller.strokes.isEmpty ? null : _showClearDialog,
                      tooltip: 'Clear all',
                    ),
                    const SizedBox(width: 8),
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
                  CanvasWidget(
                    controller: _controller,
                    canvasKey: _canvasKey,
                  ),

                  // Color picker overlay
                  if (_controller.showColorPicker)
                    Positioned(
                      bottom: 90,
                      left: 16,
                      child: _buildColorPickerPanel(),
                    ),
                    
                  // Brush size preview overlay
                  if (_controller.isDraggingSlider)
                    Center(
                      child: Container(
                        width: _controller.activeTool == DrawingTool.highlighter ? _controller.strokeWidth * 5 :
                               _controller.activeTool == DrawingTool.eraser ? _controller.strokeWidth * 4 :
                               _controller.activeTool == DrawingTool.pencil ? _controller.strokeWidth * 0.7 : _controller.strokeWidth,
                        height: _controller.activeTool == DrawingTool.highlighter ? _controller.strokeWidth * 5 :
                                _controller.activeTool == DrawingTool.eraser ? _controller.strokeWidth * 4 :
                                _controller.activeTool == DrawingTool.pencil ? _controller.strokeWidth * 0.7 : _controller.strokeWidth,
                        decoration: BoxDecoration(
                          color: _controller.activeTool == DrawingTool.eraser 
                              ? Colors.black12 
                              : _controller.activeTool == DrawingTool.highlighter
                                  ? _controller.activeColor.withOpacity(0.4)
                                  : _controller.activeColor,
                          shape: BoxShape.circle,
                          border: _controller.activeTool == DrawingTool.eraser 
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
                  GestureDetector(
                    onTap: () => _controller.showColorPicker = !_controller.showColorPicker,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _controller.activeColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30, width: 2),
                      ),
                    ),
                  ),

                  _toolButton(DrawingTool.pencil, Icons.edit_outlined, 'Pencil'),
                  _toolButton(DrawingTool.pen, Icons.create_rounded, 'Pen'),
                  _toolButton(DrawingTool.highlighter, Icons.highlight_rounded, 'Highlighter'),
                  _toolButton(DrawingTool.eraser, Icons.auto_fix_normal_rounded, 'Eraser'),

                  SizedBox(
                    width: 100,
                    child: Slider(
                      value: _controller.strokeWidth,
                      min: 1.0,
                      max: 20.0,
                      activeColor: const Color(0xFF8B5CF6),
                      inactiveColor: Colors.white12,
                      onChangeStart: (_) => _controller.isDraggingSlider = true,
                      onChangeEnd: (_) => _controller.isDraggingSlider = false,
                      onChanged: (v) => _controller.strokeWidth = v,
                    ),
                  ),

                  IconButton(
                    icon: Icon(
                      _controller.canvasBgColor == Colors.white
                          ? Icons.brightness_2_outlined
                          : Icons.brightness_7_outlined,
                      color: Colors.white70,
                      size: 20,
                    ),
                    tooltip: 'Toggle canvas background',
                    onPressed: () => _controller.canvasBgColor =
                        _controller.canvasBgColor == Colors.white ? const Color(0xFF1E1B2E) : Colors.white,
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
    final isActive = _controller.activeTool == tool;
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: () {
          _controller.activeTool = tool;
        },
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
                final isSelected = _controller.activeColor == c;
                return GestureDetector(
                  onTap: () {
                    _controller.activeColor = c;
                  },
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
              _controller.clearCanvas();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
