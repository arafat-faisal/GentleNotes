import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/models.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import 'layouts/home_calendar_layout.dart';
import 'layouts/home_compact_layout.dart';
import 'layouts/home_dashboard_layout.dart';
import 'layouts/home_focus_layout.dart';
import 'layouts/home_magazine_layout.dart';
import 'layouts/home_minimal_feed_layout.dart';
import 'layouts/home_notebook_layout.dart';

class HomeLayoutSwitcher extends ConsumerWidget {
  const HomeLayoutSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    switch (settings.homeLayout) {
      case HomeLayoutPreset.dashboard:
        return const HomeDashboardLayout();
      case HomeLayoutPreset.minimalFeed:
        return const HomeMinimalFeedLayout();
      case HomeLayoutPreset.focus:
        return const HomeFocusLayout();
      case HomeLayoutPreset.magazine:
        return const HomeMagazineLayout();
      case HomeLayoutPreset.notebook:
        return const HomeNotebookLayout();
      case HomeLayoutPreset.calendar:
        return const HomeCalendarLayout();
      case HomeLayoutPreset.compact:
        return const HomeCompactLayout();
    }
  }
}
