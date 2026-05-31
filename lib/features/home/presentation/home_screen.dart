import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/export_import_service.dart';
import '../../../models/models.dart';
import '../../../core/widgets/gentle_scaffold.dart';
import '../../folders/presentation/controllers/folders_controller.dart';
import '../../notes/presentation/controllers/notes_controller.dart';
import '../../settings/presentation/controllers/settings_controller.dart';
import 'widgets/folder_list_grid.dart';
import 'widgets/home_search_bar.dart';
import 'widgets/note_list_view.dart';
import 'widgets/quick_actions_bar.dart';
import 'widgets/stats_summary_grid.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final searchVal = ref.watch(searchQueryProvider);
    final activeTag = ref.watch(selectedTagFilterProvider);
    final filteredNotes = ref.watch(filteredNotesProvider);

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
      ),
    );
  }
}
