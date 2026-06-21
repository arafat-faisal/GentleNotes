import '../../../../core/services/storage/i_local_storage.dart';
import '../models/pdf_annotation_model.dart';
import '../models/pdf_bookmark_model.dart';

class PdfViewerLocalDatasource {
  final ILocalStorage _storage;

  const PdfViewerLocalDatasource(this._storage);

  List<PdfAnnotationModel> getAnnotations(String pdfPath) =>
      _storage.getPdfAnnotations(pdfPath);

  Future<void> saveAnnotation(PdfAnnotationModel annotation) =>
      _storage.savePdfAnnotation(annotation);

  Future<void> deleteAnnotation(String id) =>
      _storage.deletePdfAnnotation(id);

  List<PdfBookmarkModel> getBookmarks(String pdfPath) =>
      _storage.getPdfBookmarks(pdfPath);

  Future<void> saveBookmark(PdfBookmarkModel bookmark) =>
      _storage.savePdfBookmark(bookmark);

  Future<void> deleteBookmark(String id) =>
      _storage.deletePdfBookmark(id);
}
