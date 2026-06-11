/// Concrete implementation of [IPlannerRepository] backed by local Hive storage.
///
/// Bridges the domain layer's [IPlannerRepository] contract with the
/// actual data layer ([PlannerLocalDatasource]).
library;

import '../../domain/entities/planner_enums.dart';
import '../../domain/entities/planner_item_entity.dart';
import '../../domain/repositories/i_planner_repository.dart';
import '../datasources/planner_local_datasource.dart';

class PlannerRepositoryImpl implements IPlannerRepository {
  const PlannerRepositoryImpl(this._datasource);
  final PlannerLocalDatasource _datasource;

  @override
  List<PlannerItemEntity> getAll() => _datasource.getAll();

  @override
  PlannerItemEntity? getById(String id) {
    try {
      return _datasource.getAll().firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  List<PlannerItemEntity> getByDateRange(DateTime start, DateTime end) {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return _datasource.getAll().where((item) {
      final d = item.date;
      return !d.isBefore(startDay) && !d.isAfter(endDay);
    }).toList();
  }

  @override
  List<PlannerItemEntity> getToday() {
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    return _datasource.getAll().where((item) => item.date == todayDay).toList();
  }

  @override
  List<PlannerItemEntity> getUpcoming() {
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    return _datasource
        .getAll()
        .where((item) => !item.date.isBefore(todayDay))
        .toList();
  }

  @override
  Future<void> create(PlannerItemEntity item) => _datasource.save(item);

  @override
  Future<void> update(PlannerItemEntity item) => _datasource.save(item);

  @override
  Future<void> delete(String id) => _datasource.delete(id);

  @override
  Future<void> markCompleted(String id) async {
    final item = getById(id);
    if (item == null) return;
    final isCompleted = item.status == PlannerStatus.completed;
    final updated = item.copyWith(
      status: isCompleted ? PlannerStatus.upcoming : PlannerStatus.completed,
      updatedAt: DateTime.now(),
    );
    await _datasource.save(updated);
  }
}
