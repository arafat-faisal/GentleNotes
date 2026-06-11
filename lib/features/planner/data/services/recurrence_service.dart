/// Generates planner item occurrences for a given date range.
///
/// Feature-specific service — lives in the planner feature's data layer.
/// No UI dependencies.
library;

import '../../domain/entities/planner_enums.dart';
import '../../domain/entities/planner_item_entity.dart';

class RecurrenceService {
  const RecurrenceService();

  /// Generates a flat list of [PlannerItemEntity] occurrences for [item]
  /// within [rangeStart]..[rangeEnd] (inclusive, date only).
  ///
  /// For non-recurring items, returns [item] itself if its date is in range.
  /// For recurring items, generates virtual occurrences (they share the same
  /// [id] with a synthetic date override — do not persist these).
  List<PlannerItemEntity> expand({
    required PlannerItemEntity item,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final start = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
    final end = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);

    if (item.recurrenceFrequency == RecurrenceFrequency.none) {
      if (!item.date.isBefore(start) && !item.date.isAfter(end)) {
        return [item];
      }
      return [];
    }

    final results = <PlannerItemEntity>[];
    var i = 0;
    while (true) {
      final occurrenceDate = _getOccurrence(item.date, item.recurrenceFrequency, i);
      if (occurrenceDate.isAfter(end)) break;
      if (!occurrenceDate.isBefore(start)) {
        results.add(item.copyWith(date: occurrenceDate));
      }
      i++;
    }

    return results;
  }

  DateTime _getOccurrence(DateTime base, RecurrenceFrequency freq, int index) {
    switch (freq) {
      case RecurrenceFrequency.daily:
        return base.add(Duration(days: index));
      case RecurrenceFrequency.weekly:
        return base.add(Duration(days: 7 * index));
      case RecurrenceFrequency.monthly:
        final targetMonth = base.month + index;
        final yearOffset = (targetMonth - 1) ~/ 12;
        final month = (targetMonth - 1) % 12 + 1;
        final year = base.year + yearOffset;
        final maxDay = _daysInMonth(year, month);
        return DateTime(year, month, base.day.clamp(1, maxDay));
      case RecurrenceFrequency.none:
        return base;
    }
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}
