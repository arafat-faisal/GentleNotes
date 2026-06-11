import 'package:flutter_test/flutter_test.dart';
import 'package:gentle_notes/features/planner/data/models/planner_item_model.dart';
import 'package:gentle_notes/features/planner/domain/entities/planner_enums.dart';
import 'package:gentle_notes/features/planner/domain/entities/planner_item_entity.dart';

void main() {
  group('PlannerItemModel Tests', () {
    final now = DateTime.utc(2026, 6, 11, 12, 0, 0);
    final entity = PlannerItemEntity(
      id: 'test-id-123',
      title: 'Plan Title',
      description: 'Plan Description',
      type: PlannerItemType.studySession,
      date: DateTime.utc(2026, 6, 15),
      startTime: 540, // 09:00
      endTime: 600,   // 10:00
      isAllDay: false,
      reminderMinutesBefore: 15,
      recurrenceFrequency: RecurrenceFrequency.weekly,
      linkedNoteId: 'note-abc',
      locationOrLink: 'https://example.com',
      colorHex: '#FF5733',
      priority: PlannerPriority.high,
      status: PlannerStatus.upcoming,
      rescheduleReason: 'Felt tired',
      createdAt: now,
      updatedAt: now,
    );

    test('should convert from Entity to Model and back to Entity correctly', () {
      final model = PlannerItemModel.fromEntity(entity);
      expect(model.id, 'test-id-123');
      expect(model.title, 'Plan Title');
      expect(model.description, 'Plan Description');
      expect(model.type, PlannerItemType.studySession);
      expect(model.date, DateTime.utc(2026, 6, 15));
      expect(model.startTime, 540);
      expect(model.endTime, 600);
      expect(model.isAllDay, false);
      expect(model.reminderMinutesBefore, 15);
      expect(model.recurrenceFrequency, RecurrenceFrequency.weekly);
      expect(model.linkedNoteId, 'note-abc');
      expect(model.locationOrLink, 'https://example.com');
      expect(model.colorHex, '#FF5733');
      expect(model.priority, PlannerPriority.high);
      expect(model.status, PlannerStatus.upcoming);
      expect(model.rescheduleReason, 'Felt tired');
      expect(model.createdAt, now);
      expect(model.updatedAt, now);

      final convertedEntity = model.toEntity();
      expect(convertedEntity.id, entity.id);
      expect(convertedEntity.title, entity.title);
      expect(convertedEntity.description, entity.description);
      expect(convertedEntity.type, entity.type);
      expect(convertedEntity.date, entity.date);
      expect(convertedEntity.startTime, entity.startTime);
      expect(convertedEntity.endTime, entity.endTime);
      expect(convertedEntity.isAllDay, entity.isAllDay);
      expect(convertedEntity.reminderMinutesBefore, entity.reminderMinutesBefore);
      expect(convertedEntity.recurrenceFrequency, entity.recurrenceFrequency);
      expect(convertedEntity.linkedNoteId, entity.linkedNoteId);
      expect(convertedEntity.locationOrLink, entity.locationOrLink);
      expect(convertedEntity.colorHex, entity.colorHex);
      expect(convertedEntity.priority, entity.priority);
      expect(convertedEntity.status, entity.status);
      expect(convertedEntity.rescheduleReason, entity.rescheduleReason);
      expect(convertedEntity.createdAt, entity.createdAt);
      expect(convertedEntity.updatedAt, entity.updatedAt);
    });

    test('should serialize toMap and deserialize fromMap correctly', () {
      final model = PlannerItemModel.fromEntity(entity);
      final map = model.toMap();

      expect(map['id'], 'test-id-123');
      expect(map['title'], 'Plan Title');
      expect(map['type'], 'studySession');
      expect(map['isAllDay'], 0);
      expect(map['priority'], 'high');
      expect(map['recurrenceFrequency'], 'weekly');
      expect(map['rescheduleReason'], 'Felt tired');

      final deserialized = PlannerItemModel.fromMap(map);
      expect(deserialized.id, model.id);
      expect(deserialized.title, model.title);
      expect(deserialized.description, model.description);
      expect(deserialized.type, model.type);
      expect(deserialized.date, model.date);
      expect(deserialized.startTime, model.startTime);
      expect(deserialized.endTime, model.endTime);
      expect(deserialized.isAllDay, model.isAllDay);
      expect(deserialized.reminderMinutesBefore, model.reminderMinutesBefore);
      expect(deserialized.recurrenceFrequency, model.recurrenceFrequency);
      expect(deserialized.linkedNoteId, model.linkedNoteId);
      expect(deserialized.locationOrLink, model.locationOrLink);
      expect(deserialized.colorHex, model.colorHex);
      expect(deserialized.priority, model.priority);
      expect(deserialized.status, model.status);
      expect(deserialized.rescheduleReason, model.rescheduleReason);
      expect(deserialized.createdAt, model.createdAt);
      expect(deserialized.updatedAt, model.updatedAt);
    });

    test('should fallback to empty string when rescheduleReason is missing in map (backwards compatibility)', () {
      final oldMap = {
        'id': 'test-id-123',
        'title': 'Plan Title',
        'description': 'Plan Description',
        'type': 'studySession',
        'date': DateTime.utc(2026, 6, 15).toIso8601String(),
        'startTime': 540,
        'endTime': 600,
        'isAllDay': 0,
        'reminderMinutesBefore': 15,
        'recurrenceFrequency': 'weekly',
        'linkedNoteId': 'note-abc',
        'locationOrLink': 'https://example.com',
        'colorHex': '#FF5733',
        'priority': 'high',
        'status': 'upcoming',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      final deserialized = PlannerItemModel.fromMap(oldMap);
      expect(deserialized.rescheduleReason, '');
    });
  });
}
