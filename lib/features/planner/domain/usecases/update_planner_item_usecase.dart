/// Use case: Update an existing planner item.
library;

import '../entities/planner_item_entity.dart';
import '../repositories/i_planner_repository.dart';

class UpdatePlannerItemUseCase {
  const UpdatePlannerItemUseCase(this._repository);
  final IPlannerRepository _repository;

  /// Validates and persists updated item.
  ///
  /// Throws [ArgumentError] if title is empty or time range is invalid.
  Future<void> call(PlannerItemEntity item) async {
    if (item.title.trim().isEmpty) {
      throw ArgumentError('Planner item title must not be empty.');
    }
    if (item.startTime != null &&
        item.endTime != null &&
        item.endTime! < item.startTime!) {
      throw ArgumentError('End time must be after start time.');
    }
    final updated = item.copyWith(updatedAt: DateTime.now());
    await _repository.update(updated);
  }
}
