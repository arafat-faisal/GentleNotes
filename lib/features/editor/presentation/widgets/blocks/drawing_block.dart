import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/block_entity.dart';
import 'drawing_canvas_screen.dart';

class DrawingBlock extends StatelessWidget {
  final BlockEntity block;
  final ValueChanged<String> onSaved;
  final VoidCallback onRemoved;
  final bool readOnly;

  const DrawingBlock({
    super.key,
    required this.block,
    required this.onSaved,
    required this.onRemoved,
    this.readOnly = false,
  });

  Future<void> _openCanvas(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => DrawingCanvasScreen(
          onSave: (strokes, pngBytes) async {
            if (pngBytes != null) {
              if (kIsWeb) {
                final base64String = base64Encode(pngBytes);
                onSaved('data:image/png;base64,$base64String');
                return;
              }
              final dir = await getApplicationDocumentsDirectory();
              final fileName = 'drawing_${const Uuid().v4()}.png';
              final file = File('${dir.path}/$fileName');
              await file.writeAsBytes(pngBytes);
              onSaved('file://${file.path}');
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drawingPath = block.content;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (drawingPath.isEmpty) {
      // Return a placeholder to create a drawing
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: InkWell(
          onTap: readOnly ? null : () => _openCanvas(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF2E2A45) : const Color(0xFFE3DCF5),
                style: BorderStyle.solid,
                width: 1.5,
              ),
              color: isDark ? const Color(0xFF1E1A30).withOpacity(0.4) : const Color(0xFFF3F0FA),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.draw_outlined,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  readOnly ? 'No drawing' : 'Tap to start drawing',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget imageWidget;
    if (drawingPath.startsWith('data:image')) {
      final base64Str = drawingPath.split(',').last;
      try {
        imageWidget = Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.contain,
        );
      } catch (e) {
        imageWidget = const _BrokenDrawingPlaceholder();
      }
    } else if (kIsWeb) {
      imageWidget = Image.network(
        drawingPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const _BrokenDrawingPlaceholder(),
      );
    } else if (drawingPath.startsWith('file://')) {
      final path = drawingPath.replaceFirst('file://', '');
      imageWidget = Image.file(
        File(path),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const _BrokenDrawingPlaceholder(),
      );
    } else {
      imageWidget = Image.file(
        File(drawingPath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const _BrokenDrawingPlaceholder(),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF252234) : const Color(0xFFE9E6F5),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              Container(
                color: Colors.white, // Draw canvas is white by default
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(maxHeight: 250),
                width: double.infinity,
                child: Center(child: imageWidget),
              ),
              // Hover action overlay
              if (!readOnly)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _openCanvas(context),
                          child: const Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: onRemoved,
                          child: const Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrokenDrawingPlaceholder extends StatelessWidget {
  const _BrokenDrawingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      color: Colors.grey.withOpacity(0.1),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'Unable to load drawing',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
