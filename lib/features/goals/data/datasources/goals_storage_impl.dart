import 'package:hive/hive.dart';
import '../../domain/entities/goal_entity.dart';
import '../models/goal_model.dart';
import 'i_goals_storage.dart';

class GoalsStorageImpl implements IGoalsStorage {
  final Box _box;

  GoalsStorageImpl(this._box);

  @override
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

  @override
  Future<void> saveGoal(GoalEntity goal) async {
    final model = GoalModel.fromEntity(goal);
    await _box.put(goal.id, model.toMap());
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> updateGoal(GoalEntity goal) async {
    await saveGoal(goal);
  }
}
