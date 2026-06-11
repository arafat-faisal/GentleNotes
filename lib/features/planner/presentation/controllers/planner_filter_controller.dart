/// Filter/view state for the Planner feature.
///
/// Manages the selected date, active tab index, and view-level state.
/// Kept separate from [PlannerController] (which manages data CRUD) per
/// the Controller Split Rules in .rules.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Currently selected date for week/month/day views.
final plannerSelectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Active tab index in the PlannerScreen tab bar.
/// 0 = Today, 1 = Week, 2 = Month, 3 = Schedule.
final plannerActiveTabProvider = StateProvider<int>((ref) => 0);

/// The week start (Monday) for the week view.
final plannerWeekStartProvider = Provider<DateTime>((ref) {
  final selected = ref.watch(plannerSelectedDateProvider);
  // Find Monday of the week containing [selected].
  final dayOfWeek = selected.weekday; // 1=Mon, 7=Sun
  return selected.subtract(Duration(days: dayOfWeek - 1));
});

/// Selection mode active state.
final plannerSelectionModeProvider = StateProvider<bool>((ref) => false);

/// Selected planner item IDs.
final plannerSelectedIdsProvider = StateProvider<Set<String>>((ref) => {});
