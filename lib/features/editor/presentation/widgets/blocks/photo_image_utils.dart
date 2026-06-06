import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Builds a [Widget] that displays an image from any of the supported
/// path formats used in GentleNotes:
///
/// - `data:image/...;base64,...`  — inline base-64 encoded image
/// - `file:///path/to/file`       — local file URI (mobile/desktop)
/// - `http://` / `https://`       — remote URL
/// - bare file path               — fallback for raw paths without scheme
Widget buildRawImage(String path, {BoxFit fit = BoxFit.cover}) {
  if (path.startsWith('data:image')) {
    final base64Str = path.split(',').last;
    try {
      return Image.memory(
        base64Decode(base64Str),
        fit: fit,
        errorBuilder: _errorBuilder,
      );
    } catch (_) {
      return const Icon(Icons.broken_image, size: 40, color: Colors.grey);
    }
  }

  if (kIsWeb) {
    return Image.network(
      path,
      fit: fit,
      errorBuilder: _errorBuilder,
    );
  }

  if (path.startsWith('file://')) {
    return Image.file(
      io.File(path.replaceFirst('file://', '')),
      fit: fit,
      errorBuilder: _errorBuilder,
    );
  }

  if (path.startsWith('http://') || path.startsWith('https://')) {
    return Image.network(
      path,
      fit: fit,
      errorBuilder: _errorBuilder,
    );
  }

  // Bare file path fallback
  return Image.file(
    io.File(path),
    fit: fit,
    errorBuilder: _errorBuilder,
  );
}

Widget _errorBuilder(BuildContext context, Object error, StackTrace? stack) =>
    const Icon(Icons.broken_image, size: 40, color: Colors.grey);
