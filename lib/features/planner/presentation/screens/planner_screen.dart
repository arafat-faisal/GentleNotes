/// Main Planner screen — tab coordinator for Today | Week | Month | Schedule.
///
/// This is a coordinator screen only. It composes four view widgets and
/// handles top-level navigation (FAB → Create screen).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/gentle_scaffold.dart';
import '../controllers/planner_controller.dart';
import '../controllers/planner_filter_controller.dart';
import '../screens/create_edit_planner_item_screen.dart';
import '../widgets/planner_ai_import_dialog.dart';
import '../widgets/planner_today_view.dart';
import '../widgets/planner_week_view.dart';
import '../widgets/planner_month_view.dart';
import '../widgets/planner_schedule_view.dart';
import '../widgets/planner_overview_tab.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = ['Overview', 'Today', 'Week', 'Month', 'Schedule'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelectionMode = ref.watch(plannerSelectionModeProvider);
    final selectedIds = ref.watch(plannerSelectedIdsProvider);

    return GentleScaffold(
      title: isSelectionMode ? '${selectedIds.length} Selected' : 'Planner',
      floatingActionButton: isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateEditPlannerItemScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Plan'),
            ),
      appBar: isSelectionMode ? _buildSelectionAppBar(theme, selectedIds) : _buildTabAppBar(theme),
      body: TabBarView(
        controller: _tabController,
        children: [
          PlannerOverviewTab(tabController: _tabController),
          const PlannerTodayView(),
          const PlannerWeekView(),
          const PlannerMonthView(),
          const PlannerScheduleView(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildSelectionAppBar(ThemeData theme, Set<String> selectedIds) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () {
          ref.read(plannerSelectionModeProvider.notifier).state = false;
          ref.read(plannerSelectedIdsProvider.notifier).state = {};
        },
      ),
      titleSpacing: 0,
      title: Text(
        '${selectedIds.length} Selected',
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          tooltip: 'Select All',
          icon: const Icon(Icons.select_all_rounded),
          onPressed: () {
            final allItems = ref.read(plannerProvider).items;
            ref.read(plannerSelectedIdsProvider.notifier).state = allItems.map((e) => e.id).toSet();
          },
        ),
        IconButton(
          tooltip: 'Delete Selected',
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
          onPressed: selectedIds.isEmpty
              ? null
              : () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Plans?'),
                      content: Text('Are you sure you want to delete ${selectedIds.length} plan(s)?'),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    final notifier = ref.read(plannerProvider.notifier);
                    await notifier.deleteMultipleItems(selectedIds.toList());
                    ref.read(plannerSelectionModeProvider.notifier).state = false;
                    ref.read(plannerSelectedIdsProvider.notifier).state = {};
                  }
                },
        ),
        const SizedBox(width: 8),
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
        isScrollable: true,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
      ),
    );
  }

  PreferredSizeWidget _buildTabAppBar(ThemeData theme) {
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'Planner',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.menu_book_rounded),
          tooltip: 'Knowledge Hub',
          onPressed: () => context.push('/knowledge_hub'),
        ),
        IconButton(
          tooltip: 'Import from AI',
          icon: const Icon(Icons.auto_awesome),
          onPressed: () => PlannerAiImportDialog.show(context),
        ),
        const SizedBox(width: 8),
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
        isScrollable: true,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
      ),
    );
  }
}
