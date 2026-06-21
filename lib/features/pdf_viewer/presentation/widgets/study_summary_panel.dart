import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/models/pdf_annotation_model.dart';
import '../../data/models/pdf_bookmark_model.dart';

class StudySummaryPanel extends StatefulWidget {
  final List<PdfAnnotationModel> annotations;
  final List<PdfBookmarkModel> bookmarks;
  final Function(int page) onNavigateToPage;
  final Function(String id, String type) onDeleteItem;
  final VoidCallback onExport;

  const StudySummaryPanel({
    super.key,
    required this.annotations,
    required this.bookmarks,
    required this.onNavigateToPage,
    required this.onDeleteItem,
    required this.onExport,
  });

  @override
  State<StudySummaryPanel> createState() => _StudySummaryPanelState();
}

class _StudySummaryPanelState extends State<StudySummaryPanel> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';
  String _activeColorCategory = 'all';

  bool _hasValidSnapshot(String? path) {
    if (path == null || path.isEmpty) return false;
    if (path.startsWith('data:')) return true;
    if (kIsWeb) return false;
    return File(path).existsSync();
  }

  Widget _buildSnapshotImage(String path, {double? height, BoxFit fit = BoxFit.cover}) {
    if (path.startsWith('data:')) {
      try {
        final bytes = base64Decode(path.split(',').last);
        return Image.memory(bytes, height: height, fit: fit);
      } catch (_) {
        return const Text('Invalid image data', style: TextStyle(fontSize: 11, color: Colors.grey));
      }
    }
    if (kIsWeb) {
      return const Text('Native path not supported on web', style: TextStyle(fontSize: 11, color: Colors.grey));
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, height: height, fit: fit);
    }
    return const Text('Image file missing', style: TextStyle(fontSize: 11, color: Colors.grey));
  }

  static const List<Map<String, dynamic>> filterCategories = [
    {'name': 'All', 'color': Colors.grey, 'hex': 'all'},
    {'name': 'Concept', 'color': Color(0xFFFFF176), 'hex': '#FFF176'},
    {'name': 'Exam', 'color': Color(0xFFFF8A80), 'hex': '#FF8A80'},
    {'name': 'Definition', 'color': Color(0xFFA5D6A7), 'hex': '#A5D6A7'},
    {'name': 'Doubt', 'color': Color(0xFF90CAF9), 'hex': '#90CAF9'},
    {'name': 'Formula', 'color': Color(0xFFFFCC80), 'hex': '#FFCC80'},
    {'name': 'Example', 'color': Color(0xFFE1BEE7), 'hex': '#E1BEE7'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _filterQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2F) : Colors.white,
        border: Border(left: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(theme),
          _buildTabBar(theme),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHighlightsTab(theme),
                _buildCommentsTab(theme),
                _buildSnapshotsTab(theme),
                _buildBookmarksTab(theme),
                _buildFlashcardsTab(theme),
              ],
            ),
          ),
          _buildFooter(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Study Hub',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Search my highlights & notes...',
                prefixIcon: Icon(Icons.search_rounded, size: 16),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return TabBar(
      controller: _tabController,
      labelColor: theme.colorScheme.primary,
      unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      indicatorColor: theme.colorScheme.primary,
      indicatorWeight: 3,
      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      tabs: const [
        Tab(text: 'Highlights'),
        Tab(text: 'Comments'),
        Tab(text: 'Snapshots'),
        Tab(text: 'Bookmarks'),
        Tab(text: 'Flashcards'),
      ],
    );
  }

  Widget _buildHighlightsTab(ThemeData theme) {
    final list = widget.annotations.where((a) {
      if (a.type != 'highlight' && a.type != 'underline' && a.type != 'strikethrough' && a.type != 'squiggly') return false;
      if (_activeColorCategory != 'all' && a.colorHex != _activeColorCategory) return false;
      if (_filterQuery.isNotEmpty) {
        return a.selectedText?.toLowerCase().contains(_filterQuery) ?? false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        _buildCategoryFilters(),
        Expanded(
          child: list.isEmpty
              ? _buildEmptyState('No highlights found')
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return _buildHighlightCard(item, theme);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters() {
    return Container(
      height: 32,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: filterCategories.length,
        itemBuilder: (context, index) {
          final cat = filterCategories[index];
          final isSelected = _activeColorCategory == cat['hex'];
          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: FilterChip(
              label: Text(cat['name'], style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : Colors.black87)),
              selected: isSelected,
              selectedColor: themeColor(cat['hex']),
              backgroundColor: themeColor(cat['hex']).withValues(alpha: 0.25),
              onSelected: (_) {
                setState(() {
                  _activeColorCategory = cat['hex'];
                });
              },
            ),
          );
        },
      ),
    );
  }

  Color themeColor(String hex) {
    if (hex == 'all') return Colors.blue;
    final cleanHex = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleanHex', radix: 16));
  }

  Widget _buildHighlightCard(PdfAnnotationModel item, ThemeData theme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => widget.onNavigateToPage(item.pageNumber),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: themeColor(item.colorHex).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Page ${item.pageNumber}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                    onPressed: () => widget.onDeleteItem(item.id, 'annotation'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.selectedText ?? '',
                style: const TextStyle(fontSize: 12, height: 1.4),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.noteText != null && item.noteText!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(6),
                    border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 2)),
                  ),
                  child: Text(
                    item.noteText!,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsTab(ThemeData theme) {
    final list = widget.annotations.where((a) {
      if (a.type != 'note') return false;
      if (_filterQuery.isNotEmpty) {
        return (a.noteText?.toLowerCase().contains(_filterQuery) ?? false) ||
            (a.selectedText?.toLowerCase().contains(_filterQuery) ?? false);
      }
      return true;
    }).toList();

    return list.isEmpty
        ? _buildEmptyState('No comments added yet')
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return _buildCommentCard(item, theme);
            },
          );
  }

  Widget _buildCommentCard(PdfAnnotationModel item, ThemeData theme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => widget.onNavigateToPage(item.pageNumber),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Page ${item.pageNumber} • Margin Note',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                    onPressed: () => widget.onDeleteItem(item.id, 'annotation'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (item.selectedText != null && item.selectedText!.isNotEmpty) ...[
                Text(
                  item.selectedText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
              ],
              Text(
                item.noteText ?? '',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookmarksTab(ThemeData theme) {
    final list = widget.bookmarks.where((b) {
      if (_filterQuery.isNotEmpty) {
        return b.label.toLowerCase().contains(_filterQuery);
      }
      return true;
    }).toList();

    return list.isEmpty
        ? _buildEmptyState('No bookmarks saved')
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () => widget.onNavigateToPage(item.pageNumber),
                  title: Text(
                    'Page ${item.pageNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Text(item.label, style: const TextStyle(fontSize: 11)),
                  trailing: IconButton(
                    icon: const Icon(Icons.bookmark_remove_rounded, size: 18, color: Colors.redAccent),
                    onPressed: () => widget.onDeleteItem(item.id, 'bookmark'),
                  ),
                ),
              );
            },
          );
  }

  Widget _buildFlashcardsTab(ThemeData theme) {
    final list = widget.annotations.where((a) {
      if (a.type != 'flashcard') return false;
      if (_filterQuery.isNotEmpty) {
        return (a.flashcardQuestion?.toLowerCase().contains(_filterQuery) ?? false) ||
            (a.flashcardAnswer?.toLowerCase().contains(_filterQuery) ?? false);
      }
      return true;
    }).toList();

    return list.isEmpty
        ? _buildEmptyState('No flashcards created')
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return _buildFlashcardWidget(item, theme);
            },
          );
  }

  Widget _buildFlashcardWidget(PdfAnnotationModel item, ThemeData theme) {
    final hasImg = _hasValidSnapshot(item.snapshotPath);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Page ${item.pageNumber} • Flashcard',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                  onPressed: () {
                    widget.onDeleteItem(item.id, 'annotation');
                    try {
                      if (!kIsWeb && item.snapshotPath != null && !item.snapshotPath!.startsWith('data:')) {
                        final file = File(item.snapshotPath!);
                        if (file.existsSync()) file.deleteSync();
                      }
                    } catch (_) {}
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (hasImg) ...[
              const Text('Question Image:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => widget.onNavigateToPage(item.pageNumber),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: _buildSnapshotImage(item.snapshotPath!, height: 100),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Q: ${item.flashcardQuestion ?? ""}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ExpansionTile(
              title: const Text('Reveal Answer', style: TextStyle(fontSize: 11, color: Colors.amber)),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.all(8),
              expandedAlignment: Alignment.topLeft,
              children: [
                Text(
                  item.flashcardAnswer ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnapshotsTab(ThemeData theme) {
    final list = widget.annotations.where((a) {
      if (a.type != 'snapshot') return false;
      if (_filterQuery.isNotEmpty) {
        return a.selectedText?.toLowerCase().contains(_filterQuery) ?? false;
      }
      return true;
    }).toList();

    return list.isEmpty
        ? _buildEmptyState('No snapshots captured')
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Page ${item.pageNumber}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                            onPressed: () {
                              widget.onDeleteItem(item.id, 'annotation');
                              try {
                                if (!kIsWeb && item.snapshotPath != null && !item.snapshotPath!.startsWith('data:')) {
                                  final file = File(item.snapshotPath!);
                                  if (file.existsSync()) file.deleteSync();
                                }
                              } catch (_) {}
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (item.snapshotPath != null && _hasValidSnapshot(item.snapshotPath))
                        InkWell(
                          onTap: () => widget.onNavigateToPage(item.pageNumber),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: _buildSnapshotImage(item.snapshotPath!, height: 120),
                          ),
                        )
                      else
                        const Text('Image missing', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 36, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.02),
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: ElevatedButton.icon(
        onPressed: widget.onExport,
        icon: const Icon(Icons.download_rounded, size: 16),
        label: const Text('Export Study Notes', style: TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
