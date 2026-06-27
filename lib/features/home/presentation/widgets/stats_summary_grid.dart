import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../folders/presentation/controllers/folders_controller.dart';
import '../../../notes/presentation/controllers/notes_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../templates/presentation/controllers/templates_controller.dart';
import '../../../../models/models.dart';
import 'home_action_delegate.dart';

/// Aggregated statistics summary grid displayed on the home page.
/// 
/// Cards are interactive:
/// - **Notes Card**: Resets all filters; highlighted when no filters are active.
/// - **Folders Card**: Switches to Notebook Shelf layout; highlighted when shelf layout is active.
/// - **Templates Card**: Navigates to the Templates module.
/// - **Favorites Card**: Toggles the favorite notes filter; highlighted when active.
class StatsSummaryGrid extends ConsumerWidget {
  const StatsSummaryGrid({super.key});

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: isActive ? 4 : 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive 
              ? color 
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: isActive ? 2.2 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    count, 
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold, 
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    title, 
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(foldersProvider);
    final notes = ref.watch(notesProvider);
    final templates = ref.watch(templatesProvider);
    final settings = ref.watch(settingsProvider);
    
    // Watch filter states to determine card highlight states
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedFolder = ref.watch(selectedFolderFilterProvider);
    final selectedTag = ref.watch(selectedTagFilterProvider);
    final selectedType = ref.watch(selectedTypeFilterProvider);
    final favoriteOnly = ref.watch(filterFavoriteProvider);
    final pinnedOnly = ref.watch(filterPinnedProvider);
    final delegate = ref.watch(homeActionDelegateProvider);

    final hasActiveFilters = searchQuery.isNotEmpty ||
        selectedFolder != null ||
        selectedTag != null ||
        selectedType != null ||
        favoriteOnly ||
        pinnedOnly;

    // Check if bento grid layout is active
    final isBentoActive = settings.homeLayout == HomeLayoutPreset.bentoGrid;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildStatCard(
          context,
          title: 'Notes',
          count: notes.length.toString(),
          icon: Icons.description_outlined,
          color: Colors.indigo,
          isActive: !hasActiveFilters, // Highlight when showing all notes
          onTap: () => delegate.onResetAllFilters(ref),
        ),
        _buildStatCard(
          context,
          title: 'Folders',
          count: folders.length.toString(),
          icon: Icons.folder_open_outlined,
          color: const Color(0xFF10B981),
          isActive: isBentoActive, // Highlight when in bento mode
          onTap: () {
            delegate.onResetAllFilters(ref);
            delegate.onUpdateHomeLayout(ref, HomeLayoutPreset.bentoGrid);
          },
        ),
        _buildStatCard(
          context,
          title: 'Templates',
          count: templates.length.toString(),
          icon: Icons.assignment_outlined,
          color: Colors.amber.shade800,
          isActive: false,
          onTap: () => delegate.onTemplatesTap(context),
        ),
        _buildStatCard(
          context,
          title: 'Favorites',
          count: notes.where((n) => n.isFavorite).length.toString(),
          icon: Icons.favorite_border_rounded,
          color: const Color(0xFFF43F5E),
          isActive: favoriteOnly, // Highlight when favorites filter is enabled
          onTap: () => delegate.onToggleFavoriteFilter(ref, favoriteOnly),
        ),
      ],
    );
  }
}
