/// Week tab view — 7-day columns grouped by day.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../controllers/planner_controller.dart';
import '../controllers/planner_filter_controller.dart';
import 'planner_empty_state.dart';
import 'planner_item_tile.dart';

class PlannerWeekView extends ConsumerWidget {
  const PlannerWeekView({super.key});

  static final _dayHeaderFmt = DateFormat('EEE d');
  static final _monthFmt = DateFormat('MMMM yyyy');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(plannerWeekStartProvider);
    final allItems = ref.watch(plannerProvider).items;
    final controller = ref.read(plannerProvider.notifier);
    final theme = Theme.of(context);
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);

    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final weekEnd = weekDays.last;

    final weekItems = allItems.where((item) {
      return !item.date.isBefore(weekStart) && !item.date.isAfter(weekEnd);
    }).toList();

    return Column(
      children: [
        // ── Week navigation header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => ref
                    .read(plannerSelectedDateProvider.notifier)
                    .state = weekStart.subtract(const Duration(days: 7)),
              ),
              Expanded(
                child: Text(
                  _monthFmt.format(weekStart),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => ref
                    .read(plannerSelectedDateProvider.notifier)
                    .state = weekStart.add(const Duration(days: 7)),
              ),
            ],
          ),
        ),

        // ── Content ──
        if (weekItems.isEmpty)
          const Expanded(
            child: PlannerEmptyState(
              title: 'Nothing planned this week.',
              subtitle: 'Tap + to add a study session or task.',
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              itemCount: weekDays.length,
              itemBuilder: (context, index) {
                final day = weekDays[index];
                final dayItems = weekItems
                    .where((i) => i.date == day)
                    .toList()
                  ..sort((a, b) => (a.startTime ?? 0).compareTo(b.startTime ?? 0));

                if (dayItems.isEmpty) return const SizedBox.shrink();
                final isToday = day == todayDay;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _DayHeader(day: day, isToday: isToday, label: _dayHeaderFmt.format(day)),
                    const SizedBox(height: 4),
                    ...dayItems.map((item) => PlannerItemTile(
                          item: item,
                          onTap: () => context.push('/planner/item/${item.id}'),
                          onComplete: () => controller.markCompleted(item.id),
                        )),
                    Divider(height: 16, color: theme.dividerColor),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.isToday, required this.label});

  final DateTime day;
  final bool isToday;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (isToday)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          )
        else
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2),
          ),
      ],
    );
  }
}
