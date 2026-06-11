/// Pure domain entity for a planner item.
///
/// No Flutter imports — this is the domain layer and must remain UI-agnostic.
/// All persistence-specific logic lives in the data layer ([PlannerItemModel]).
library;

import 'planner_enums.dart';

class PlannerItemEntity {
  const PlannerItemEntity({
    required this.id,
    required this.title,
    this.description = '',
    required this.type,
    required this.date,
    this.startTime,
    this.endTime,
    this.isAllDay = false,
    this.reminderMinutesBefore,
    this.recurrenceFrequency = RecurrenceFrequency.none,
    this.linkedNoteId,
    this.locationOrLink = '',
    this.colorHex = '#8B5CF6',
    this.priority = PlannerPriority.medium,
    this.status = PlannerStatus.upcoming,
    this.rescheduleReason = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final PlannerItemType type;

  /// The calendar date this item belongs to (time-of-day ignored here).
  final DateTime date;

  /// Optional start time (stored as minutes from midnight, e.g. 9*60 = 09:00).
  final int? startTime;

  /// Optional end time (stored as minutes from midnight).
  final int? endTime;

  final bool isAllDay;

  /// How many minutes before the event to fire the local notification.
  /// Null means no reminder.
  final int? reminderMinutesBefore;

  final RecurrenceFrequency recurrenceFrequency;

  /// ID of a [NoteModel] linked to this planner item.
  final String? linkedNoteId;

  final String locationOrLink;
  final String colorHex;
  final PlannerPriority priority;
  final PlannerStatus status;
  final String rescheduleReason;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCompleted => status == PlannerStatus.completed;
  bool get hasReminder  => reminderMinutesBefore != null;
  bool get isRecurring  => recurrenceFrequency != RecurrenceFrequency.none;

  PlannerItemEntity copyWith({
    String? title,
    String? description,
    PlannerItemType? type,
    DateTime? date,
    int? startTime,
    int? endTime,
    bool? isAllDay,
    int? reminderMinutesBefore,
    bool clearReminder = false,
    RecurrenceFrequency? recurrenceFrequency,
    String? linkedNoteId,
    bool clearLinkedNote = false,
    String? locationOrLink,
    String? colorHex,
    PlannerPriority? priority,
    PlannerStatus? status,
    String? rescheduleReason,
    DateTime? updatedAt,
  }) {
    return PlannerItemEntity(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      reminderMinutesBefore:
          clearReminder ? null : (reminderMinutesBefore ?? this.reminderMinutesBefore),
      recurrenceFrequency: recurrenceFrequency ?? this.recurrenceFrequency,
      linkedNoteId: clearLinkedNote ? null : (linkedNoteId ?? this.linkedNoteId),
      locationOrLink: locationOrLink ?? this.locationOrLink,
      colorHex: colorHex ?? this.colorHex,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      rescheduleReason: rescheduleReason ?? this.rescheduleReason,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
