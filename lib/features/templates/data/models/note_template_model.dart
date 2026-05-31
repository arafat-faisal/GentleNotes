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
