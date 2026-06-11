import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/gentle_scaffold.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../models/models.dart';
import '../data/folders_repository.dart';
import '../../notes/data/notes_repository.dart';
import '../../settings/data/settings_repository.dart';
import '../../home/presentation/widgets/folder_form_dialog.dart';
import 'widgets/folder_note_card.dart';

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
    final subfolders = folders.where((f) => f.parentFolderId == widget.folderId).toList();
    
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
            color: folderColor.withValues(alpha: 0.08),
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

          // Breadcrumbs
          _buildBreadcrumbs(context, folder, folders),

          // Subfolders
          _buildSubfoldersSection(context, subfolders, folder),

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
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                            color: folderColor.withValues(alpha: 0.2),
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
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
                        itemBuilder: (context, index) => FolderNoteGridCard(
                          note: folderNotes[index],
                          folderColor: folderColor,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: folderNotes.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FolderNoteListItem(
                            note: folderNotes[index],
                            folderColor: folderColor,
                          ),
                        ),
                      )),
          ),
        ],
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
  List<FolderModel> _getBreadcrumbs(FolderModel folder, List<FolderModel> folders) {
    FolderModel? findFolder(String id) {
      for (var f in folders) {
        if (f.id == id) return f;
      }
      return null;
    }

    final list = <FolderModel>[folder];
    var current = folder;
    while (current.parentFolderId != null) {
      final parent = findFolder(current.parentFolderId!);
      if (parent == null) break;
      list.insert(0, parent);
      current = parent;
    }
    return list;
  }

  Widget _buildBreadcrumbs(BuildContext context, FolderModel currentFolder, List<FolderModel> folders) {
    final breadcrumbs = _getBreadcrumbs(currentFolder, folders);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: breadcrumbs.map((f) {
          final isLast = f.id == currentFolder.id;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: isLast
                    ? null
                    : () {
                        context.push('/folders/${f.id}');
                      },
                child: Text(
                  f.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                    color: isLast ? theme.colorScheme.onSurface : theme.colorScheme.primary,
                  ),
                ),
              ),
              if (!isLast)
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubfoldersSection(BuildContext context, List<FolderModel> subfolders, FolderModel folder) {
    final theme = Theme.of(context);
    final folderColor = folder.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subfolders',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  FolderFormDialog.show(context, preselectedParentId: folder.id);
                },
                icon: Icon(Icons.create_new_folder, size: 16, color: folderColor),
                label: Text(
                  'Add Subfolder',
                  style: TextStyle(color: folderColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        if (subfolders.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              'No subfolders created yet.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: subfolders.length,
              itemBuilder: (context, index) {
                final sub = subfolders[index];
                final subColor = sub.color;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: Icon(IconHelper.getIcon(sub.iconName), color: subColor, size: 18),
                    label: Text(sub.name),
                    onPressed: () {
                      context.push('/folders/${sub.id}');
                    },
                    backgroundColor: subColor.withValues(alpha: 0.08),
                    side: BorderSide(color: subColor.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
