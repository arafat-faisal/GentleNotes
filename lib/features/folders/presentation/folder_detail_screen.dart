import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/gentle_scaffold.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../models/models.dart';
import '../data/folders_repository.dart';
import '../../notes/data/notes_repository.dart';
import '../../settings/data/settings_repository.dart';

class FolderDetailScreen extends ConsumerStatefulWidget {
  final String folderId;

  const FolderDetailScreen({
    super.key,
    required this.folderId,
  });

  @override
  ConsumerState<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends ConsumerState<FolderDetailScreen> {
  final TextEditingController _folderSearchController = TextEditingController();
  String _localSearchQuery = '';

  @override
  void dispose() {
    _folderSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Fetch folder info
    final folders = ref.watch(foldersProvider);
    final folder = folders.cast<FolderModel?>().firstWhere(
          (f) => f?.id == widget.folderId,
          orElse: () => null,
        );

    // If folder doesn't exist (e.g. deleted), route back to home
    if (folder == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/home');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final folderColor = folder.color;
    final settings = ref.watch(settingsProvider);
    
    // Fetch notes inside this folder and filter by local query
    final allNotes = ref.watch(notesProvider);
    final folderNotes = allNotes.where((n) {
      final matchesFolder = n.folderId == widget.folderId;
      if (!matchesFolder) return false;
      
      if (_localSearchQuery.isNotEmpty) {
        final query = _localSearchQuery.toLowerCase();
        final matchesTitle = n.title.toLowerCase().contains(query);
        final matchesContent = n.plainText.toLowerCase().contains(query);
        final matchesTag = n.tags.any((t) => t.toLowerCase().contains(query));
        return matchesTitle || matchesContent || matchesTag;
      }
      return true;
    }).toList();

    return GentleScaffold(
      title: folder.name,
      showBackButton: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/notes/create?folderId=${folder.id}'),
        icon: const Icon(Icons.add),
        label: const Text('Add Note'),
        backgroundColor: folderColor,
        foregroundColor: Colors.white,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Rename Folder',
          onPressed: () => _showRenameFolderDialog(context, folder),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Folder Info Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: folderColor.withOpacity(0.08),
            child: Row(
              children: [
                Icon(IconHelper.getIcon(folder.iconName), color: folderColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${folderNotes.length} notes inside this folder',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: folderColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(settings.layoutMode == LayoutMode.grid ? Icons.list : Icons.grid_view),
                  onPressed: () {
                    final newMode = settings.layoutMode == LayoutMode.grid ? LayoutMode.list : LayoutMode.grid;
                    ref.read(settingsProvider.notifier).updateLayoutMode(newMode);
                  },
                ),
              ],
            ),
          ),

          // Folder-Specific Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _folderSearchController,
              onChanged: (val) {
                setState(() {
                  _localSearchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search notes inside ${folder.name}...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _folderSearchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _folderSearchController.clear();
                          setState(() {
                            _localSearchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              ),
            ),
          ),

          // Notes List/Grid
          Expanded(
            child: folderNotes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.note_alt_outlined,
                            size: 64,
                            color: folderColor.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _localSearchQuery.isNotEmpty ? 'No Matching Notes' : 'This Folder is Empty',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _localSearchQuery.isNotEmpty
                                ? 'Try modifying your search text.'
                                : 'Create your first note in this folder using the button below!',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : (settings.layoutMode == LayoutMode.grid
                    ? GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : (MediaQuery.of(context).size.width > 600 ? 3 : 2),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.3,
                        ),
                        itemCount: folderNotes.length,
                        itemBuilder: (context, index) => _buildNoteGridCard(context, folderNotes[index], folderColor),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: folderNotes.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildNoteListItem(context, folderNotes[index], folderColor),
                        ),
                      )),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteGridCard(BuildContext context, NoteModel note, Color folderColor) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: InkWell(
        onTap: () => context.push('/notes/edit/${note.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(note.noteType.icon, size: 18, color: folderColor),
                  Row(
                    children: [
                      if (note.isPinned)
                        Icon(Icons.push_pin, size: 14, color: theme.colorScheme.secondary),
                      if (note.isPinned && note.isFavorite) const SizedBox(width: 4),
                      if (note.isFavorite)
                        const Icon(Icons.favorite, size: 14, color: Color(0xFFF43F5E)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title.isEmpty ? 'Untitled Note' : note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        note.plainText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteListItem(BuildContext context, NoteModel note, Color folderColor) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: InkWell(
        onTap: () => context.push('/notes/edit/${note.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: folderColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(note.noteType.icon, size: 20, color: folderColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title.isEmpty ? 'Untitled Note' : note.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      note.plainText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (note.isPinned)
                Icon(Icons.push_pin, size: 16, color: theme.colorScheme.secondary),
              if (note.isPinned && note.isFavorite) const SizedBox(width: 6),
              if (note.isFavorite)
                const Icon(Icons.favorite, size: 16, color: Color(0xFFF43F5E)),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameFolderDialog(BuildContext context, FolderModel folder) {
    final controller = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Folder'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Folder Name'),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                final updated = folder.copyWith(name: text, updatedAt: DateTime.now());
                ref.read(foldersProvider.notifier).updateFolder(updated);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
