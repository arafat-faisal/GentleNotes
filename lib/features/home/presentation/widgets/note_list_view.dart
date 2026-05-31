import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../folders/presentation/controllers/folders_controller.dart';
import '../../../notes/presentation/controllers/notes_controller.dart';
import 'note_card.dart';

class NoteListView extends ConsumerWidget {
  const NoteListView({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredNotes = ref.watch(filteredNotesProvider);
    final folders = ref.watch(foldersProvider);
    final searchVal = ref.watch(searchQueryProvider);
    final activeTag = ref.watch(selectedTagFilterProvider);

    if (filteredNotes.isEmpty) {
      return _buildEmptyState(
        context,
        searchVal.isNotEmpty || activeTag != null ? 'No matching notes' : 'No Notes Yet',
        'Create a note using the floating action button below.',
        Icons.note_alt_outlined,
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredNotes.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: NoteCard(
          note: filteredNotes[index],
          folders: folders,
        ),
      ),
    );
  }
}
