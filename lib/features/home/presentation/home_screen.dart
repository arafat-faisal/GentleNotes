import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/export_import_service.dart';
import '../../../core/widgets/gentle_scaffold.dart';
import '../../folders/presentation/controllers/folders_controller.dart';
import '../../notes/presentation/controllers/notes_controller.dart';
import 'widgets/home_layout_switcher.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleImport(BuildContext context) async {
    final success = await ExportImportService().pickAndImportFile();
    if (!mounted) return;
    if (success) {
      ref.read(foldersProvider.notifier).loadFolders();
      ref.read(notesProvider.notifier).loadNotes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Import completed successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to import file or cancelled.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GentleScaffold(
      title: 'Gentle Notes',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/notes/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.download_rounded),
          tooltip: 'Import Backup/Note',
          onPressed: () => _handleImport(context),
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () => context.go('/settings'),
        ),
      ],
      body: const HomeLayoutSwitcher(),
    );
  }
}
