import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import '../controllers/pdf_workspace_controller.dart';
import '../widgets/pdf_viewer_body_widget.dart';
import '../widgets/pdf_search_bar.dart';
import '../widgets/study_summary_panel.dart';
import '../widgets/pdf_annotation_exporter.dart';
import '../../../editor/domain/entities/block_type.dart';

class PdfReaderWorkspaceScreen extends ConsumerStatefulWidget {
  final String pdfPath;
  final void Function(BlockType type, String content, Map<String, dynamic> attributes)? onInsertBlock;

  const PdfReaderWorkspaceScreen({
    super.key,
    required this.pdfPath,
    this.onInsertBlock,
  });

  @override
  ConsumerState<PdfReaderWorkspaceScreen> createState() => _PdfReaderWorkspaceScreenState();
}

class _PdfReaderWorkspaceScreenState extends ConsumerState<PdfReaderWorkspaceScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey _pdfViewerKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _pdfName {
    final parts = widget.pdfPath.replaceAll('\\', '/').split('/');
    return parts.isNotEmpty ? parts.last : 'PDF Document';
  }

  void _triggerSearch(String query) {
    if (query.isEmpty) return;
    // TODO: Implement search using PdfTextSearcher
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearchActive = false;
    });
    ref.read(pdfWorkspaceProvider(widget.pdfPath).notifier).setSearchActive(false);
  }

  void _saveSearchResultsAsNote() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Search extraction coming soon!'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showJumpToPageDialog(int totalPages) {
    final txtController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jump to Page'),
        content: TextField(
          controller: txtController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '1 - $totalPages',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(txtController.text.trim());
              if (page != null && page >= 1 && page <= totalPages) {
                _pdfViewerController.goToPage(pageNumber: page);
              }
              Navigator.pop(context);
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final workspaceState = ref.watch(pdfWorkspaceProvider(widget.pdfPath));
    final workspaceNotifier = ref.read(pdfWorkspaceProvider(widget.pdfPath).notifier);

    final Widget viewerBody = PdfViewerBodyWidget(
      pdfPath: widget.pdfPath,
      pdfViewerController: _pdfViewerController,
      pdfViewerKey: _pdfViewerKey,
      onInsertBlock: widget.onInsertBlock,
    );

    final String matchStatus = '';

    return Scaffold(
      backgroundColor: workspaceState.isNightMode ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(_pdfName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearchActive ? Icons.search_off_rounded : Icons.search_rounded),
            tooltip: 'Search inside document',
            onPressed: () {
              setState(() {
                _isSearchActive = !_isSearchActive;
              });
              workspaceNotifier.setSearchActive(_isSearchActive);
              if (!_isSearchActive) _clearSearch();
            },
          ),
          IconButton(
            icon: Icon(workspaceState.isNightMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            tooltip: 'Toggle Night Mode',
            onPressed: () {
              workspaceNotifier.setNightMode(!workspaceState.isNightMode);
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded),
            tooltip: 'Bookmark current page',
            onPressed: () {
              workspaceNotifier.toggleBookmark(
                workspaceState.currentPage,
                label: 'Custom bookmark page ${workspaceState.currentPage}',
              );
            },
          ),
          IconButton(
            icon: Icon(workspaceState.isPanelOpen ? Icons.menu_open_rounded : Icons.menu_rounded),
            tooltip: 'Toggle Study Panel',
            onPressed: () {
              workspaceNotifier.togglePanel();
            },
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                if (_isSearchActive)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: PdfSearchBar(
                      controller: _searchController,
                      matchStatus: matchStatus,
                      onPrevious: () {}, // TODO
                      onNext: () {}, // TODO
                      onClear: _clearSearch,
                      onSaveResults: _saveSearchResultsAsNote,
                      onSearch: _triggerSearch,
                    ),
                  ),
                Expanded(
                  child: ColorFiltered(
                    colorFilter: workspaceState.isNightMode
                        ? const ColorFilter.matrix(<double>[
                            -1, 0, 0, 0, 255,
                             0, -1, 0, 0, 255,
                             0, 0, -1, 0, 255,
                             0, 0, 0, 1, 0,
                          ])
                        : const ColorFilter.matrix(<double>[
                            1, 0, 0, 0, 0,
                            0, 1, 0, 0, 0,
                            0, 0, 1, 0, 0,
                            0, 0, 0, 1, 0,
                          ]),
                    child: viewerBody,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A2A) : Colors.white,
                    border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showJumpToPageDialog(workspaceState.totalPages),
                        icon: const Icon(Icons.pages_outlined, size: 16),
                        label: Text('Page ${workspaceState.currentPage} of ${workspaceState.totalPages}'),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.zoom_out_rounded),
                            onPressed: () {
                              _pdfViewerController.zoomDown();
                              workspaceNotifier.setZoomLevel(_pdfViewerController.currentZoom);
                            },
                          ),
                          Text('${(workspaceState.zoomLevel * 100).toInt()}%', style: const TextStyle(fontSize: 12)),
                          IconButton(
                            icon: const Icon(Icons.zoom_in_rounded),
                            onPressed: () {
                              _pdfViewerController.zoomUp();
                              workspaceNotifier.setZoomLevel(_pdfViewerController.currentZoom);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (workspaceState.isPanelOpen)
            StudySummaryPanel(
              annotations: workspaceState.annotations,
              bookmarks: workspaceState.bookmarks,
              onNavigateToPage: (page) {
                _pdfViewerController.goToPage(pageNumber: page);
              },
              onDeleteItem: (id, type) {
                if (type == 'annotation') {
                  workspaceNotifier.deleteAnnotation(id);
                } else {
                  workspaceNotifier.deleteBookmark(id);
                }
              },
              onExport: () {
                PdfAnnotationExporter.exportToMarkdown(
                  context: context,
                  pdfName: _pdfName,
                  annotations: workspaceState.annotations,
                  bookmarks: workspaceState.bookmarks,
                );
              },
            ),
        ],
      ),
    );
  }
}
