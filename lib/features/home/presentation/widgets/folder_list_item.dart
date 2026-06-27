import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/icon_helper.dart';
import '../../../../models/models.dart';
import '../../../notes/presentation/controllers/notes_controller.dart';
import 'home_action_delegate.dart';

/// Row item representation for a single folder (List Layout Mode).
/// 
/// Integrates:
/// - strategy navigation callbacks using [HomeActionDelegate]
/// - drag-and-drop categorization as a [DragTarget] receiver for Note IDs.
class FolderListItem extends ConsumerWidget {
  final FolderModel folder;
  final VoidCallback onTapMore;
  
  const FolderListItem({
    super.key,
    required this.folder,
    required this.onTapMore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = folder.color;
    final delegate = ref.watch(homeActionDelegateProvider);

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data.isNotEmpty,
      onAcceptWithDetails: (details) {
        final noteId = details.data;
        delegate.onNoteMoveToFolder(ref, noteId, folder.id);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return Card(
          elevation: isHovered ? 2 : 0,
          color: isHovered 
              ? color.withValues(alpha: 0.08) 
              : theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isHovered ? color : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: isHovered ? 2.0 : 1.0,
            ),
          ),
          child: InkWell(
            onTap: () => delegate.onFolderTap(context, folder.id),
            onLongPress: onTapMore,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      IconHelper.getIcon(folder.iconName),
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folder.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                        ),
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final notesCount = ref.watch(notesProvider)
                              .where((n) => n.folderId == folder.id)
                              .length;
                          return Text(
                            '$notesCount ${notesCount == 1 ? "note" : "notes"}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: onTapMore,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
 }
}
