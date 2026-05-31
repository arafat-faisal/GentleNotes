import 'package:flutter/material.dart';

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

class DrawingController extends ChangeNotifier {
  List<DrawingStroke> _strokes = [];
  List<DrawingStroke> _undoStack = [];
  DrawingStroke? _currentStroke;

  DrawingTool _activeTool = DrawingTool.pen;
  Color _activeColor = Colors.black;
  double _strokeWidth = 3.0;
  Color _canvasBgColor = Colors.white;
  bool _showColorPicker = false;
  bool _isDraggingSlider = false;

  DrawingController({List<DrawingStroke>? initialStrokes}) {
    if (initialStrokes != null) {
      _strokes = List.from(initialStrokes);
    }
  }

  List<DrawingStroke> get strokes => _strokes;
  List<DrawingStroke> get undoStack => _undoStack;
  DrawingStroke? get currentStroke => _currentStroke;

  DrawingTool get activeTool => _activeTool;
  set activeTool(DrawingTool tool) {
    _activeTool = tool;
    _showColorPicker = false;
    notifyListeners();
  }

  Color get activeColor => _activeColor;
  set activeColor(Color color) {
    _activeColor = color;
    _showColorPicker = false;
    notifyListeners();
  }

  double get strokeWidth => _strokeWidth;
  set strokeWidth(double width) {
    _strokeWidth = width;
    notifyListeners();
  }

  Color get canvasBgColor => _canvasBgColor;
  set canvasBgColor(Color color) {
    _canvasBgColor = color;
    notifyListeners();
  }

  bool get showColorPicker => _showColorPicker;
  set showColorPicker(bool show) {
    _showColorPicker = show;
    notifyListeners();
  }

  bool get isDraggingSlider => _isDraggingSlider;
  set isDraggingSlider(bool dragging) {
    _isDraggingSlider = dragging;
    notifyListeners();
  }

  void startStroke(Offset position) {
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
    notifyListeners();
  }

  void addPoint(Offset position) {
    if (_currentStroke == null) return;
    _currentStroke!.points.add(position);
    notifyListeners();
  }

  void endStroke() {
    if (_currentStroke != null && _currentStroke!.points.length > 1) {
      _strokes.add(_currentStroke!);
      _undoStack.clear();
      _currentStroke = null;
    } else {
      _currentStroke = null;
    }
    notifyListeners();
  }

  void undo() {
    if (_strokes.isNotEmpty) {
      _undoStack.add(_strokes.removeLast());
      notifyListeners();
    }
  }

  void redo() {
    if (_undoStack.isNotEmpty) {
      _strokes.add(_undoStack.removeLast());
      notifyListeners();
    }
  }

  void clearCanvas() {
    _strokes.clear();
    _undoStack.clear();
    _currentStroke = null;
    notifyListeners();
  }
}
