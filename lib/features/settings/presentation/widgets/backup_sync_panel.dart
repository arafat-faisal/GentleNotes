import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/services/export_import_service.dart';
import '../../../../models/models.dart';
import '../../../folders/presentation/controllers/folders_controller.dart';
import '../../../notes/presentation/controllers/notes_controller.dart';

class BackupSyncPanel extends ConsumerStatefulWidget {
  final UserRole userRole;
  const BackupSyncPanel({super.key, required this.userRole});

  @override
  ConsumerState<BackupSyncPanel> createState() => _BackupSyncPanelState();
}

class _BackupSyncPanelState extends ConsumerState<BackupSyncPanel> {
  Future<void> _handleExportBackup(BuildContext context) async {
    final jsonStr = ExportImportService().exportBackupAsJson();
    await Share.share(
      jsonStr,
      subject: 'GentleNotes_Backup_${DateTime.now().millisecondsSinceEpoch}.json',
    );
  }

  Future<void> _handleImportBackup(BuildContext context, WidgetRef ref) async {
    final success = await ExportImportService().pickAndImportFile();
    if (!mounted) return;
    if (success) {
      ref.read(foldersProvider.notifier).loadFolders();
      ref.read(notesProvider.notifier).loadNotes();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup restored successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to restore backup or cancelled.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('Cloud Sync State'),
            subtitle: Text(
              widget.userRole == UserRole.subscriber || widget.userRole == UserRole.admin
                  ? 'Connected. (Subscribed User Workspace Demo)'
                  : 'Offline Mode. Connect your subscription to sync.',
            ),
            trailing: widget.userRole == UserRole.subscriber || widget.userRole == UserRole.admin
                ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
                : const Icon(Icons.cloud_off, color: Colors.grey),
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.download_rounded, color: Colors.indigo),
            title: const Text('Import Backup File'),
            subtitle: const Text('Load full JSON backup database or raw text notes'),
            onTap: () => _handleImportBackup(context, ref),
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.upload_rounded, color: Colors.indigo),
            title: const Text('Export Backup File'),
            subtitle: const Text('Save entire folders, templates, and notes as JSON'),
            onTap: () => _handleExportBackup(context),
          ),
        ],
      ),
    );
  }
}
