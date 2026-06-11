/// Use case: Retrieve planner items with various filters.
library;

import '../entities/planner_item_entity.dart';
import '../repositories/i_planner_repository.dart';

class GetPlannerItemsUseCase {
  const GetPlannerItemsUseCase(this._repository);
  final IPlannerRepository _repository;

  /// Returns all items sorted by date.
  List<PlannerItemEntity> getAll() => _repository.getAll();

  /// Returns items for today.
  List<PlannerItemEntity> getToday() => _repository.getToday();

  /// Returns items within [start]..[end] inclusive.
  List<PlannerItemEntity> getByDateRange(DateTime start, DateTime end) =>
      _repository.getByDateRange(start, end);

  /// Returns upcoming items (today or later).
  List<PlannerItemEntity> getUpcoming() => _repository.getUpcoming();

  /// Returns a single item by ID, or null.
  PlannerItemEntity? getById(String id) => _repository.getById(id);
}
