import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/models.dart';
import '../../../folders/presentation/controllers/folders_controller.dart';
import '../../../notes/presentation/controllers/notes_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import 'folder_card.dart';
import 'folder_form_dialog.dart';
import 'folder_list_item.dart';

class FolderListGrid extends ConsumerStatefulWidget {
  const FolderListGrid({super.key});

  @override
  ConsumerState<FolderListGrid> createState() => _FolderListGridState();
}

class _FolderListGridState extends ConsumerState<FolderListGrid> {
  void _showFolderOptions(BuildContext context, FolderModel folder) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Folder: ${folder.name}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Folder details'),
                onTap: () {
                  Navigator.pop(context);
                  FolderFormDialog.show(context, existingFolder: folder);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Folder', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteFolder(context, folder);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteFolder(BuildContext context, FolderModel folder) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Folder?'),
          content: Text(
            'Are you sure you want to delete "${folder.name}"? '
            'This folder\'s notes will NOT be deleted, but they will become folder-less.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(foldersProvider.notifier).deleteFolder(folder.id);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

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
  Widget build(BuildContext context) {
    final folders = ref.watch(foldersProvider);
    final settings = ref.watch(settingsProvider);

    if (folders.isEmpty) {
      return _buildEmptyState(
        context,
        'No Folders Yet',
        'Create a folder to begin organizing your thoughts.',
        Icons.folder_zip_outlined,
      );
    }

    if (settings.layoutMode == LayoutMode.grid) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : (MediaQuery.of(context).size.width > 600 ? 3 : 2),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
        ),
        itemCount: folders.length,
        itemBuilder: (context, index) => FolderCard(
          folder: folders[index],
          onTapMore: () => _showFolderOptions(context, folders[index]),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: folders.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FolderListItem(
          folder: folders[index],
          onTapMore: () => _showFolderOptions(context, folders[index]),
        ),
      ),
    );
  }
}
