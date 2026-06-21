library;

import '../entities/goal_entity.dart';

abstract class GoalRepository {
  List<GoalEntity> getGoals();
  Future<void> saveGoal(GoalEntity goal);
  Future<void> deleteGoal(String id);
}
