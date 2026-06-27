import '../../domain/entities/goal_entity.dart';

abstract class IGoalsStorage {
  List<GoalEntity> getGoals();
  Future<void> saveGoal(GoalEntity goal);
  Future<void> deleteGoal(String id);
  Future<void> updateGoal(GoalEntity goal);
}
