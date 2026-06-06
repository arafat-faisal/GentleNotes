import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../notes/presentation/controllers/notes_controller.dart';
import '../home_search_bar.dart';
import '../note_list_view.dart';

class HomeMinimalFeedLayout extends ConsumerWidget {
  const HomeMinimalFeedLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final searchVal = ref.watch(searchQueryProvider);
    final activeTag = ref.watch(selectedTagFilterProvider);

    return CustomScrollView(
      slivers: [
        // Cozy Minimal Greeting Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Let\'s write down your thoughts today.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Search & Tag Chips
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: HomeSearchBar(),
          ),
        ),

        // Notes Title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              searchVal.isNotEmpty || activeTag != null ? 'Filtered Feed' : 'Your Feed',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
          ),
        ),

        // Note Feed List
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
