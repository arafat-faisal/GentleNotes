import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../models/models.dart';
import '../../../../folders/presentation/controllers/folders_controller.dart';
import '../../../../notes/presentation/controllers/notes_controller.dart';
import '../../../../templates/presentation/controllers/templates_controller.dart';
import '../home_action_delegate.dart';
import '../home_search_bar.dart';
import '../note_card.dart';

/// Tactile, asymmetrical Bento Box layout.
/// 
/// Lays out widgets inside a dynamic, modular grid that reflows based on 
/// screen boundaries. Incorporates:
/// - **Hero Tile (2x2)**: Most recently modified note with color gradient backgrounds and multi-line content previews.
/// - **Medium Tiles (1x2 / 2x1)**: Calendar indicators and Folder collection previews.
/// - **Small Tiles (1x1)**: Stats summary blocks.
/// 
/// Styled using "Tactile Maximalism" aesthetics: diffuse drop shadows, 
/// subtle inner gradients, and heavy Outfit/Inter typography hierarchy.
class BentoGridEditorialLayout extends ConsumerWidget {
  final List<NoteModel> notes;
  final HomeActionDelegate delegate;

  const BentoGridEditorialLayout({
    super.key,
    required this.notes,
    required this.delegate,
  });

  Widget _buildBentoCard(
    BuildContext context, {
    required Widget child,
    Color? baseColor,
    VoidCallback? onTap,
    double elevation = 0,
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    final shadowColor = theme.brightness == Brightness.dark ? Colors.black26 : Colors.black.withValues(alpha: 0.05);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Card(
        elevation: elevation,
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: highlight 
                ? theme.colorScheme.primary 
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: highlight ? 2.2 : 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  baseColor ?? theme.colorScheme.primary.withValues(alpha: 0.02),
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: child,
          ),
        ),
      ),
    );
  }

  // 👑 Hero Tile: Displays the most recently updated note with custom gradients
  Widget _buildHeroTile(BuildContext context, NoteModel? note, List<FolderModel> folders) {
    final theme = Theme.of(context);
    if (note == null) {
      return _buildBentoCard(
        context,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notes, color: theme.colorScheme.primary.withValues(alpha: 0.3), size: 36),
              const SizedBox(height: 8),
              Text('No notes yet.', style: theme.textTheme.titleSmall),
            ],
          ),
        ),
      );
    }

    final folder = folders.cast<FolderModel?>().firstWhere(
          (f) => f?.id == note.folderId,
          orElse: () => null,
        );
    final folderColor = folder?.color ?? theme.colorScheme.secondary;
    final dateStr = DateFormat('MMMM d, yyyy').format(note.updatedAt);
    
    // Parse custom note color hex for gradient backdrop
    Color? customColor;
    try {
      customColor = Color(int.parse(note.colorHex.replaceAll('#', 'FF'), radix: 16)).withValues(alpha: 0.12);
    } catch (_) {}

    return _buildBentoCard(
      context,
      baseColor: customColor,
      onTap: () => delegate.onNoteTap(context, note.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(note.noteType.icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              if (folder != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: folderColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    folder.name,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: folderColor),
                  ),
                ),
              const Spacer(),
              if (note.isPinned) Icon(Icons.push_pin, size: 16, color: theme.colorScheme.secondary),
              if (note.isPinned && note.isFavorite) const SizedBox(width: 6),
              if (note.isFavorite) const Icon(Icons.favorite, size: 16, color: Color(0xFFF43F5E)),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              note.title.isEmpty ? 'Untitled Note' : note.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
                fontSize: 18,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            dateStr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              note.plainText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📅 Calendar Tile: Medium tile showing current day and notes updated today count
  Widget _buildCalendarTile(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dayName = DateFormat('EEEE').format(now).toUpperCase();
    final dateStr = DateFormat('MMMM d, yyyy').format(now);
    
    // Notes modified today
    final notesCount = ref.watch(notesProvider).where((n) {
      final u = n.updatedAt;
      return u.year == now.year && u.month == now.month && u.day == now.day;
    }).length;

    return _buildBentoCard(
      context,
      onTap: () => delegate.onCalendarTap(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Planner Agenda', 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary, 
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                  letterSpacing: 0.5,
                  fontSize: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                dateStr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          Text(
            notesCount == 0 
                ? 'No updates today' 
                : '$notesCount ${notesCount == 1 ? "note" : "notes"} updated today',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showWorkspaceFoldersSheet(BuildContext context, List<FolderModel> folders, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, ref, _) {
                final allFolders = ref.watch(foldersProvider);
                final notes = ref.watch(notesProvider);
                final theme = Theme.of(context);
                
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Drag Handle Indicator
                      const SizedBox(height: 12),
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Header Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Workspace Folders',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Outfit',
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            IconButton.filledTonal(
                              onPressed: () {
                                Navigator.pop(context);
                                delegate.onFolderCreate(context);
                              },
                              icon: const Icon(Icons.create_new_folder_rounded, size: 20),
                              tooltip: 'Create Folder',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Scrollable List of Folders
                      Expanded(
                        child: allFolders.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.folder_open_outlined, 
                                      size: 48, 
                                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                                    ),
                                    const SizedBox(height: 12),
                                    Text('No folders created yet', style: theme.textTheme.bodyMedium),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: allFolders.length,
                                itemBuilder: (context, index) {
                                  final folder = allFolders[index];
                                  final count = notes.where((n) => n.folderId == folder.id).length;
                                  
                                  return Card(
                                    elevation: 0,
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: folder.color.withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.folder_rounded, color: folder.color, size: 24),
                                      ),
                                      title: Text(
                                        folder.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '$count ${count == 1 ? "note" : "notes"} in this workspace',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                          fontSize: 12,
                                        ),
                                      ),
                                      trailing: Icon(
                                        Icons.chevron_right_rounded,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        delegate.onFolderTap(context, folder.id);
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // 📂 Folders Tile: Medium tile showing summary scroll list of folders
  Widget _buildFoldersTile(BuildContext context, List<FolderModel> folders, WidgetRef ref) {
    final theme = Theme.of(context);

    return _buildBentoCard(
      context,
      onTap: () => _showWorkspaceFoldersSheet(context, folders, ref),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.folder_copy_outlined, size: 16, color: const Color(0xFF10B981)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Workspace Folders', 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF10B981), 
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: Color(0xFF10B981)),
                onPressed: () => delegate.onFolderCreate(context),
                tooltip: 'Create New Folder',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: folders.isEmpty
                ? Center(
                    child: Text(
                      'No folders', 
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                    ),
                  )
                : ListView.builder(
                    itemCount: folders.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final folder = folders[index];
                      final count = ref.watch(notesProvider).where((n) => n.folderId == folder.id).length;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: InkWell(
                          onTap: () => delegate.onFolderTap(context, folder.id),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(color: folder.color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  folder.name, 
                                  maxLines: 1, 
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ),
                              Text(
                                '$count',
                                style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 📊 Stats Tile: Small tile (1x1) representing interactive metrics
  Widget _buildStatTile(
    BuildContext context, {
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return _buildBentoCard(
      context,
      onTap: onTap,
      highlight: isActive,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 18),
              if (isActive)
                Icon(Icons.check_circle_outline, color: color, size: 12),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count, 
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold, 
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                title, 
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(foldersProvider);
    final allNotes = ref.watch(notesProvider);
    final templates = ref.watch(templatesProvider);
    
    // Watch active filter states
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedFolder = ref.watch(selectedFolderFilterProvider);
    final selectedTag = ref.watch(selectedTagFilterProvider);
    final selectedType = ref.watch(selectedTypeFilterProvider);
    final favoriteOnly = ref.watch(filterFavoriteProvider);
    final pinnedOnly = ref.watch(filterPinnedProvider);

    final hasActiveFilters = searchQuery.isNotEmpty ||
        selectedFolder != null ||
        selectedTag != null ||
        selectedType != null ||
        favoriteOnly ||
        pinnedOnly;

    final heroNote = notes.isNotEmpty ? notes.first : null;
    final remainingNotes = notes.isEmpty 
        ? <NoteModel>[] 
        : (notes.length > 1 ? notes.skip(1).toList() : <NoteModel>[]);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        // 💻 Desktop Grid (Width > 900) - 4 Columns Bento Layout
        if (width > 900) {
          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: HomeSearchBar(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    height: 300,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left: Hero Tile (takes 2 columns out of 4)
                        Expanded(
                          flex: 2,
                          child: _buildHeroTile(context, heroNote, folders),
                        ),
                        const SizedBox(width: 16),
                        // Right: 2 Rows (takes remaining columns)
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              // Row 1: Calendar & Folders
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: _buildCalendarTile(context, ref)),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildFoldersTile(context, folders, ref)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Row 2: 4 Stats Cards
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _buildStatTile(
                                        context,
                                        title: 'All Notes',
                                        count: allNotes.length.toString(),
                                        icon: Icons.description_outlined,
                                        color: Colors.indigo,
                                        isActive: !hasActiveFilters,
                                        onTap: () => delegate.onResetAllFilters(ref),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatTile(
                                        context,
                                        title: 'Favorites',
                                        count: allNotes.where((n) => n.isFavorite).length.toString(),
                                        icon: Icons.favorite_border_rounded,
                                        color: const Color(0xFFF43F5E),
                                        isActive: favoriteOnly,
                                        onTap: () => delegate.onToggleFavoriteFilter(ref, favoriteOnly),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatTile(
                                        context,
                                        title: 'Templates',
                                        count: templates.length.toString(),
                                        icon: Icons.assignment_outlined,
                                        color: Colors.amber.shade800,
                                        isActive: false,
                                        onTap: () => delegate.onTemplatesTap(context),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatTile(
                                        context,
                                        title: 'Folders Count',
                                        count: folders.length.toString(),
                                        icon: Icons.folder_open_outlined,
                                        color: const Color(0xFF10B981),
                                        isActive: false,
                                        onTap: () {},
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Secondary Feed (Remaining notes)
              if (remainingNotes.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Text(
                      'Other Workspace Notes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.7,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => NoteCard(note: remainingNotes[index], folders: folders),
                      childCount: remainingNotes.length,
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        }

        // 📱 Tablet Grid (Width between 600 and 900) - 3 Columns
        if (width > 600) {
          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: HomeSearchBar(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    height: 300,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left: Hero Tile (takes 2 columns conceptually, so flex: 2)
                        Expanded(
                          flex: 2,
                          child: _buildHeroTile(context, heroNote, folders),
                        ),
                        const SizedBox(width: 14),
                        // Right: 2 Rows
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              // Row 1: Calendar & Folders
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: _buildCalendarTile(context, ref)),
                                    const SizedBox(width: 14),
                                    Expanded(child: _buildFoldersTile(context, folders, ref)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              // Row 2: 3 Stats Cards
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _buildStatTile(
                                        context,
                                        title: 'All Notes',
                                        count: allNotes.length.toString(),
                                        icon: Icons.description_outlined,
                                        color: Colors.indigo,
                                        isActive: !hasActiveFilters,
                                        onTap: () => delegate.onResetAllFilters(ref),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildStatTile(
                                        context,
                                        title: 'Favorites',
                                        count: allNotes.where((n) => n.isFavorite).length.toString(),
                                        icon: Icons.favorite_border_rounded,
                                        color: const Color(0xFFF43F5E),
                                        isActive: favoriteOnly,
                                        onTap: () => delegate.onToggleFavoriteFilter(ref, favoriteOnly),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildStatTile(
                                        context,
                                        title: 'Templates',
                                        count: templates.length.toString(),
                                        icon: Icons.assignment_outlined,
                                        color: Colors.amber.shade800,
                                        isActive: false,
                                        onTap: () => delegate.onTemplatesTap(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Secondary Feed (Remaining notes)
              if (remainingNotes.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Text(
                      'Other Notes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.65,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => NoteCard(note: remainingNotes[index], folders: folders),
                      childCount: remainingNotes.length,
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        }

        // 📱 Mobile Grid (Width <= 600) - Linear stacking flow
        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: HomeSearchBar(),
              ),
            ),
            // Bento elements rendered vertically/stack for mobile layout
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SizedBox(
                    height: 150,
                    child: _buildHeroTile(context, heroNote, folders),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(height: 115, child: _buildCalendarTile(context, ref)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(height: 115, child: _buildFoldersTile(context, folders, ref)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 80,
                          child: _buildStatTile(
                            context,
                            title: 'All Notes',
                            count: allNotes.length.toString(),
                            icon: Icons.description_outlined,
                            color: Colors.indigo,
                            isActive: !hasActiveFilters,
                            onTap: () => delegate.onResetAllFilters(ref),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 80,
                          child: _buildStatTile(
                            context,
                            title: 'Favorites',
                            count: allNotes.where((n) => n.isFavorite).length.toString(),
                            icon: Icons.favorite_border_rounded,
                            color: const Color(0xFFF43F5E),
                            isActive: favoriteOnly,
                            onTap: () => delegate.onToggleFavoriteFilter(ref, favoriteOnly),
                          ),
                        ),
                      ),
                    ],
                  ),
                ]),
              ),
            ),
            // Remaining Notes
            if (remainingNotes.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'Workspace Notes Feed',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: NoteCard(note: remainingNotes[index], folders: folders),
                    ),
                    childCount: remainingNotes.length,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      },
    );
  }
}
