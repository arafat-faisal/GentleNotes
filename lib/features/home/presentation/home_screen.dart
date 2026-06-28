import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import '../../../core/widgets/gentle_scaffold.dart';
import 'widgets/home_action_delegate.dart';
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

  @override
  Widget build(BuildContext context) {
    final delegate = ref.watch(homeActionDelegateProvider);

    return GentleScaffold(
      title: 'Gentle Notes',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => delegate.onCreateNote(context),
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.download_rounded),
          tooltip: 'Import Backup/Note',
          onPressed: () => delegate.onImportBackup(context, ref),
        ),
        IconButton(
          icon: const Icon(Icons.menu_book_rounded),
          tooltip: 'Knowledge Hub',
          onPressed: () => context.push('/knowledge_hub'),
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () => delegate.onSettingsTap(context),
        ),
      ],
      body: const HomeLayoutSwitcher(),
    );
  }
}
