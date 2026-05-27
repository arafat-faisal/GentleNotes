/// String extension methods used throughout the app.
///
/// Import once where needed — avoids repeated utility functions in screens.
library string_extensions;

extension StringExtensions on String {
  /// Truncates the string to [maxLength] characters, appending [ellipsis].
  String truncate(int maxLength, {String ellipsis = '…'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }

  /// Capitalizes the first letter of the string.
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Strips Markdown syntax from the string, returning plain text.
  String stripMarkdown() {
    return replaceAll(RegExp(r'#{1,6}\s'), '')
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'_+'), '')
        .replaceAll(RegExp(r'`+'), '')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1')
        .replaceAll(RegExp(r'\n+'), ' ')
        .trim();
  }

  /// Returns true if the string is a valid hex color (e.g., '#FFFFFF').
  bool get isValidHexColor {
    return RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(this);
  }

  /// Converts a 6-char hex color string to a Dart [Color]-compatible int.
  int toColorInt() {
    final hex = replaceAll('#', '');
    if (hex.length == 6) return int.parse('FF$hex', radix: 16);
    return 0xFFFFFFFF;
  }
}
