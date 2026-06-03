import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../models/models.dart';
import 'attachment_model.dart';
import 'floating_sticker_model.dart';

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
  final List<FloatingStickerModel> stickers;

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
    this.stickers = const [],
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
    List<FloatingStickerModel>? stickers,
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
      stickers: stickers ?? this.stickers,
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
      'stickers': stickers.map((x) => x.toMap()).toList(),
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

    List<FloatingStickerModel> parsedStickers = [];
    if (map['stickers'] is List) {
      parsedStickers = (map['stickers'] as List)
          .map((x) => FloatingStickerModel.fromMap(Map<String, dynamic>.from(x)))
          .toList();
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
      stickers: parsedStickers,
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
