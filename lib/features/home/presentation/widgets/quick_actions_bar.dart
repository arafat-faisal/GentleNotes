import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/export_import_service.dart';
import '../../../folders/presentation/controllers/folders_controller.dart';
import '../../../notes/presentation/controllers/notes_controller.dart';
import 'folder_form_dialog.dart';

class QuickActionsBar extends ConsumerWidget {
  const QuickActionsBar({super.key});

  Future<void> _handleImport(BuildContext context, WidgetRef ref) async {
    final success = await ExportImportService().pickAndImportFile();
    if (success) {
      ref.read(foldersProvider.notifier).loadFolders();
      ref.read(notesProvider.notifier).loadNotes();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import completed successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to import file or cancelled.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildQuickAction(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.primary.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickAction(
                context,
                'Add Folder',
                Icons.create_new_folder_outlined,
                () => FolderFormDialog.show(context),
              ),
              const SizedBox(width: 8),
              _buildQuickAction(
                context,
                'Import JSON',
                Icons.file_present_outlined,
                () => _handleImport(context, ref),
              ),
              const SizedBox(width: 8),
              _buildQuickAction(
                context,
                'Templates',
                Icons.copy_all_outlined,
                () => context.go('/templates'),
              ),
              const SizedBox(width: 8),
              _buildQuickAction(
                context,
                'Calendar',
                Icons.calendar_month_outlined,
                () => context.go('/calendar'),
              ),
              const SizedBox(width: 8),
              _buildQuickAction(
                context,
                'Settings',
                Icons.tune,
                () => context.go('/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
