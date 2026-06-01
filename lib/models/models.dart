import 'package:flutter/material.dart';

// Backwards compatibility exports for split models
export '../features/folders/data/models/folder_model.dart';
export '../features/notes/data/models/attachment_model.dart';
export '../features/notes/data/models/note_model.dart';
export '../features/templates/data/models/note_template_model.dart';
export '../features/settings/data/models/app_settings_model.dart';
export '../features/settings/data/models/user_profile.dart';
export '../features/settings/data/models/custom_workspace_profile.dart';

// --- ENUMS ---


enum UserRole {
  admin,
  subscriber,
  freeUser,
  guest;

  String get displayName {
    switch (this) {
      case UserRole.admin: return 'Admin';
      case UserRole.subscriber: return 'Subscriber';
      case UserRole.freeUser: return 'Free User';
      case UserRole.guest: return 'Guest';
    }
  }
}

enum NoteType {
  text,
  markdown,
  checklist,
  link,
  image,
  code,
  mixed;

  String get displayName {
    switch (this) {
      case NoteType.text: return 'Plain Text';
      case NoteType.markdown: return 'Markdown Document';
      case NoteType.checklist: return 'Checklist';
      case NoteType.link: return 'Resource Link';
      case NoteType.image: return 'Visual Image';
      case NoteType.code: return 'Code Snippet';
      case NoteType.mixed: return 'GentleNote (Block Editor)';
    }
  }

  IconData get icon {
    switch (this) {
      case NoteType.text: return Icons.notes;
      case NoteType.markdown: return Icons.article_outlined;
      case NoteType.checklist: return Icons.check_box_outlined;
      case NoteType.link: return Icons.link;
      case NoteType.image: return Icons.image_outlined;
      case NoteType.code: return Icons.code_rounded;
      case NoteType.mixed: return Icons.dashboard_customize_outlined;
    }
  }
}

enum ThemeModeSetting {
  light,
  dark,
  system;

  ThemeMode get toThemeMode {
    switch (this) {
      case ThemeModeSetting.light: return ThemeMode.light;
      case ThemeModeSetting.dark: return ThemeMode.dark;
      case ThemeModeSetting.system: return ThemeMode.system;
    }
  }
}

enum AppUserMode {
  normal,
  coder,
  student,
  researcher,
  custom;

  String get displayName {
    switch (this) {
      case AppUserMode.normal: return 'Standard / Full';
      case AppUserMode.coder: return 'Developer / Coder';
      case AppUserMode.student: return 'Academic / Student';
      case AppUserMode.researcher: return 'Researcher';
      case AppUserMode.custom: return 'Custom Profile';
    }
  }

  String get description {
    switch (this) {
      case AppUserMode.normal: return 'Full experience with all layouts, themes, and tools.';
      case AppUserMode.coder: return 'Focused on coding and technical docs. Classic/Notebook layouts, developer dark themes, and code tools.';
      case AppUserMode.student: return 'Tailored for lecture notes, checklist tasks, and drawing. Pastel themes and student tools.';
      case AppUserMode.researcher: return 'Optimized for distraction-free writing, tagging, and logging. Minimal/Zen layouts, clean themes, and research tools.';
      case AppUserMode.custom: return 'Build your own profile: select specific layouts, themes, and formatting options.';
    }
  }

  IconData get icon {
    switch (this) {
      case AppUserMode.normal: return Icons.dashboard_outlined;
      case AppUserMode.coder: return Icons.code_rounded;
      case AppUserMode.student: return Icons.school_outlined;
      case AppUserMode.researcher: return Icons.biotech_outlined;
      case AppUserMode.custom: return Icons.settings_suggest_outlined;
    }
  }
}

enum LayoutMode {
  grid,
  list,
  compact;
}

enum EditorMode {
  gentleNote,
  blockEditor;

  String get displayName {
    switch (this) {
      case EditorMode.gentleNote:
        return 'GentleNote (Quill)';
      case EditorMode.blockEditor:
        return 'Block Editor';
    }
  }
}

/// Controls which visual layout variant is used in the note editor.
enum EditorLayoutVariant {
  /// The original layout — title in AppBar, dropdowns bar at top, tags at bottom.
  classic,
  /// Clean layout — large inline title, minimal chrome, floating toolbar.
  minimal,
  /// Two-panel layout — left metadata sidebar + right writing column.
  notebook,
  /// Distraction-free full-bleed layout — chrome fades in on interaction.
  zen,
  /// Card-style layout — colored cover card header, editor below.
  cards,
  /// Diary-style layout — lined notebook background, date header, serif title.
  journal,
  /// Scrapbook layout — colorful sticky-note metadata panels.
  scrapbook,
  /// Floral petal layout — soft curved gradient header, rounded chrome.
  petal,
  /// Dreamy dark gradient layout with sparkle accents.
  stardust;

  String get displayName {
    switch (this) {
      case EditorLayoutVariant.classic:   return 'Classic';
      case EditorLayoutVariant.minimal:   return 'Minimal';
      case EditorLayoutVariant.notebook:  return 'Notebook';
      case EditorLayoutVariant.zen:       return 'Zen';
      case EditorLayoutVariant.cards:     return 'Cards';
      case EditorLayoutVariant.journal:   return 'Journal';
      case EditorLayoutVariant.scrapbook: return 'Scrapbook';
      case EditorLayoutVariant.petal:     return 'Petal';
      case EditorLayoutVariant.stardust:  return 'Stardust';
    }
  }

