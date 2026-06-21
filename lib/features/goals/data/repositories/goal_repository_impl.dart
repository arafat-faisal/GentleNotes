library;

import '../../../../core/services/storage/i_local_storage.dart';
import '../../domain/entities/goal_entity.dart';
import '../../domain/repositories/goal_repository.dart';

class GoalRepositoryImpl implements GoalRepository {
  final ILocalStorage storage;

  GoalRepositoryImpl({required this.storage});

  @override
  List<GoalEntity> getGoals() {
    return storage.getGoals();
  }

  @override
  Future<void> saveGoal(GoalEntity goal) {
    return storage.saveGoal(goal);
  }

  @override
  Future<void> deleteGoal(String id) {
    return storage.deleteGoal(id);
  }
}
