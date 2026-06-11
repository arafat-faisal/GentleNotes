import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../models/models.dart';
import '../../../../folders/presentation/controllers/folders_controller.dart';
import '../../../../notes/presentation/controllers/notes_controller.dart';

class HomeCompactLayout extends ConsumerWidget {
  const HomeCompactLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final folders = ref.watch(foldersProvider);
    final filteredNotes = ref.watch(filteredNotesProvider);
    final searchVal = ref.watch(searchQueryProvider);

    return CustomScrollView(
      slivers: [
        // Dense Search Field
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: SizedBox(
              height: 40,
              child: TextField(
                onChanged: (val) {
                  ref.read(searchQueryProvider.notifier).state = val;
                },
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ),

        // Compact Folder tags row
        if (folders.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: folders.length,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemBuilder: (context, index) {
                  final folder = folders[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      avatar: CircleAvatar(
                        radius: 6,
                        backgroundColor: folder.color,
                      ),
                      label: Text(
                        folder.name,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => context.go('/folders/${folder.id}'),
                    ),
                  );
                },
              ),
            ),
          ),

        // List Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
            child: Text(
              searchVal.isNotEmpty ? 'Results (${filteredNotes.length})' : 'All Notes (${filteredNotes.length})',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),

        // Dense Note Rows
        if (filteredNotes.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'No notes found',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final note = filteredNotes[index];
                  return _buildCompactItem(context, note, folders);
                },
                childCount: filteredNotes.length,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildCompactItem(BuildContext context, NoteModel note, List<FolderModel> folders) {
    final theme = Theme.of(context);
    final folder = folders.cast<FolderModel?>().firstWhere(
          (f) => f?.id == note.folderId,
          orElse: () => null,
        );

    final dateStr = DateFormat('MM/dd').format(note.updatedAt);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/notes/edit/${note.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Icon(note.noteType.icon, size: 16, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
              const SizedBox(width: 10),
              if (folder != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: folder.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  note.title.isEmpty ? 'Untitled' : note.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (note.isPinned)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.push_pin, size: 12, color: theme.colorScheme.secondary),
                ),
              if (note.isFavorite)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.favorite, size: 12, color: Color(0xFFF43F5E)),
                ),
              Text(
                dateStr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