  String get description {
    switch (this) {
      case EditorLayoutVariant.classic:   return 'Original layout with AppBar title and bottom tags bar';
      case EditorLayoutVariant.minimal:   return 'Clean look with large inline title and minimal chrome';
      case EditorLayoutVariant.notebook:  return 'Left metadata sidebar with writing panel on right';
      case EditorLayoutVariant.zen:       return 'Distraction-free full-bleed editor, chrome on tap';
      case EditorLayoutVariant.cards:     return 'Color card header with editor content below';
      case EditorLayoutVariant.journal:   return 'Lined diary paper, serif font, date stamp header';
      case EditorLayoutVariant.scrapbook: return 'Colorful sticky-note panels for metadata';
      case EditorLayoutVariant.petal:     return 'Curved floral gradient header with soft accents';
      case EditorLayoutVariant.stardust:  return 'Dark dreamy gradient with sparkle decorations';
    }
  }

  /// Whether this is one of the feminine/aesthetic variants.
  bool get isAesthetic => [
    EditorLayoutVariant.journal,
    EditorLayoutVariant.scrapbook,
    EditorLayoutVariant.petal,
    EditorLayoutVariant.stardust,
  ].contains(this);
}

/// Full-app aesthetic theme presets.
enum AppThemePreset {
  none,
  floralRose,
  cookiesCream,
  sakura,
  lavenderDream,
  oceanBreeze,
  midnightStars,
  cottagecore,
  candyPop,
  matchaLatte,
  cloudPastel;

  String get displayName {
    switch (this) {
      case AppThemePreset.none:          return 'Default';
      case AppThemePreset.floralRose:    return 'Floral Rose';
      case AppThemePreset.cookiesCream:  return 'Cookies & Cream';
      case AppThemePreset.sakura:        return 'Sakura';
      case AppThemePreset.lavenderDream: return 'Lavender Dream';
      case AppThemePreset.oceanBreeze:   return 'Ocean Breeze';
      case AppThemePreset.midnightStars: return 'Midnight Stars';
      case AppThemePreset.cottagecore:   return 'Cottagecore';
      case AppThemePreset.candyPop:      return 'Candy Pop';
      case AppThemePreset.matchaLatte:   return 'Matcha Latte';
      case AppThemePreset.cloudPastel:   return 'Cloud Pastel';
    }
  }

  String get emoji {
    switch (this) {
      case AppThemePreset.none:          return '✨';
      case AppThemePreset.floralRose:    return '🌸';
      case AppThemePreset.cookiesCream:  return '🍪';
      case AppThemePreset.sakura:        return '🌺';
      case AppThemePreset.lavenderDream: return '💜';
      case AppThemePreset.oceanBreeze:   return '🌊';
      case AppThemePreset.midnightStars: return '🌙';
      case AppThemePreset.cottagecore:   return '🌿';
      case AppThemePreset.candyPop:      return '🍬';
      case AppThemePreset.matchaLatte:   return '🍵';
      case AppThemePreset.cloudPastel:   return '☁️';
    }
  }

  /// Preview swatch colors (for the settings picker card).
  List<Color> get swatchColors {
    switch (this) {
      case AppThemePreset.none:
        return [Color(0xFF6366F1), Color(0xFFF5F3FF), Color(0xFF090B16)];
      case AppThemePreset.floralRose:
        return [Color(0xFFE91E63), Color(0xFFFFF0F3), Color(0xFFFF6B9D)];
      case AppThemePreset.cookiesCream:
        return [Color(0xFF8B5E3C), Color(0xFFFFF8F0), Color(0xFFD4956A)];
      case AppThemePreset.sakura:
        return [Color(0xFFF06292), Color(0xFFFFF5F8), Color(0xFFF8BBD0)];
      case AppThemePreset.lavenderDream:
        return [Color(0xFF9C27B0), Color(0xFFF8F0FF), Color(0xFFCE93D8)];
      case AppThemePreset.oceanBreeze:
        return [Color(0xFF0288D1), Color(0xFFF0F8FF), Color(0xFF81D4FA)];
      case AppThemePreset.midnightStars:
        return [Color(0xFF9FA8DA), Color(0xFF05050F), Color(0xFF3F51B5)];
      case AppThemePreset.cottagecore:
        return [Color(0xFF558B2F), Color(0xFFF4FAF0), Color(0xFF8BC34A)];
      case AppThemePreset.candyPop:
        return [Color(0xFFE91E8C), Color(0xFFFFF0FB), Color(0xFFFF80CE)];
      case AppThemePreset.matchaLatte:
        return [Color(0xFF689F38), Color(0xFFF5F8F0), Color(0xFFA5C461)];
      case AppThemePreset.cloudPastel:
        return [Color(0xFF5C85D6), Color(0xFFF0F8FF), Color(0xFFB3C6F0)];
    }
  }
}

enum AttachmentType {
  image,
  file,
  link,
  audio;
}


