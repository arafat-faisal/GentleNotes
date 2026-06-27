import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../models/models.dart';
import '../../../../folders/presentation/controllers/folders_controller.dart';
import '../../../../notes/presentation/controllers/notes_controller.dart';
import '../home_action_delegate.dart';
import '../note_card.dart';

/// Distraction-free progressive disclosure layout.
/// 
/// Hides all secondary statistics modules, folders grids, and visual cards.
/// Renders a single vertical stream of notes alongside a floating "Omni-Bar"
/// search field that expands on tap to display active folder and tag filter chips.
class ContextualMinimalLayout extends ConsumerStatefulWidget {
  final List<NoteModel> notes;
  final HomeActionDelegate delegate;

  const ContextualMinimalLayout({
    super.key,
    required this.notes,
    required this.delegate,
  });

  @override
  ConsumerState<ContextualMinimalLayout> createState() => _ContextualMinimalLayoutState();
}

class _ContextualMinimalLayoutState extends ConsumerState<ContextualMinimalLayout> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(searchQueryProvider);
    
    // Automatically expand Omni-Bar filter chips when search input receives focus
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _isExpanded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Widget _buildOmniBar(BuildContext context) {
    final theme = Theme.of(context);
    final folders = ref.watch(foldersProvider);
    final allNotes = ref.watch(notesProvider);
    
    // Get unique tags across all notes in memory
    final allTags = allNotes.expand((n) => n.tags).toSet().toList();
    final activeTag = ref.watch(selectedTagFilterProvider);
    final activeFolder = ref.watch(selectedFolderFilterProvider);

    return Card(
      elevation: _isExpanded ? 6 : 2,
      shadowColor: theme.colorScheme.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Input Text Field
              TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: (val) {
                  ref.read(searchQueryProvider.notifier).state = val;
                },
                decoration: InputDecoration(
                  hintText: 'Search title, tags, body...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                        ),
                      IconButton(
                        icon: Icon(_isExpanded ? Icons.expand_less : Icons.tune),
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                            if (!_isExpanded) {
                              _focusNode.unfocus();
                            }
                          });
                        },
                        tooltip: 'Toggle filters',
                      ),
                    ],
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              
              // Progressive Disclosure Area: Expandable Filter Chips
              if (_isExpanded) ...[
                const SizedBox(height: 12),
                
                // 📂 Folders filter row
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Filter by Folder', 
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: folders.length + 2, // All Folders, folder list, New Folder
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = activeFolder == null;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: const Text('All Folders', style: TextStyle(fontSize: 11)),
                            selected: isSelected,
                            onSelected: (_) => widget.delegate.onSelectFolderFilter(ref, null),
                          ),
                        );
                      }
                      if (index == folders.length + 1) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            avatar: const Icon(Icons.add, size: 14, color: Colors.teal),
                            label: const Text('New Folder', style: TextStyle(fontSize: 11, color: Colors.teal)),
                            onPressed: () => widget.delegate.onFolderCreate(context),
                            backgroundColor: Colors.teal.withValues(alpha: 0.05),
                            side: BorderSide(color: Colors.teal.withValues(alpha: 0.2)),
                          ),
                        );
                      }
                      final folder = folders[index - 1];
                      final isSelected = activeFolder == folder.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          avatar: CircleAvatar(radius: 6, backgroundColor: folder.color),
                          label: Text(folder.name, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          onSelected: (_) => widget.delegate.onSelectFolderFilter(ref, folder.id),
                          selectedColor: folder.color.withValues(alpha: 0.15),
                          checkmarkColor: folder.color,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                
                // 🏷️ Tags filter row
                if (allTags.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'Filter by Tag', 
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: allTags.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          final isSelected = activeTag == null;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: const Text('All Tags', style: TextStyle(fontSize: 11)),
                              selected: isSelected,
                              onSelected: (_) => widget.delegate.onSelectTagFilter(ref, null),
                            ),
                          );
                        }
                        final tag = allTags[index - 1];
                        final isSelected = activeTag == tag;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text('#$tag', style: const TextStyle(fontSize: 11)),
                            selected: isSelected,
                            onSelected: (_) => widget.delegate.onSelectTagFilter(ref, isSelected ? null : tag),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final hasSearch = ref.watch(searchQueryProvider).isNotEmpty;
    final hasTag = ref.watch(selectedTagFilterProvider) != null;
    final hasFolder = ref.watch(selectedFolderFilterProvider) != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_alt_outlined, 
              size: 48, 
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch || hasTag || hasFolder ? 'No matching notes' : 'No Notes Yet',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Try adjusting your search queries or add notes using the action button.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final folders = ref.watch(foldersProvider);

    return GestureDetector(
      // Collapse filters when tapping outside the Omni-bar.
      // translucent ensures the scroll view still receives its own hit events.
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (_focusNode.hasFocus) {
          _focusNode.unfocus();
        }
        setState(() {
          _isExpanded = false;
        });
      },
      child: CustomScrollView(
        slivers: [
          // 1. Floating Omni-Bar Search Input
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _buildOmniBar(context),
            ),
          ),

          // 2. Main Notes List (Progressive Disclosure)
          if (widget.notes.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(context),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final note = widget.notes[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: NoteCard(
                        note: note,
                        folders: folders,
                      ),
                    );
                  },
                  childCount: widget.notes.length,
                ),
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}
