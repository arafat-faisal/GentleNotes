import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/icon_helper.dart';
import '../../../../models/models.dart';
import '../../../notes/presentation/controllers/notes_controller.dart';

class FolderCard extends ConsumerWidget {
  final FolderModel folder;
  final VoidCallback onTapMore;
  const FolderCard({super.key, required this.folder, required this.onTapMore});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = folder.color;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: InkWell(
        onTap: () => context.go('/folders/${folder.id}'),
        onLongPress: onTapMore,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IconHelper.getIcon(folder.iconName),
                      color: color,
                      size: 24,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onTapMore,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Consumer(
                    builder: (context, ref, child) {
                      final notesCount = ref.watch(notesProvider)
                          .where((n) => n.folderId == folder.id)
                          .length;
                      return Text(
                        '$notesCount ${notesCount == 1 ? "note" : "notes"}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
