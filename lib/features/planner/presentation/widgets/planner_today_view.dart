/// Today tab view — header + timeline of today's planner items.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/planner_controller.dart';
import 'planner_empty_state.dart';
import 'planner_header_widget.dart';
import 'planner_item_card.dart';

class PlannerTodayView extends ConsumerWidget {
  const PlannerTodayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(todayPlannerItemsProvider);
    final controller = ref.read(plannerProvider.notifier);

    return CustomScrollView(
      slivers: [
        // ── Header ──
        SliverToBoxAdapter(
          child: PlannerHeaderWidget(todayItems: items),
        ),

        // ── Items or Empty State ──
        if (items.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: PlannerEmptyState(
              title: 'No plans for today.',
              subtitle: 'Add a study session, task, or deadline.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = items[index];
                  return PlannerItemCard(
                    item: item,
                    onTap: () => context.push('/planner/item/${item.id}'),
                    onComplete: () => controller.markCompleted(item.id),
                  );
                },
                childCount: items.length,
              ),
            ),
          ),
      ],
    );
  }
}
