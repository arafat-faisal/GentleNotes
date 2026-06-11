/// Use case: Delete a planner item by ID.
library;

import '../repositories/i_planner_repository.dart';

class DeletePlannerItemUseCase {
  const DeletePlannerItemUseCase(this._repository);
  final IPlannerRepository _repository;

  Future<void> call(String id) => _repository.delete(id);
}
