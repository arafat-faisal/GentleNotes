class PdfBookmarkModel {
  final String id;
  final String pdfPath;
  final int pageNumber;
  final String label; // "Important", "Need Review", "Exam", "Confusing" or a custom one
  final DateTime createdAt;

  PdfBookmarkModel({
    required this.id,
    required this.pdfPath,
    required this.pageNumber,
    required this.label,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pdfPath': pdfPath,
      'pageNumber': pageNumber,
      'label': label,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PdfBookmarkModel.fromMap(Map<String, dynamic> map) {
    return PdfBookmarkModel(
      id: map['id'] ?? '',
      pdfPath: map['pdfPath'] ?? '',
      pageNumber: map['pageNumber'] ?? 1,
      label: map['label'] ?? 'Bookmark',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
