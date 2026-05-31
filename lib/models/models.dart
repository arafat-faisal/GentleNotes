import 'dart:convert';
import 'package:flutter/material.dart';


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

enum LayoutMode {
  grid,
  list,
  compact;
}

enum EditorMode {
  plain,
  markdown;
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

// --- DATA MODELS ---

class UserProfile {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.values.firstWhere((e) => e.name == map['role'], orElse: () => UserRole.guest),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class FolderModel {
  final String id;
  final String name;
  final String? parentFolderId;
  final String colorHex;
  final String iconName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int sortOrder;

  FolderModel({
    required this.id,
    required this.name,
    this.parentFolderId,
    required this.colorHex,
    required this.iconName,
    required this.createdAt,
    required this.updatedAt,
    required this.sortOrder,
  });

  FolderModel copyWith({
    String? name,
    String? parentFolderId,
    String? colorHex,
    String? iconName,
    DateTime? updatedAt,
    int? sortOrder,
  }) {
    return FolderModel(
      id: this.id,
      name: name ?? this.name,
      parentFolderId: parentFolderId ?? this.parentFolderId,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parentFolderId': parentFolderId,
      'colorHex': colorHex,
      'iconName': iconName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sortOrder': sortOrder,
    };
  }

  factory FolderModel.fromMap(Map<String, dynamic> map) {
    return FolderModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      parentFolderId: map['parentFolderId'],
      colorHex: map['colorHex'] ?? '#2196F3',
      iconName: map['iconName'] ?? 'folder',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      sortOrder: map['sortOrder'] ?? 0,
    );
  }

  Color get color {
    final hex = colorHex.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return Colors.blue;
  }
}

class AttachmentModel {
  final String id;
  final String noteId;
  final AttachmentType type;
  final String name;
  final String pathOrUrl;
  final DateTime createdAt;

