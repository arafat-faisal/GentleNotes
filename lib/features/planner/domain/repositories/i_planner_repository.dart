/// Abstract repository contract for the Planner feature.
///
/// The domain layer depends only on this interface.
/// The concrete implementation ([PlannerRepositoryImpl]) lives in the data layer.
library;

import '../entities/planner_item_entity.dart';

abstract class IPlannerRepository {
  /// Returns all planner items sorted by date ascending.
  List<PlannerItemEntity> getAll();

  /// Returns a single item by [id], or null if not found.
  PlannerItemEntity? getById(String id);

  /// Returns items whose date falls within [start]..[end] (inclusive).
  List<PlannerItemEntity> getByDateRange(DateTime start, DateTime end);

  /// Returns items whose date is today.
  List<PlannerItemEntity> getToday();

  /// Returns upcoming items (today or later), sorted by date.
  List<PlannerItemEntity> getUpcoming();

  /// Persists a new planner item.
  Future<void> create(PlannerItemEntity item);

  /// Updates an existing planner item.
  Future<void> update(PlannerItemEntity item);

  /// Deletes the planner item with the given [id].
  Future<void> delete(String id);

  /// Marks the planner item with [id] as [PlannerStatus.completed].
  Future<void> markCompleted(String id);
}
