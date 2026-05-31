import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../folders/presentation/controllers/folders_controller.dart';
import '../../../notes/presentation/controllers/notes_controller.dart';
import '../../../templates/presentation/controllers/templates_controller.dart';

class StatsSummaryGrid extends ConsumerWidget {
  const StatsSummaryGrid({super.key});

  Widget _buildStatCard(BuildContext context, String title, String count, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(count, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(title, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(foldersProvider);
    final notes = ref.watch(notesProvider);
    final templates = ref.watch(templatesProvider);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildStatCard(context, 'Notes', notes.length.toString(), Icons.description_outlined, Colors.indigo),
        _buildStatCard(context, 'Folders', folders.length.toString(), Icons.folder_open_outlined, const Color(0xFF10B981)),
        _buildStatCard(context, 'Templates', templates.length.toString(), Icons.assignment_outlined, Colors.amber),
        _buildStatCard(context, 'Favorites', notes.where((n) => n.isFavorite).length.toString(), Icons.favorite_border_rounded, const Color(0xFFF43F5E)),
      ],
    );
  }
}
