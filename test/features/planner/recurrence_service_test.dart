import 'package:flutter_test/flutter_test.dart';
import 'package:gentle_notes/features/planner/data/services/recurrence_service.dart';
import 'package:gentle_notes/features/planner/domain/entities/planner_enums.dart';
import 'package:gentle_notes/features/planner/domain/entities/planner_item_entity.dart';

void main() {
  group('RecurrenceService Tests', () {
    const service = RecurrenceService();
    final baseDate = DateTime(2026, 6, 1);
    final now = DateTime.now();

    final baseItem = PlannerItemEntity(
      id: 'test-id',
      title: 'Workout',
      type: PlannerItemType.habit,
      date: baseDate,
      createdAt: now,
      updatedAt: now,
    );

    test('should return single item for RecurrenceFrequency.none in range', () {
      final results = service.expand(
        item: baseItem,
        rangeStart: DateTime(2026, 6, 1),
        rangeEnd: DateTime(2026, 6, 10),
      );
      expect(results.length, 1);
      expect(results[0].date, baseDate);
    });

    test('should return empty list for RecurrenceFrequency.none out of range', () {
      final results = service.expand(
        item: baseItem,
        rangeStart: DateTime(2026, 6, 2),
        rangeEnd: DateTime(2026, 6, 10),
      );
      expect(results, isEmpty);
    });

    test('should expand daily recurrence correctly', () {
      final dailyItem = baseItem.copyWith(recurrenceFrequency: RecurrenceFrequency.daily);
      final results = service.expand(
        item: dailyItem,
        rangeStart: DateTime(2026, 6, 1),
        rangeEnd: DateTime(2026, 6, 5),
      );
      expect(results.length, 5);
      expect(results[0].date, DateTime(2026, 6, 1));
      expect(results[1].date, DateTime(2026, 6, 2));
      expect(results[2].date, DateTime(2026, 6, 3));
      expect(results[3].date, DateTime(2026, 6, 4));
      expect(results[4].date, DateTime(2026, 6, 5));
    });

    test('should expand weekly recurrence correctly', () {
      final weeklyItem = baseItem.copyWith(recurrenceFrequency: RecurrenceFrequency.weekly);
      final results = service.expand(
        item: weeklyItem,
        rangeStart: DateTime(2026, 5, 20),
        rangeEnd: DateTime(2026, 6, 20),
      );
      // Item is on June 1. Weekly occurrences in range: June 1, June 8, June 15.
      expect(results.length, 3);
      expect(results[0].date, DateTime(2026, 6, 1));
      expect(results[1].date, DateTime(2026, 6, 8));
      expect(results[2].date, DateTime(2026, 6, 15));
    });

    test('should expand monthly recurrence correctly and handle end-of-month clamp', () {
      // Setup an event on 31st of Jan.
      final monthlyItem = baseItem.copyWith(
        date: DateTime(2026, 1, 31),
        recurrenceFrequency: RecurrenceFrequency.monthly,
      );

      final results = service.expand(
        item: monthlyItem,
        rangeStart: DateTime(2026, 1, 1),
        rangeEnd: DateTime(2026, 4, 30),
      );

      // Expected dates:
      // Jan 31
      // Feb 28 (clamped from 31)
      // Mar 31
      // Apr 30 (clamped from 31)
      expect(results.length, 4);
      expect(results[0].date, DateTime(2026, 1, 31));
      expect(results[1].date, DateTime(2026, 2, 28));
      expect(results[2].date, DateTime(2026, 3, 31));
      expect(results[3].date, DateTime(2026, 4, 30));
    });
  });
}
