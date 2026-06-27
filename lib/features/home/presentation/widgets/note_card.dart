import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/models.dart';
import '../../../notes/presentation/controllers/notes_controller.dart';
import 'home_action_delegate.dart';

/// Card item representation for a single note.
/// 
/// Integrates:
/// - strategy actions using [HomeActionDelegate]
/// - drag-and-drop operations as a [Draggable] source
/// - swipe-to-pin & swipe-to-delete gestures via [Dismissible]
/// - active selection indicators for multi-select batch operations.
class NoteCard extends ConsumerWidget {
  final NoteModel note;
  final List<FolderModel> folders;

  const NoteCard({
    super.key,
    required this.note,
    required this.folders,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final folder = folders.cast<FolderModel?>().firstWhere(
          (f) => f?.id == note.folderId,
          orElse: () => null,
        );

    final folderColor = folder?.color ?? Colors.grey.shade400;
    
    // Watch batch selection state
    final selectedIds = ref.watch(selectedNoteIdsProvider);
    final isBatchActive = selectedIds.isNotEmpty;
    final isSelected = selectedIds.contains(note.id);
    final delegate = ref.watch(homeActionDelegateProvider);

    // 1. Construct the Base Visual Card representation
    Widget cardWidget = Card(
      elevation: isSelected ? 4 : 0,
      color: isSelected 
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15) 
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected 
              ? theme.colorScheme.primary 
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (isBatchActive) {
            // Toggle selection state
            if (isSelected) {
              ref.read(selectedNoteIdsProvider.notifier).state =
                  selectedIds.where((id) => id != note.id).toList();
            } else {
              ref.read(selectedNoteIdsProvider.notifier).state = [...selectedIds, note.id];
            }
          } else {
            delegate.onNoteTap(context, note.id);
          }
        },
        onLongPress: () {
          if (!isBatchActive) {
            // Activate batch edit selection mode
            ref.read(selectedNoteIdsProvider.notifier).state = [note.id];
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Multi-select Indicator Checkbox
                  if (isBatchActive) ...[
                    Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isSelected 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(note.noteType.icon, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  if (folder != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: folderColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        folder.name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: folderColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  if (note.isPinned)
                    Icon(Icons.push_pin, size: 16, color: theme.colorScheme.secondary),
                  if (note.isPinned && note.isFavorite) const SizedBox(width: 6),
                  if (note.isFavorite)
                    const Icon(Icons.favorite, size: 16, color: Color(0xFFF43F5E)),
                ],
              ),
              const SizedBox(height: 12),
              
              Text(
                note.title.isEmpty ? 'Untitled Note' : note.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),

              Text(
                note.plainText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: note.tags.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
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

    // 2. Wrap with Draggable functionality if not inside multi-select mode
    if (!isBatchActive) {
      cardWidget = LongPressDraggable<String>(
        data: note.id,
        hapticFeedbackOnStart: true,
        // Increase delay so scroll gestures win the gesture arena first.
        // At the default 500ms, even light touch+move can accidentally trigger
        // a drag instead of scrolling.
        delay: const Duration(milliseconds: 800),
        feedback: Material(
          type: MaterialType.transparency,
          child: SizedBox(
            width: MediaQuery.of(context).size.width.clamp(180.0, 340.0),
            child: Card(
              elevation: 8,
              shadowColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              color: theme.colorScheme.surface.withValues(alpha: 0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(note.noteType.icon, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          folder?.name ?? 'General',
                          style: TextStyle(fontSize: 10, color: folderColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      note.title.isEmpty ? 'Untitled Note' : note.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: cardWidget,
        ),
        child: cardWidget,
      );
    }

    // 3. Wrap with Dismissible swipe gestures if not inside multi-select mode
    if (!isBatchActive) {
      cardWidget = Dismissible(
        key: Key('note_dismiss_${note.id}'),
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.teal.shade400,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.push_pin, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Toggle Pin',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.redAccent.shade400,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Delete',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              Icon(Icons.delete_outline, color: Colors.white),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            await delegate.onNotePinToggle(ref, note.id);
            return false; // Slides back, toggling pin state reactively
          } else if (direction == DismissDirection.endToStart) {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Note?'),
                content: Text(
                  'Are you sure you want to permanently delete "${note.title.isEmpty ? 'Untitled Note' : note.title}"?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await delegate.onNoteDelete(ref, note.id);
              return true;
            }
            return false;
          }
          return false;
        },
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}
