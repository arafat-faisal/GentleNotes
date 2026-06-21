import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/storage/hive_local_storage.dart';
import '../../data/datasources/pdf_viewer_local_datasource.dart';
import '../../data/repositories/pdf_viewer_repository_impl.dart';
import '../../domain/repositories/pdf_viewer_repository.dart';
import '../../data/models/pdf_annotation_model.dart';
import '../../data/models/pdf_bookmark_model.dart';

class PdfWorkspaceState {
  final List<PdfAnnotationModel> annotations;
  final List<PdfBookmarkModel> bookmarks;
  final bool isNightMode;
  final double zoomLevel;
  final int currentPage;
  final int totalPages;
  final bool isSearchActive;
  final String searchQuery;
  final String activeColorFilter; // 'all' or color categories: 'Concept', 'Question', 'Definition', etc.
  final bool isPanelOpen;

  PdfWorkspaceState({
    this.annotations = const [],
    this.bookmarks = const [],
    this.isNightMode = false,
    this.zoomLevel = 1.0,
    this.currentPage = 1,
    this.totalPages = 0,
    this.isSearchActive = false,
    this.searchQuery = '',
    this.activeColorFilter = 'all',
    this.isPanelOpen = false,
  });

  PdfWorkspaceState copyWith({
    List<PdfAnnotationModel>? annotations,
    List<PdfBookmarkModel>? bookmarks,
    bool? isNightMode,
    double? zoomLevel,
    int? currentPage,
    int? totalPages,
    bool? isSearchActive,
    String? searchQuery,
    String? activeColorFilter,
    bool? isPanelOpen,
  }) {
    return PdfWorkspaceState(
      annotations: annotations ?? this.annotations,
      bookmarks: bookmarks ?? this.bookmarks,
      isNightMode: isNightMode ?? this.isNightMode,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isSearchActive: isSearchActive ?? this.isSearchActive,
      searchQuery: searchQuery ?? this.searchQuery,
      activeColorFilter: activeColorFilter ?? this.activeColorFilter,
      isPanelOpen: isPanelOpen ?? this.isPanelOpen,
    );
  }
}

final pdfViewerDatasourceProvider = Provider<PdfViewerLocalDatasource>((ref) {
  final storage = HiveLocalStorage();
  return PdfViewerLocalDatasource(storage);
});

final pdfViewerRepositoryProvider = Provider<PdfViewerRepository>((ref) {
  final ds = ref.watch(pdfViewerDatasourceProvider);
  return PdfViewerRepositoryImpl(ds);
});

class PdfWorkspaceController extends StateNotifier<PdfWorkspaceState> {
  final PdfViewerRepository _repository;
  final String _pdfPath;

  PdfWorkspaceController(this._repository, this._pdfPath) : super(PdfWorkspaceState()) {
    _loadWorkspace();
  }

  void _loadWorkspace() {
    if (_pdfPath.isEmpty) return;
    final anns = _repository.getAnnotations(_pdfPath);
    final bmks = _repository.getBookmarks(_pdfPath);
    state = state.copyWith(
      annotations: anns,
      bookmarks: bmks,
    );
  }

  Future<void> addAnnotation(PdfAnnotationModel ann) async {
    await _repository.saveAnnotation(ann);
    _loadWorkspace();
  }

  Future<void> deleteAnnotation(String id) async {
    await _repository.deleteAnnotation(id);
    _loadWorkspace();
  }

  Future<void> toggleBookmark(int pageNumber, {required String label}) async {
    final existing = state.bookmarks.where((b) => b.pageNumber == pageNumber).toList();
    if (existing.isNotEmpty) {
      for (var b in existing) {
        await _repository.deleteBookmark(b.id);
      }
    } else {
      final bmk = PdfBookmarkModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        pdfPath: _pdfPath,
        pageNumber: pageNumber,
        label: label,
        createdAt: DateTime.now(),
      );
      await _repository.saveBookmark(bmk);
    }
    _loadWorkspace();
  }

  Future<void> deleteBookmark(String id) async {
    await _repository.deleteBookmark(id);
    _loadWorkspace();
  }

  void setNightMode(bool value) {
    state = state.copyWith(isNightMode: value);
  }

  void setZoomLevel(double value) {
    state = state.copyWith(zoomLevel: value.clamp(1.0, 3.0));
  }

  void setCurrentPage(int value) {
    state = state.copyWith(currentPage: value);
  }

  void setTotalPages(int value) {
    state = state.copyWith(totalPages: value);
  }

  void setSearchActive(bool value) {
    state = state.copyWith(isSearchActive: value);
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  void setColorFilter(String value) {
    state = state.copyWith(activeColorFilter: value);
  }

  void togglePanel() {
    state = state.copyWith(isPanelOpen: !state.isPanelOpen);
  }
}

// Family provider so we have a scoped controller per PDF path
final pdfWorkspaceProvider = StateNotifierProvider.family<PdfWorkspaceController, PdfWorkspaceState, String>((ref, pdfPath) {
  final repo = ref.watch(pdfViewerRepositoryProvider);
  return PdfWorkspaceController(repo, pdfPath);
});
