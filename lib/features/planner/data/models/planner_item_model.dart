/// Data model for a planner item.
///
/// Handles serialization (toMap/fromMap) for Hive storage.
/// Converts to/from the domain [PlannerItemEntity].
library;

import '../../domain/entities/planner_enums.dart';
import '../../domain/entities/planner_item_entity.dart';

class PlannerItemModel {
  const PlannerItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.date,
    this.startTime,
    this.endTime,
    required this.isAllDay,
    this.reminderMinutesBefore,
    required this.recurrenceFrequency,
    this.linkedNoteId,
    this.linkedGoalId,
    required this.locationOrLink,
    required this.colorHex,
    required this.priority,
    required this.status,
    required this.rescheduleReason,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final PlannerItemType type;
  final DateTime date;
  final int? startTime;
  final int? endTime;
  final bool isAllDay;
  final int? reminderMinutesBefore;
  final RecurrenceFrequency recurrenceFrequency;
  final String? linkedNoteId;
  final String? linkedGoalId;
  final String locationOrLink;
  final String colorHex;
  final PlannerPriority priority;
  final PlannerStatus status;
  final String rescheduleReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Serialization ────────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'isAllDay': isAllDay ? 1 : 0,
      'reminderMinutesBefore': reminderMinutesBefore,
      'recurrenceFrequency': recurrenceFrequency.name,
      'linkedNoteId': linkedNoteId,
      'linkedGoalId': linkedGoalId,
      'locationOrLink': locationOrLink,
      'colorHex': colorHex,
      'priority': priority.name,
      'status': status.name,
      'rescheduleReason': rescheduleReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PlannerItemModel.fromMap(Map<String, dynamic> map) {
    return PlannerItemModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      type: PlannerItemType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PlannerItemType.task,
      ),
      date: DateTime.parse(map['date'] as String),
      startTime: map['startTime'] as int?,
      endTime: map['endTime'] as int?,
      isAllDay: (map['isAllDay'] == 1 || map['isAllDay'] == true),
      reminderMinutesBefore: map['reminderMinutesBefore'] as int?,
      recurrenceFrequency: RecurrenceFrequency.values.firstWhere(
        (e) => e.name == map['recurrenceFrequency'],
        orElse: () => RecurrenceFrequency.none,
      ),
      linkedNoteId: map['linkedNoteId'] as String?,
      linkedGoalId: map['linkedGoalId'] as String?,
      locationOrLink: map['locationOrLink'] as String? ?? '',
      colorHex: map['colorHex'] as String? ?? '#8B5CF6',
      priority: PlannerPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => PlannerPriority.medium,
      ),
      status: PlannerStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PlannerStatus.upcoming,
      ),
      rescheduleReason: map['rescheduleReason'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // ── Entity Conversion ────────────────────────────────────────────────────────

  PlannerItemEntity toEntity() {
    return PlannerItemEntity(
      id: id,
      title: title,
      description: description,
      type: type,
      date: date,
      startTime: startTime,
      endTime: endTime,
      isAllDay: isAllDay,
      reminderMinutesBefore: reminderMinutesBefore,
      recurrenceFrequency: recurrenceFrequency,
      linkedNoteId: linkedNoteId,
      linkedGoalId: linkedGoalId,
      locationOrLink: locationOrLink,
      colorHex: colorHex,
      priority: priority,
      status: status,
      rescheduleReason: rescheduleReason,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory PlannerItemModel.fromEntity(PlannerItemEntity entity) {
    return PlannerItemModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      type: entity.type,
      date: entity.date,
      startTime: entity.startTime,
      endTime: entity.endTime,
      isAllDay: entity.isAllDay,
      reminderMinutesBefore: entity.reminderMinutesBefore,
      recurrenceFrequency: entity.recurrenceFrequency,
      linkedNoteId: entity.linkedNoteId,
      linkedGoalId: entity.linkedGoalId,
      locationOrLink: entity.locationOrLink,
      colorHex: entity.colorHex,
      priority: entity.priority,
      status: entity.status,
      rescheduleReason: entity.rescheduleReason,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
