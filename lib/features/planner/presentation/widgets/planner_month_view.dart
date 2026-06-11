/// Month tab view — calendar grid with dot indicators + selected-day agenda.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../controllers/planner_controller.dart';
import '../controllers/planner_filter_controller.dart';
import 'planner_empty_state.dart';
import 'planner_item_card.dart';

class PlannerMonthView extends ConsumerWidget {
  const PlannerMonthView({super.key});

  static final _monthFmt = DateFormat('MMMM yyyy');
  static final _dayFmt = DateFormat('EEEE, d MMMM');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(plannerSelectedDateProvider);
    final allItems = ref.watch(plannerProvider).items;
    final controller = ref.read(plannerProvider.notifier);
    final theme = Theme.of(context);

    final monthStart = DateTime(selected.year, selected.month, 1);
    final monthEnd = DateTime(selected.year, selected.month + 1, 0);
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);

    final dayItems = allItems
        .where((i) => i.date == selected)
        .toList()
      ..sort((a, b) => (a.startTime ?? 0).compareTo(b.startTime ?? 0));

    return Column(
      children: [
        // ── Month navigation ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () {
                  final prev = DateTime(selected.year, selected.month - 1, 1);
                  ref.read(plannerSelectedDateProvider.notifier).state = prev;
                },
              ),
              Expanded(
                child: Text(
                  _monthFmt.format(selected),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () {
                  final next = DateTime(selected.year, selected.month + 1, 1);
                  ref.read(plannerSelectedDateProvider.notifier).state = next;
                },
              ),
            ],
          ),
        ),

        // ── Calendar grid ──
        _CalendarGrid(
          monthStart: monthStart,
          monthEnd: monthEnd,
          selected: selected,
          todayDay: todayDay,
          allItems: allItems,
          onDayTap: (day) =>
              ref.read(plannerSelectedDateProvider.notifier).state = day,
        ),

        const Divider(height: 1),

        // ── Selected day agenda ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _dayFmt.format(selected),
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),

        Expanded(
          child: dayItems.isEmpty
              ? PlannerEmptyState(
                  title: 'No plans for this day.',
                  subtitle: 'Tap + to add something.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: dayItems.length,
                  itemBuilder: (context, index) {
                    final item = dayItems[index];
                    return PlannerItemCard(
                      item: item,
                      onTap: () => context.push('/planner/item/${item.id}'),
                      onComplete: () => controller.markCompleted(item.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.monthStart,
    required this.monthEnd,
    required this.selected,
    required this.todayDay,
    required this.allItems,
    required this.onDayTap,
  });

  final DateTime monthStart;
  final DateTime monthEnd;
  final DateTime selected;
  final DateTime todayDay;
  final List<dynamic> allItems;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startOffset = monthStart.weekday - 1; // 0=Mon offset
    final daysInMonth = monthEnd.day;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          // Day-of-week headers
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          ...List.generate(rows, (row) {
            return Row(
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                final dayNum = cellIndex - startOffset + 1;
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 40));
                }
                final day = DateTime(monthStart.year, monthStart.month, dayNum);
                final isSelected = day == selected;
                final isToday = day == todayDay;
                final hasItems = allItems.any((i) => (i as dynamic).date == day);

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onDayTap(day),
                    child: Container(
                      height: 40,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : isToday
                                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNum',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.normal,
                              color: isSelected ? Colors.white : null,
                            ),
                          ),
                          if (hasItems)
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(top: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }
}
