import '../../data/models/pdf_annotation_model.dart';
import '../../data/models/pdf_bookmark_model.dart';

abstract class PdfViewerRepository {
  List<PdfAnnotationModel> getAnnotations(String pdfPath);
  Future<void> saveAnnotation(PdfAnnotationModel annotation);
  Future<void> deleteAnnotation(String id);

  List<PdfBookmarkModel> getBookmarks(String pdfPath);
  Future<void> saveBookmark(PdfBookmarkModel bookmark);
  Future<void> deleteBookmark(String id);
}
