/// Use case: Create a new planner item with validation.
library;

import 'package:uuid/uuid.dart';
import '../entities/planner_enums.dart';
import '../entities/planner_item_entity.dart';
import '../repositories/i_planner_repository.dart';

class CreatePlannerItemUseCase {
  const CreatePlannerItemUseCase(this._repository);
  final IPlannerRepository _repository;

  /// Validates inputs and persists a new [PlannerItemEntity].
  ///
  /// Throws [ArgumentError] if:
  /// - [title] is empty.
  /// - [endTime] is before [startTime] when both are provided.
  Future<PlannerItemEntity> call({
    required String title,
    String description = '',
    required PlannerItemType type,
    required DateTime date,
    int? startTime,
    int? endTime,
    bool isAllDay = false,
    int? reminderMinutesBefore,
    RecurrenceFrequency recurrenceFrequency = RecurrenceFrequency.none,
    String? linkedNoteId,
    String? linkedGoalId,
    String locationOrLink = '',
    String colorHex = '#8B5CF6',
    PlannerPriority priority = PlannerPriority.medium,
  }) async {
    if (title.trim().isEmpty) {
      throw ArgumentError('Planner item title must not be empty.');
    }
    if (startTime != null && endTime != null && endTime < startTime) {
      throw ArgumentError('End time must be after start time.');
    }

    final now = DateTime.now();
    final item = PlannerItemEntity(
      id: const Uuid().v4(),
      title: title.trim(),
      description: description.trim(),
      type: type,
      date: DateTime(date.year, date.month, date.day),
      startTime: startTime,
      endTime: endTime,
      isAllDay: isAllDay,
      reminderMinutesBefore: reminderMinutesBefore,
      recurrenceFrequency: recurrenceFrequency,
      linkedNoteId: linkedNoteId,
      linkedGoalId: linkedGoalId,
      locationOrLink: locationOrLink.trim(),
      colorHex: colorHex,
      priority: priority,
      status: PlannerStatus.upcoming,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.create(item);
    return item;
  }
}
