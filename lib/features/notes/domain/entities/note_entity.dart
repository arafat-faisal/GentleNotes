/// Pure domain entity for a Note.
///
/// This entity is intentionally free of Flutter, Hive, or JSON dependencies.
/// It represents the core business concept of a note as understood by the
/// domain layer — independent of how it is stored or displayed.
///
/// The [NoteModel] in the data layer maps to/from this entity when crossing
/// layer boundaries. The presentation layer receives [NoteEntity] objects
/// from use cases, not raw [NoteModel] objects.
///
/// Extension points:
/// - Add [aiSummary] field when AI summarization is enabled.
/// - Add [syncStatus] field when cloud sync is implemented.
library;

/// Represents the type/format of a note's content.
enum NoteContentType {
  text,
  markdown,
  checklist,
  link,
  image,
  code,
  mixed,
}

/// Represents an attachment linked to a note.
class NoteAttachment {
  const NoteAttachment({
    required this.id,
    required this.noteId,
    required this.type,
    required this.name,
    required this.pathOrUrl,
    required this.createdAt,
  });

  final String id;
  final String noteId;

  /// Type of attachment: 'image', 'audio', 'file', 'link'
  final String type;
  final String name;
  final String pathOrUrl;
  final DateTime createdAt;

  @override
  String toString() => 'NoteAttachment(id: $id, type: $type, name: $name)';
}

/// Core domain entity representing a single note.
class NoteEntity {
  const NoteEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.contentType,
    required this.tags,
    required this.attachments,
    required this.isPinned,
    required this.isFavorite,
    required this.colorHex,
    required this.createdAt,
    required this.updatedAt,
    this.folderId,
    this.templateId,
    // Extension point: AI features (null until AI module is active)
    this.aiSummary,
    // Extension point: Cloud sync status (null until sync is active)
    this.syncStatus,
  });

  final String id;
  final String title;
  final String content;
  final NoteContentType contentType;
  final List<String> tags;
  final List<NoteAttachment> attachments;
  final bool isPinned;
  final bool isFavorite;
  final String colorHex;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// ID of the folder this note belongs to. Null means it's in the root.
  final String? folderId;

  /// ID of the template this note was created from. Null if no template used.
  final String? templateId;

  // ── Future Extension Points ──────────────────────────────────────────────────

  /// AI-generated summary of the note content.
  /// Populated when the AI summarization feature is enabled.
  final String? aiSummary;

  /// Cloud synchronization status: 'synced', 'pending', 'conflict', etc.
  /// Populated when cloud sync is enabled.
  final String? syncStatus;

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Returns true if this note has any attachments.
  bool get hasAttachments => attachments.isNotEmpty;

  /// Returns true if this note has any tags.
  bool get hasTags => tags.isNotEmpty;

  /// Returns a truncated preview of the content (first 150 chars, no markdown).
  String get contentPreview {
    final cleaned = content
        .replaceAll(RegExp(r'#{1,6}\s'), '')
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'_+'), '')
        .replaceAll(RegExp(r'`+'), '')
        .trim();
    return cleaned.length > 150 ? '${cleaned.substring(0, 150)}…' : cleaned;
  }

  NoteEntity copyWith({
    String? title,
    String? content,
    NoteContentType? contentType,
    List<String>? tags,
    List<NoteAttachment>? attachments,
    bool? isPinned,
    bool? isFavorite,
    String? colorHex,
    DateTime? updatedAt,
    String? folderId,
    String? templateId,
    String? aiSummary,
    String? syncStatus,
  }) {
    return NoteEntity(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      contentType: contentType ?? this.contentType,
      tags: tags ?? this.tags,
      attachments: attachments ?? this.attachments,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      folderId: folderId ?? this.folderId,
      templateId: templateId ?? this.templateId,
      aiSummary: aiSummary ?? this.aiSummary,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  String toString() => 'NoteEntity(id: $id, title: $title, type: $contentType)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteEntity && runtimeType == other.runtimeType && id == other.id);

  @override
  int get hashCode => id.hashCode;
}
