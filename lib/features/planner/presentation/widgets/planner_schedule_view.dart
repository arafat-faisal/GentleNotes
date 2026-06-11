/// Schedule tab view — upcoming items grouped by date.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../controllers/planner_controller.dart';
import 'planner_empty_state.dart';
import 'planner_item_card.dart';

class PlannerScheduleView extends ConsumerWidget {
  const PlannerScheduleView({super.key});

  static final _groupFmt = DateFormat('EEEE, d MMMM');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(upcomingPlannerItemsProvider);
    final controller = ref.read(plannerProvider.notifier);
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return const PlannerEmptyState(
        title: 'No upcoming plans.',
        subtitle: 'Your schedule is clear. Add something!',
      );
    }

    // Group items by date.
    final grouped = <DateTime, List<dynamic>>{};
    for (final item in items) {
      final day = item.date;
      grouped.putIfAbsent(day, () => []).add(item);
    }
    final sortedDates = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final day = sortedDates[index];
        final dayItems = grouped[day]!;
        final today = DateTime.now();
        final todayDay = DateTime(today.year, today.month, today.day);
        final isToday = day == todayDay;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date group header ──
            Padding(
              padding: EdgeInsets.only(bottom: 8, top: index == 0 ? 0 : 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isToday
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isToday ? 'Today' : _groupFmt.format(day),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isToday
                            ? Colors.white
                            : theme.colorScheme.primary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Items ──
            ...dayItems.map((item) => PlannerItemCard(
                  item: item,
                  onTap: () => context.push('/planner/item/${item.id}'),
                  onComplete: () => controller.markCompleted(item.id),
                )),
          ],
        );
      },
    );
  }
}
