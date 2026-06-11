/// Local data source for planner operations.
///
/// Wraps [ILocalStorage] and translates raw storage calls into typed
/// [PlannerItemEntity] operations. No business logic lives here.
library;

import '../../../../core/services/storage/i_local_storage.dart';
import '../../domain/entities/planner_item_entity.dart';

class PlannerLocalDatasource {
  const PlannerLocalDatasource(this._storage);
  final ILocalStorage _storage;

  List<PlannerItemEntity> getAll() => _storage.getPlannerItems();

  Future<void> save(PlannerItemEntity item) => _storage.savePlannerItem(item);

  Future<void> delete(String id) => _storage.deletePlannerItem(id);
}
