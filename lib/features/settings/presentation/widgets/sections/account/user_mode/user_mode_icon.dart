import 'package:flutter/material.dart';
import '../../../../../../../models/models.dart';

class UserModeIcon {
  static IconData getLayoutIcon(EditorLayoutVariant variant) {
    switch (variant) {
      case EditorLayoutVariant.classic: return Icons.view_agenda_outlined;
      case EditorLayoutVariant.minimal: return Icons.article_outlined;
      case EditorLayoutVariant.notebook: return Icons.menu_book_outlined;
      case EditorLayoutVariant.zen: return Icons.self_improvement_rounded;
      case EditorLayoutVariant.cards: return Icons.style_rounded;
      case EditorLayoutVariant.journal: return Icons.edit_note_rounded;
      case EditorLayoutVariant.scrapbook: return Icons.dashboard_customize_outlined;
      case EditorLayoutVariant.petal: return Icons.local_florist_outlined;
      case EditorLayoutVariant.stardust: return Icons.auto_awesome_rounded;
    }
  }
}
