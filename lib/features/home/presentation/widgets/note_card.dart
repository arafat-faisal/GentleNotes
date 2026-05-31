import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../models/models.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;
  final List<FolderModel> folders;

  const NoteCard({
    super.key,
    required this.note,
    required this.folders,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final folder = folders.cast<FolderModel?>().firstWhere(
          (f) => f?.id == note.folderId,
          orElse: () => null,
        );

    final folderColor = folder?.color ?? Colors.grey.shade400;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: InkWell(
        onTap: () => context.push('/notes/edit/${note.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(note.noteType.icon, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  if (folder != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: folderColor.withOpacity(0.12),
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
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                      color: theme.colorScheme.surfaceVariant,
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
  }
}
