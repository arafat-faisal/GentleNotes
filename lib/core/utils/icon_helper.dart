import 'package:flutter/material.dart';

class IconHelper {
  static const Map<String, IconData> _icons = {
    'folder': Icons.folder,
    'psychology_outlined': Icons.psychology_outlined,
    'lightbulb_outline': Icons.lightbulb_outline,
    'science_outlined': Icons.science_outlined,
    'work_outline': Icons.work_outline,
    'book_outlined': Icons.book_outlined,
    'trending_up': Icons.trending_up,
    'school': Icons.school_outlined,
    'code': Icons.code_outlined,
    'star': Icons.star_border,
    'favorite': Icons.favorite_border,
    'person': Icons.person_outline,
    'cloud_queue': Icons.cloud_queue,
    'terminal': Icons.terminal,
    'description': Icons.description_outlined,
  };

  static IconData getIcon(String name) {
    return _icons[name] ?? Icons.folder;
  }

  static List<String> getAvailableIconNames() {
    return _icons.keys.toList();
  }

  static List<IconData> getAvailableIcons() {
    return _icons.values.toList();
  }
}
