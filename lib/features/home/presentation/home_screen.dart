import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/widgets/gentle_scaffold.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../models/models.dart';
import '../../folders/data/folders_repository.dart';
import '../../notes/data/notes_repository.dart';
import '../../templates/data/templates_repository.dart';
import '../../settings/data/settings_repository.dart';
import '../../../services/export_import_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final folders = ref.watch(foldersProvider);
    final notes = ref.watch(notesProvider);
    final templates = ref.watch(templatesProvider);
    final filteredNotes = ref.watch(filteredNotesProvider);
    final settings = ref.watch(settingsProvider);

    // Get unique tags across all notes
    final allTags = notes.expand((n) => n.tags).toSet().toList();
    final activeTag = ref.watch(selectedTagFilterProvider);

    return GentleScaffold(
      title: 'Gentle Notes',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/notes/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.download_rounded),
          tooltip: 'Import Backup/Note',
          onPressed: () => _handleImport(context),
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () => context.go('/settings'),
        ),
      ],
      body: CustomScrollView(
        slivers: [
          // 1. Search Bar & Tag Chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      ref.read(searchQueryProvider.notifier).state = val;
                    },
                    decoration: InputDecoration(
                      hintText: 'Search notes by title, body, or tags...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(searchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tag Filter Bar
                  if (allTags.isNotEmpty)
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: allTags.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            final isAll = activeTag == null;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: const Text('All Tags'),
                                selected: isAll,
                                onSelected: (_) {
                                  ref.read(selectedTagFilterProvider.notifier).state = null;
                                },
                              ),
                            );
                          }
                          final tag = allTags[index - 1];
                          final isSelected = activeTag == tag;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text('#$tag'),
                              selected: isSelected,
                              onSelected: (_) {
                                ref.read(selectedTagFilterProvider.notifier).state = isSelected ? null : tag;
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 2. Stats Summary Grid (Collapsible/Dynamic)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  _buildStatCard(context, 'Notes', notes.length.toString(), Icons.description_outlined, Colors.indigo),
                  _buildStatCard(context, 'Folders', folders.length.toString(), Icons.folder_open_outlined, const Color(0xFF10B981)),
                  _buildStatCard(context, 'Templates', templates.length.toString(), Icons.assignment_outlined, Colors.amber),
                  _buildStatCard(context, 'Favorites', notes.where((n) => n.isFavorite).length.toString(), Icons.favorite_border_rounded, const Color(0xFFF43F5E)),
                ],
              ),
            ),
          ),

          // 3. Quick Actions row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Card(
                elevation: 0,
                color: theme.colorScheme.primary.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickAction(context, 'Add Folder', Icons.create_new_folder_outlined, () => _showAddFolderDialog(context)),
                        const SizedBox(width: 8),
                        _buildQuickAction(context, 'Import JSON', Icons.file_present_outlined, () => _handleImport(context)),
                        const SizedBox(width: 8),
                        _buildQuickAction(context, 'Templates', Icons.copy_all_outlined, () => context.go('/templates')),
                        const SizedBox(width: 8),
                        _buildQuickAction(context, 'Calendar', Icons.calendar_month_outlined, () => context.go('/calendar')),
                        const SizedBox(width: 8),
                        _buildQuickAction(context, 'Settings', Icons.tune, () => context.go('/settings')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 4. Folders Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Folders', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(settings.layoutMode == LayoutMode.grid ? Icons.list : Icons.grid_view),
                    onPressed: () {
                      final newMode = settings.layoutMode == LayoutMode.grid ? LayoutMode.list : LayoutMode.grid;
                      ref.read(settingsProvider.notifier).updateLayoutMode(newMode);
                    },
                    tooltip: 'Toggle Layout Grid/List',
                  ),
                ],
              ),
            ),
          ),

          // 5. Folders List/Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: folders.isEmpty
                ? SliverToBoxAdapter(
                    child: _buildEmptyState(context, 'No Folders Yet', 'Create a folder to begin organizing your thoughts.', Icons.folder_zip_outlined),
                  )
                : (settings.layoutMode == LayoutMode.grid
                    ? SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : (MediaQuery.of(context).size.width > 600 ? 3 : 2),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.4,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildFolderCard(context, folders[index]),
                          childCount: folders.length,
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildFolderListItem(context, folders[index]),
                          ),
                          childCount: folders.length,
                        ),
                      )),
          ),

          // 6. Recent Notes Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 24, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _searchController.text.isNotEmpty || activeTag != null ? 'Filtered Notes' : 'Recent Notes',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (filteredNotes.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        context.push('/notes/create');
                      },
                      child: const Text('Add Note'),
                    ),
                ],
              ),
            ),
          ),

          // 7. Recent Notes List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: filteredNotes.isEmpty
                ? SliverToBoxAdapter(
                    child: _buildEmptyState(
                      context,
                      _searchController.text.isNotEmpty || activeTag != null ? 'No matching notes' : 'No Notes Yet',
                      'Create a note using the floating action button below.',
                      Icons.note_alt_outlined,
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildNoteCard(context, filteredNotes[index], folders),
                      ),
                      childCount: filteredNotes.length,
                    ),
                  ),
          ),

          // Extra spacing at bottom
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildStatCard(BuildContext context, String title, String count, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(count, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(title, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderCard(BuildContext context, FolderModel folder) {
    final theme = Theme.of(context);
    final color = folder.color;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: InkWell(
        onTap: () => context.go('/folders/${folder.id}'),
        onLongPress: () => _showFolderOptions(context, folder),
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IconHelper.getIcon(folder.iconName),
                      color: color,
                      size: 24,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showFolderOptions(context, folder),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Consumer(
                    builder: (context, ref, child) {
                      final notesCount = ref.watch(notesProvider)
                          .where((n) => n.folderId == folder.id)
                          .length;
                      return Text(
                        '$notesCount ${notesCount == 1 ? "note" : "notes"}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolderListItem(BuildContext context, FolderModel folder) {
    final theme = Theme.of(context);
    final color = folder.color;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: InkWell(
        onTap: () => context.go('/folders/${folder.id}'),
        onLongPress: () => _showFolderOptions(context, folder),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  IconHelper.getIcon(folder.iconName),
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Consumer(
                      builder: (context, ref, child) {
                        final notesCount = ref.watch(notesProvider)
                            .where((n) => n.folderId == folder.id)
                            .length;
                        return Text(
                          '$notesCount ${notesCount == 1 ? "note" : "notes"}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                onPressed: () => _showFolderOptions(context, folder),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, NoteModel note, List<FolderModel> folders) {
    final theme = Theme.of(context);
    final folder = folders.cast<FolderModel?>().firstWhere(
          (f) => f?.id == note.folderId,
          orElse: () => null,
        );

    final folderColor = folder?.color ?? Colors.grey.shade400;

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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Upper details (Pinned/Fav + Date + Type)
              Row(
                children: [
                  Icon(note.noteType.icon, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  if (folder != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: folderColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        folder.name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: folderColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  if (note.isPinned)
                    Icon(Icons.push_pin, size: 16, color: theme.colorScheme.secondary),
                  if (note.isPinned && note.isFavorite) const SizedBox(width: 6),
                  if (note.isFavorite)
                    const Icon(Icons.favorite, size: 16, color: Color(0xFFF43F5E)),
                ],
              ),
              const SizedBox(height: 12),
              
              // Note Title
              Text(
                note.title.isEmpty ? 'Untitled Note' : note.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),

              // Note Body Snippet
              Text(
                note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                // Tags list
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: note.tags.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#$t',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, String subtitle, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.primary.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }

  // --- ACTIONS HANDLERS ---

  Future<void> _handleImport(BuildContext context) async {
    final success = await ExportImportService().pickAndImportFile();
    if (!mounted) return;
    if (success) {
      ref.read(foldersProvider.notifier).loadFolders();
      ref.read(notesProvider.notifier).loadNotes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Import completed successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to import file or cancelled.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showFolderOptions(BuildContext context, FolderModel folder) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Folder: ${folder.name}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Folder details'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditFolderDialog(context, folder);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Folder', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteFolder(context, folder);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteFolder(BuildContext context, FolderModel folder) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Folder?'),
          content: Text(
            'Are you sure you want to delete "${folder.name}"? '
            'This folder\'s notes will NOT be deleted, but they will become folder-less.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(foldersProvider.notifier).deleteFolder(folder.id);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Dialogs for creating and editing folders
  void _showAddFolderDialog(BuildContext context) {
    _showFolderFormDialog(context, null);
  }

  void _showEditFolderDialog(BuildContext context, FolderModel folder) {
    _showFolderFormDialog(context, folder);
  }

  void _showFolderFormDialog(BuildContext context, FolderModel? existingFolder) {
    final isEdit = existingFolder != null;
    final nameController = TextEditingController(text: existingFolder?.name ?? '');
    
    // Configurable choices for colors
    final colors = [
      '#6366F1', // Indigo
      '#10B981', // Emerald
      '#3B82F6', // Blue
      '#F43F5E', // Rose
      '#F59E0B', // Amber
      '#8B5CF6', // Purple
      '#EC4899', // Pink
      '#F97316', // Orange
    ];
    
    // Configurable choices for icons
    final icons = IconHelper.getAvailableIconNames();

    String selectedColor = existingFolder?.colorHex ?? colors.first;
    String selectedIcon = existingFolder?.iconName ?? icons.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final theme = Theme.of(context);
            return AlertDialog(
              title: Text(isEdit ? 'Edit Folder' : 'New Folder'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Folder Name',
                        hintText: 'e.g., Deep Learning Study',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 18),
                    
                    Text('Select Color', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      width: 300,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: colors.length,
                        itemBuilder: (context, index) {
                          final colorHex = colors[index];
                          final isSelected = selectedColor == colorHex;
                          final color = Color(int.parse('FF${colorHex.replaceAll('#', '')}', radix: 16));
                          return GestureDetector(
                            onTap: () {
                              setStateDialog(() {
                                selectedColor = colorHex;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: theme.colorScheme.onSurface, width: 2.5)
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    
                    Text('Select Icon', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: icons.map((iconName) {
                        final isSelected = selectedIcon == iconName;
                        final iconData = IconHelper.getIcon(iconName);
                        final color = Color(int.parse('FF${selectedColor.replaceAll('#', '')}', radix: 16));
                        return GestureDetector(
                          onTap: () {
                            setStateDialog(() {
                              selectedIcon = iconName;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withOpacity(0.15) : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected ? Border.all(color: color, width: 1.5) : null,
                            ),
                            child: Icon(
                              iconData,
                              color: isSelected ? color : theme.colorScheme.onSurface.withOpacity(0.6),
                              size: 22,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    if (isEdit) {
                      final updated = existingFolder.copyWith(
                        name: name,
                        colorHex: selectedColor,
                        iconName: selectedIcon,
                        updatedAt: DateTime.now(),
                      );
                      ref.read(foldersProvider.notifier).updateFolder(updated);
                    } else {
                      final newFolder = FolderModel(
                        id: const Uuid().v4(),
                        name: name,
                        colorHex: selectedColor,
                        iconName: selectedIcon,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                        sortOrder: ref.read(foldersProvider).length + 1,
                      );
                      ref.read(foldersProvider.notifier).addFolder(newFolder);
                    }
                    Navigator.pop(context);
                  },
                  child: Text(isEdit ? 'Save' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
