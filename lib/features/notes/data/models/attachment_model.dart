import '../../../../models/models.dart';

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
