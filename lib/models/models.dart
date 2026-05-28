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

  AppSettingsModel({
    required this.themeMode,
    required this.accentColorHex,
    required this.layoutMode,
    required this.editorMode,
    required this.defaultNoteType,
    required this.autoSaveEnabled,
    required this.activeCodeTheme,
  });

  AppSettingsModel copyWith({
    ThemeModeSetting? themeMode,
    String? accentColorHex,
    LayoutMode? layoutMode,
    EditorMode? editorMode,
    NoteType? defaultNoteType,
    bool? autoSaveEnabled,
    String? activeCodeTheme,
  }) {
    return AppSettingsModel(
      themeMode: themeMode ?? this.themeMode,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      layoutMode: layoutMode ?? this.layoutMode,
      editorMode: editorMode ?? this.editorMode,
      defaultNoteType: defaultNoteType ?? this.defaultNoteType,
      autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
      activeCodeTheme: activeCodeTheme ?? this.activeCodeTheme,
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
    };
  }

  factory AppSettingsModel.fromMap(Map<String, dynamic> map) {
    return AppSettingsModel(
      themeMode: ThemeModeSetting.values.firstWhere((e) => e.name == map['themeMode'], orElse: () => ThemeModeSetting.system),
      accentColorHex: map['accentColorHex'] ?? '#6366F1', // soft Indigo
      layoutMode: LayoutMode.values.firstWhere((e) => e.name == map['layoutMode'], orElse: () => LayoutMode.grid),
      editorMode: EditorMode.values.firstWhere((e) => e.name == map['editorMode'], orElse: () => EditorMode.markdown),
      defaultNoteType: NoteType.values.firstWhere((e) => e.name == map['defaultNoteType'], orElse: () => NoteType.markdown),
      autoSaveEnabled: (map['autoSaveEnabled'] == 1 || map['autoSaveEnabled'] == true || map['autoSaveEnabled'] == null),
      activeCodeTheme: map['activeCodeTheme'] ?? 'vs-dark',
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
