import 'package:hive_flutter/hive_flutter.dart';
import '../../../features/goals/data/models/goal_model.dart';
import '../../../features/goals/domain/entities/goal_entity.dart';

class GoalsStorage {
  const GoalsStorage({required Box goalsBox}) : _box = goalsBox;

  final Box _box;

  List<GoalEntity> getGoals() {
    final items = <GoalEntity>[];
    for (final key in _box.keys) {
      final val = _box.get(key);
      if (val is Map) {
        try {
          final model = GoalModel.fromMap(Map<String, dynamic>.from(val));
          items.add(model.toEntity());
        } catch (_) {
          // Skip corrupted entries silently.
        }
      }
    }
    // Sort by created at descending
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> saveGoal(GoalEntity goal) async {
    final model = GoalModel.fromEntity(goal);
    await _box.put(goal.id, model.toMap());
  }

  Future<void> deleteGoal(String id) async {
    await _box.delete(id);
  }
}
