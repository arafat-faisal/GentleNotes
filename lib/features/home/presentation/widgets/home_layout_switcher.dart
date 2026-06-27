import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/models.dart';
import '../../../notes/presentation/controllers/notes_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import 'home_action_delegate.dart';
import 'layouts/bento_grid_editorial_layout.dart';
import 'layouts/contextual_minimal_layout.dart';

class HomeLayoutSwitcher extends ConsumerWidget {
  const HomeLayoutSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notes = ref.watch(filteredNotesProvider);
    final delegate = ref.watch(homeActionDelegateProvider);

    switch (settings.homeLayout) {
      case HomeLayoutPreset.minimal:
        return ContextualMinimalLayout(
          notes: notes,
          delegate: delegate,
        );
      case HomeLayoutPreset.bentoGrid:
        return BentoGridEditorialLayout(
          notes: notes,
          delegate: delegate,
        );
    }
  }
}

