import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../models/models.dart';
import '../../../../folders/presentation/controllers/folders_controller.dart';
import '../../../../notes/presentation/controllers/notes_controller.dart';
import '../../../../settings/presentation/controllers/settings_controller.dart';
import '../folder_list_grid.dart';
import '../home_search_bar.dart';
import '../note_list_view.dart';
import '../quick_actions_bar.dart';
import '../stats_summary_grid.dart';

class HomeDashboardLayout extends ConsumerWidget {
  const HomeDashboardLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final searchVal = ref.watch(searchQueryProvider);
    final activeTag = ref.watch(selectedTagFilterProvider);
    final filteredNotes = ref.watch(filteredNotesProvider);

    return CustomScrollView(
      slivers: [
        // 1. Search Bar & Tag Chips
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: HomeSearchBar(),
          ),
        ),

        // 2. Stats Summary Grid
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: StatsSummaryGrid(),
          ),
        ),

        // 3. Quick Actions row
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: QuickActionsBar(),
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
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: FolderListGrid(),
          ),
        ),

        // 6. Recent Notes Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 24, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  searchVal.isNotEmpty || activeTag != null ? 'Filtered Notes' : 'Recent Notes',
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
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: NoteListView(),
          ),
        ),

        // Extra spacing at bottom
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}
