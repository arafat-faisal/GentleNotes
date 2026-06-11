import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../models/models.dart';
import '../../../../folders/presentation/controllers/folders_controller.dart';
import '../../../../notes/presentation/controllers/notes_controller.dart';
import '../home_search_bar.dart';
import '../note_card.dart';

class HomeMagazineLayout extends ConsumerWidget {
  const HomeMagazineLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final folders = ref.watch(foldersProvider);
    final filteredNotes = ref.watch(filteredNotesProvider);

    if (filteredNotes.isEmpty) {
      return CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: HomeSearchBar(),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article_outlined, size: 48, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text('No Notes Yet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final heroNote = filteredNotes.first;
    final remainingNotes = filteredNotes.skip(1).toList();

    return CustomScrollView(
      slivers: [
        // Search & Tags
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: HomeSearchBar(),
          ),
        ),

        // Featured Title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Featured Cover',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),

        // Featured Hero Note
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildHeroCard(context, heroNote, folders),
          ),
        ),

        // Remaining Feed Title
        if (remainingNotes.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text(
                'Recent Articles',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
          ),

          // Remaining Notes Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final note = remainingNotes[index];
                  return NoteCard(note: note, folders: folders);
                },
                childCount: remainingNotes.length,
              ),
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context, NoteModel note, List<FolderModel> folders) {
    final theme = Theme.of(context);
    final folder = folders.cast<FolderModel?>().firstWhere(
          (f) => f?.id == note.folderId,
          orElse: () => null,
        );

    final folderColor = folder?.color ?? theme.colorScheme.secondary;
    final formattedDate = DateFormat('MMMM d, yyyy').format(note.updatedAt);

    // Dynamic gradient background color based on note's custom colorHex if present
    final Color baseColor = Color(int.parse(note.colorHex.replaceAll('#', 'FF'), radix: 16));

    return Card(
      elevation: 4,
      shadowColor: theme.colorScheme.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/notes/edit/${note.id}'),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                baseColor,
                theme.colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: folderColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      folder?.name ?? 'General',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: folderColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (note.isPinned)
                    Icon(Icons.push_pin, size: 16, color: theme.colorScheme.secondary),
                  if (note.isPinned && note.isFavorite) const SizedBox(width: 8),
                  if (note.isFavorite)
                    const Icon(Icons.favorite, size: 16, color: Color(0xFFF43F5E)),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                note.title.isEmpty ? 'Untitled Note' : note.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formattedDate,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                note.plainText,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 20),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: note.tags.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
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
}
