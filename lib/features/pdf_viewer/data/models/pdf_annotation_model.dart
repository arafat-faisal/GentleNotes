class PdfAnnotationModel {
  final String id;
  final String pdfPath;
  final int pageNumber;
  final String type; // 'highlight', 'underline', 'strikethrough', 'squiggly', 'note', 'flashcard', 'snapshot'
  final String colorHex;
  final String? selectedText;
  final String? noteText;
  final String? flashcardQuestion;
  final String? flashcardAnswer;
  final String? snapshotPath;
  final String? rectsJson; // JSON representation of text bounds / coordinate rects
  final DateTime createdAt;

  PdfAnnotationModel({
    required this.id,
    required this.pdfPath,
    required this.pageNumber,
    required this.type,
    required this.colorHex,
    this.selectedText,
    this.noteText,
    this.flashcardQuestion,
    this.flashcardAnswer,
    this.snapshotPath,
    this.rectsJson,
    required this.createdAt,
  });

  PdfAnnotationModel copyWith({
    String? type,
    String? colorHex,
    String? selectedText,
    String? noteText,
    String? flashcardQuestion,
    String? flashcardAnswer,
    String? snapshotPath,
    String? rectsJson,
  }) {
    return PdfAnnotationModel(
      id: id,
      pdfPath: pdfPath,
      pageNumber: pageNumber,
      type: type ?? this.type,
      colorHex: colorHex ?? this.colorHex,
      selectedText: selectedText ?? this.selectedText,
      noteText: noteText ?? this.noteText,
      flashcardQuestion: flashcardQuestion ?? this.flashcardQuestion,
      flashcardAnswer: flashcardAnswer ?? this.flashcardAnswer,
      snapshotPath: snapshotPath ?? this.snapshotPath,
      rectsJson: rectsJson ?? this.rectsJson,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pdfPath': pdfPath,
      'pageNumber': pageNumber,
      'type': type,
      'colorHex': colorHex,
      'selectedText': selectedText,
      'noteText': noteText,
      'flashcardQuestion': flashcardQuestion,
      'flashcardAnswer': flashcardAnswer,
      'snapshotPath': snapshotPath,
      'rectsJson': rectsJson,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PdfAnnotationModel.fromMap(Map<String, dynamic> map) {
    return PdfAnnotationModel(
      id: map['id'] ?? '',
      pdfPath: map['pdfPath'] ?? '',
      pageNumber: map['pageNumber'] ?? 1,
      type: map['type'] ?? 'highlight',
      colorHex: map['colorHex'] ?? '#FFEB3B',
      selectedText: map['selectedText'],
      noteText: map['noteText'],
      flashcardQuestion: map['flashcardQuestion'],
      flashcardAnswer: map['flashcardAnswer'],
      snapshotPath: map['snapshotPath'],
      rectsJson: map['rectsJson'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
