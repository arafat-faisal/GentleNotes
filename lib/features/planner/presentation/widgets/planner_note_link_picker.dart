/// Bottom sheet for linking a note to a planner item.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../features/notes/presentation/controllers/notes_controller.dart';
import '../../../../../models/models.dart';

class PlannerNoteLinkPicker extends ConsumerWidget {
  const PlannerNoteLinkPicker({
    super.key,
    required this.selectedNoteId,
    required this.onChanged,
  });

  final String? selectedNoteId;
  final ValueChanged<String?> onChanged;

  /// Opens the note link picker bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required String? currentNoteId,
    required ValueChanged<String?> onChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ProviderScope(
        child: PlannerNoteLinkPicker(
          selectedNoteId: currentNoteId,
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notes = ref.watch(notesProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, controller) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Link a Note', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Select a note to attach to this plan.', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 12),
                  // Clear link option
                  if (selectedNoteId != null)
                    TextButton.icon(
                      onPressed: () {
                        onChanged(null);
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.link_off_rounded, size: 16),
                      label: const Text('Remove link'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: notes.isEmpty
                  ? Center(
                      child: Text(
                        'No notes available.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        final isSelected = note.id == selectedNoteId;
                        return _NoteListTile(
                          note: note,
                          isSelected: isSelected,
                          onTap: () {
                            onChanged(note.id);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _NoteListTile extends StatelessWidget {
  const _NoteListTile({
    required this.note,
    required this.isSelected,
    required this.onTap,
  });

  final NoteModel note;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4))
            : BorderSide.none,
      ),
      child: ListTile(
        leading: Icon(note.noteType.icon, color: theme.colorScheme.primary, size: 20),
        title: Text(
          note.title.isEmpty ? 'Untitled' : note.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal),
        ),
        trailing: isSelected ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary) : null,
        onTap: onTap,
      ),
    );
  }
}
