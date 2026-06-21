import 'package:hive_flutter/hive_flutter.dart';
import '../../../features/pdf_viewer/data/models/pdf_annotation_model.dart';
import '../../../features/pdf_viewer/data/models/pdf_bookmark_model.dart';

class PdfAnnotationStorage {
  final Box annotationsBox;
  final Box bookmarksBox;

  PdfAnnotationStorage({
    required this.annotationsBox,
    required this.bookmarksBox,
  });

  List<PdfAnnotationModel> getPdfAnnotations(String pdfPath) {
    final List<PdfAnnotationModel> list = [];
    for (var key in annotationsBox.keys) {
      final val = annotationsBox.get(key);
      if (val is Map) {
        final ann = PdfAnnotationModel.fromMap(Map<String, dynamic>.from(val));
        if (ann.pdfPath == pdfPath) {
          list.add(ann);
        }
      }
    }
    // Newest annotations first
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> savePdfAnnotation(PdfAnnotationModel annotation) async {
    await annotationsBox.put(annotation.id, annotation.toMap());
  }

  Future<void> deletePdfAnnotation(String id) async {
    await annotationsBox.delete(id);
  }

  List<PdfBookmarkModel> getPdfBookmarks(String pdfPath) {
    final List<PdfBookmarkModel> list = [];
    for (var key in bookmarksBox.keys) {
      final val = bookmarksBox.get(key);
      if (val is Map) {
        final bmk = PdfBookmarkModel.fromMap(Map<String, dynamic>.from(val));
        if (bmk.pdfPath == pdfPath) {
          list.add(bmk);
        }
      }
    }
    // Sort by page number ascending
    list.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
    return list;
  }

  Future<void> savePdfBookmark(PdfBookmarkModel bookmark) async {
    await bookmarksBox.put(bookmark.id, bookmark.toMap());
  }

  Future<void> deletePdfBookmark(String id) async {
    await bookmarksBox.delete(id);
  }
}
