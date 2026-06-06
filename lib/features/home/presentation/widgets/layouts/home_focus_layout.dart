import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../models/models.dart';
import '../../../../folders/presentation/controllers/folders_controller.dart';
import '../../../../notes/presentation/controllers/notes_controller.dart';
import '../home_search_bar.dart';
import '../note_card.dart';

class HomeFocusLayout extends ConsumerWidget {
  const HomeFocusLayout({super.key});

  static const _quotes = [
    "Simplicity is the ultimate sophistication. — Leonardo da Vinci",
    "Focus on being productive instead of busy. — Tim Ferriss",
    "Your mind is for having ideas, not holding them. — David Allen",
    "Write down what should not be forgotten. — Isabel Allende",
    "The secret of getting ahead is getting started. — Mark Twain",
    "Done is better than perfect. — Sheryl Sandberg",
    "Deep work is the superpower of the 21st century. — Cal Newport",
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final folders = ref.watch(foldersProvider);
    final filteredNotes = ref.watch(filteredNotesProvider);
    final pinnedNotes = filteredNotes.where((n) => n.isPinned).toList();

    // Use current day to select a stable daily quote
    final dayIndex = DateTime.now().day;
    final quote = _quotes[dayIndex % _quotes.length];

    return CustomScrollView(
      slivers: [
        // Greeting & Quotes banner
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Focus Session',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Icon(Icons.format_quote_rounded, color: theme.colorScheme.primary, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            quote,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                              color: theme.colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Search bar
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: HomeSearchBar(),
          ),
        ),

        // Pinned notes list
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Pinned Focus Tasks',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
          ),
        ),

        if (pinnedNotes.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.push_pin_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No Pinned Notes',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pin notes from the editor to see them directly in Focus Mode.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
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
                    note: pinnedNotes[index],
                    folders: folders,
                  ),
                ),
                childCount: pinnedNotes.length,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}
