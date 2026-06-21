import '../../domain/repositories/pdf_viewer_repository.dart';
import '../datasources/pdf_viewer_local_datasource.dart';
import '../models/pdf_annotation_model.dart';
import '../models/pdf_bookmark_model.dart';

class PdfViewerRepositoryImpl implements PdfViewerRepository {
  final PdfViewerLocalDatasource _datasource;

  const PdfViewerRepositoryImpl(this._datasource);

  @override
  List<PdfAnnotationModel> getAnnotations(String pdfPath) =>
      _datasource.getAnnotations(pdfPath);

  @override
  Future<void> saveAnnotation(PdfAnnotationModel annotation) =>
      _datasource.saveAnnotation(annotation);

  @override
  Future<void> deleteAnnotation(String id) =>
      _datasource.deleteAnnotation(id);

  @override
  List<PdfBookmarkModel> getBookmarks(String pdfPath) =>
      _datasource.getBookmarks(pdfPath);

  @override
  Future<void> saveBookmark(PdfBookmarkModel bookmark) =>
      _datasource.saveBookmark(bookmark);

  @override
  Future<void> deleteBookmark(String id) =>
      _datasource.deleteBookmark(id);
}