  AttachmentModel({
    required this.id,
    required this.noteId,
    required this.type,
    required this.name,
    required this.pathOrUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'noteId': noteId,
      'type': type.name,
      'name': name,
      'pathOrUrl': pathOrUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AttachmentModel.fromMap(Map<String, dynamic> map) {
    return AttachmentModel(
      id: map['id'] ?? '',
      noteId: map['noteId'] ?? '',
      type: AttachmentType.values.firstWhere((e) => e.name == map['type'], orElse: () => AttachmentType.file),
      name: map['name'] ?? '',
      pathOrUrl: map['pathOrUrl'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class NoteModel {
  final String id;
  final String? folderId;
  final String title;
  final String content;
  final NoteType noteType;
  final List<String> tags;
  final List<AttachmentModel> attachments;
  final String? templateId;
  final bool isPinned;
  final bool isFavorite;
  final String colorHex;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteModel({
    required this.id,
    this.folderId,
    required this.title,
    required this.content,
    required this.noteType,
    required this.tags,
    required this.attachments,
    this.templateId,
    required this.isPinned,
    required this.isFavorite,
    required this.colorHex,
    required this.createdAt,
    required this.updatedAt,
  });

  String get plainText {
    if (content.startsWith('[') && content.endsWith(']')) {
      try {
        final List parsed = jsonDecode(content);
        final sb = StringBuffer();
        for (final op in parsed) {
          if (op is Map && op.containsKey('insert')) {
            final insert = op['insert'];
            if (insert is String) {
              sb.write(insert);
            }
          }
        }
        return sb.toString();
      } catch (_) {}
    }
    return content;
  }


  NoteModel copyWith({
    String? folderId,
    String? title,
    String? content,
    NoteType? noteType,
    List<String>? tags,
    List<AttachmentModel>? attachments,
    String? templateId,
    bool? isPinned,
    bool? isFavorite,
    String? colorHex,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: this.id,
      folderId: folderId ?? this.folderId,
      title: title ?? this.title,
      content: content ?? this.content,
      noteType: noteType ?? this.noteType,
      tags: tags ?? this.tags,
      attachments: attachments ?? this.attachments,
      templateId: templateId ?? this.templateId,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      colorHex: colorHex ?? this.colorHex,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'folderId': folderId,
      'title': title,
      'content': content,
      'noteType': noteType.name,
      'tags': tags,
      'attachments': attachments.map((x) => x.toMap()).toList(),
      'templateId': templateId,
      'isPinned': isPinned ? 1 : 0,
      'isFavorite': isFavorite ? 1 : 0,
      'colorHex': colorHex,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    var rawAttachments = map['attachments'];
    List<AttachmentModel> parsedAttachments = [];
    if (rawAttachments is List) {
      parsedAttachments = rawAttachments.map((x) => AttachmentModel.fromMap(Map<String, dynamic>.from(x))).toList();
    }

    List<String> parsedTags = [];
    if (map['tags'] is List) {
      parsedTags = List<String>.from(map['tags']);
    }

    return NoteModel(
      id: map['id'] ?? '',
      folderId: map['folderId'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      noteType: NoteType.values.firstWhere((e) => e.name == map['noteType'], orElse: () => NoteType.text),
      tags: parsedTags,
      attachments: parsedAttachments,
      templateId: map['templateId'],
      isPinned: (map['isPinned'] == 1 || map['isPinned'] == true),
      isFavorite: (map['isFavorite'] == 1 || map['isFavorite'] == true),
      colorHex: map['colorHex'] ?? '#FFFFFF',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Color get color {
    final hex = colorHex.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return Colors.white;
  }
}

class NoteTemplateModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String defaultTitle;
  final String defaultContent;
  final List<String> defaultTags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isBuiltIn;

  NoteTemplateModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.defaultTitle,
    required this.defaultContent,
    required this.defaultTags,
    required this.createdAt,
    required this.updatedAt,
    this.isBuiltIn = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'defaultTitle': defaultTitle,
      'defaultContent': defaultContent,
      'defaultTags': defaultTags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isBuiltIn': isBuiltIn ? 1 : 0,
    };
  }

  factory NoteTemplateModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedTags = [];
    if (map['defaultTags'] is List) {
      parsedTags = List<String>.from(map['defaultTags']);
    }

    return NoteTemplateModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'General',
      defaultTitle: map['defaultTitle'] ?? '',
      defaultContent: map['defaultContent'] ?? '',
      defaultTags: parsedTags,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      isBuiltIn: (map['isBuiltIn'] == 1 || map['isBuiltIn'] == true),
    );
  }
}

class AppSettingsModel {
  final ThemeModeSetting themeMode;
  final String accentColorHex;
  final LayoutMode layoutMode;
  final EditorMode editorMode;
  final NoteType defaultNoteType;
  final bool autoSaveEnabled;
  final String activeCodeTheme;
  final EditorLayoutVariant editorLayout;
  final AppThemePreset themePreset;

  AppSettingsModel({
    required this.themeMode,
    required this.accentColorHex,
    required this.layoutMode,
    required this.editorMode,
    required this.defaultNoteType,
    required this.autoSaveEnabled,
    required this.activeCodeTheme,
    this.editorLayout = EditorLayoutVariant.classic,
    this.themePreset = AppThemePreset.none,
  });

  AppSettingsModel copyWith({
    ThemeModeSetting? themeMode,
    String? accentColorHex,
    LayoutMode? layoutMode,
    EditorMode? editorMode,
    NoteType? defaultNoteType,
    bool? autoSaveEnabled,
    String? activeCodeTheme,
    EditorLayoutVariant? editorLayout,
    AppThemePreset? themePreset,
  }) {
    return AppSettingsModel(
      themeMode: themeMode ?? this.themeMode,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      layoutMode: layoutMode ?? this.layoutMode,
      editorMode: editorMode ?? this.editorMode,
      defaultNoteType: defaultNoteType ?? this.defaultNoteType,
      autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
      activeCodeTheme: activeCodeTheme ?? this.activeCodeTheme,
      editorLayout: editorLayout ?? this.editorLayout,
      themePreset: themePreset ?? this.themePreset,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode.name,
      'accentColorHex': accentColorHex,
      'layoutMode': layoutMode.name,
      'editorMode': editorMode.name,
      'defaultNoteType': defaultNoteType.name,
      'autoSaveEnabled': autoSaveEnabled ? 1 : 0,
      'activeCodeTheme': activeCodeTheme,
      'editorLayout': editorLayout.name,
      'themePreset': themePreset.name,
    };
  }

  factory AppSettingsModel.fromMap(Map<String, dynamic> map) {
    return AppSettingsModel(
      themeMode: ThemeModeSetting.values.firstWhere((e) => e.name == map['themeMode'], orElse: () => ThemeModeSetting.system),
      accentColorHex: map['accentColorHex'] ?? '#6366F1',
      layoutMode: LayoutMode.values.firstWhere((e) => e.name == map['layoutMode'], orElse: () => LayoutMode.grid),
      editorMode: EditorMode.values.firstWhere((e) => e.name == map['editorMode'], orElse: () => EditorMode.markdown),
      defaultNoteType: NoteType.values.firstWhere((e) => e.name == map['defaultNoteType'], orElse: () => NoteType.markdown),
      autoSaveEnabled: (map['autoSaveEnabled'] == 1 || map['autoSaveEnabled'] == true || map['autoSaveEnabled'] == null),
      activeCodeTheme: map['activeCodeTheme'] ?? 'vs-dark',
      editorLayout: EditorLayoutVariant.values.firstWhere(
        (e) => e.name == map['editorLayout'],
        orElse: () => EditorLayoutVariant.classic,
      ),
      themePreset: AppThemePreset.values.firstWhere(
        (e) => e.name == map['themePreset'],
        orElse: () => AppThemePreset.none,
      ),
    );
  }

  Color get accentColor {
    final hex = accentColorHex.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return const Color(0xFF6366F1);
  }
}
