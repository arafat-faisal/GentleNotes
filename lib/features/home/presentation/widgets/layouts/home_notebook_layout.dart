import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../models/models.dart';
import '../../../../folders/presentation/controllers/folders_controller.dart';
import '../../../../notes/presentation/controllers/notes_controller.dart';
import '../note_card.dart';

class HomeNotebookLayout extends ConsumerStatefulWidget {
  const HomeNotebookLayout({super.key});

  @override
  ConsumerState<HomeNotebookLayout> createState() => _HomeNotebookLayoutState();
}

class _HomeNotebookLayoutState extends ConsumerState<HomeNotebookLayout> {
  String? _selectedFolderId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final folders = ref.watch(foldersProvider);
    final filteredNotes = ref.watch(filteredNotesProvider);

    // Filter notes by the locally selected folder if not "All"
    final displayNotes = _selectedFolderId == null
        ? filteredNotes
        : filteredNotes.where((n) => n.folderId == _selectedFolderId).toList();

    // Try to resolve folder name or fallback to "All Notes"
    final String activeHeaderTitle;
    if (_selectedFolderId == null) {
      activeHeaderTitle = 'All Folders & Notes';
    } else {
      final activeFolder = folders.cast<FolderModel?>().firstWhere(
            (f) => f?.id == _selectedFolderId,
            orElse: () => null,
          );
      activeHeaderTitle = activeFolder != null ? '${activeFolder.name} Notes' : 'Notes';
    }

    return CustomScrollView(
      slivers: [
        // Notebook title banner
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notebook Shelves',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Browse through your folders to discover your notes.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Horizontal scrollable folders shelf
        SliverToBoxAdapter(
          child: SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: folders.length + 1,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = _selectedFolderId == null;
                  return _buildFolderTab(
                    context,
                    name: 'All Folders',
                    icon: Icons.grid_view_rounded,
                    color: theme.colorScheme.primary,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedFolderId = null),
                  );
                }

                final folder = folders[index - 1];
                final isSelected = _selectedFolderId == folder.id;
                
                // Map icon name to IconData
                IconData folderIcon = Icons.folder_rounded;
                if (folder.iconName == 'psychology_outlined') {
                  folderIcon = Icons.psychology;
                } else if (folder.iconName == 'lightbulb_outline') {
                  folderIcon = Icons.lightbulb_outline_rounded;
                } else if (folder.iconName == 'science_outlined') {
                  folderIcon = Icons.science_outlined;
                } else if (folder.iconName == 'work_outline') {
                  folderIcon = Icons.work_outline_rounded;
                } else if (folder.iconName == 'g_translate') {
                  folderIcon = Icons.g_translate_rounded;
                } else if (folder.iconName == 'book_outlined') {
                  folderIcon = Icons.book_rounded;
                }

                return _buildFolderTab(
                  context,
                  name: folder.name,
                  icon: folderIcon,
                  color: folder.color,
                  isSelected: isSelected,
                  onTap: () => setState(() => _selectedFolderId = folder.id),
                );
              },
            ),
          ),
        ),

        // Group Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              activeHeaderTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
          ),
        ),

        // Foldered notes display
        if (displayNotes.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Shelf is Empty',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No notes categorized under this folder shelf.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NoteCard(
                    note: displayNotes[index],
                    folders: folders,
                  ),
                ),
                childCount: displayNotes.length,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildFolderTab(
    BuildContext context, {
    required String name,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: isSelected ? color.withValues(alpha: 0.12) : theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? color : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(icon, color: isSelected ? color : theme.colorScheme.onSurface.withValues(alpha: 0.5), size: 18),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? color : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
