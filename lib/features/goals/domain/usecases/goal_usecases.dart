library;

import 'package:uuid/uuid.dart';

import '../entities/goal_entity.dart';
import '../entities/goal_enums.dart';
import '../repositories/goal_repository.dart';

class CreateGoalUseCase {
  final GoalRepository repository;

  CreateGoalUseCase(this.repository);

  Future<void> call({
    required String title,
    required String description,
    required GoalHorizon horizon,
    required GoalPriority priority,
    List<GoalStepEntity> steps = const [],
    DateTime? targetDate,
  }) async {
    final goal = GoalEntity(
      id: const Uuid().v4(),
      title: title,
      description: description,
      horizon: horizon,
      priority: priority,
      steps: steps,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      targetDate: targetDate,
    );
    await repository.saveGoal(goal);
  }
}

class UpdateGoalUseCase {
  final GoalRepository repository;

  UpdateGoalUseCase(this.repository);

  Future<void> call(GoalEntity goal) async {
    final updated = goal.copyWith(updatedAt: DateTime.now());
    await repository.saveGoal(updated);
  }
}

class DeleteGoalUseCase {
  final GoalRepository repository;

  DeleteGoalUseCase(this.repository);

  Future<void> call(String id) async {
    await repository.deleteGoal(id);
  }
}

class MarkGoalAchievedUseCase {
  final GoalRepository repository;

  MarkGoalAchievedUseCase(this.repository);

  Future<void> call(GoalEntity goal) async {
    final updated = goal.copyWith(
      status: GoalStatus.achieved,
      updatedAt: DateTime.now(),
    );
    await repository.saveGoal(updated);
  }
}

class FailGoalUseCase {
  final GoalRepository repository;

  FailGoalUseCase(this.repository);

  Future<void> call({
    required GoalEntity goal,
    required String failureReason,
    required String lessonsLearned,
  }) async {
    final updated = goal.copyWith(
      status: GoalStatus.failed,
      failureReason: failureReason,
      lessonsLearned: lessonsLearned,
      updatedAt: DateTime.now(),
    );
    await repository.saveGoal(updated);
  }
}

class RetryGoalUseCase {
  final GoalRepository repository;

  RetryGoalUseCase(this.repository);

  Future<void> call(GoalEntity failedGoal) async {
    // 1. Mark the old one as retried
    final updatedOld = failedGoal.copyWith(
      status: GoalStatus.retried,
      updatedAt: DateTime.now(),
    );
    await repository.saveGoal(updatedOld);

    // 2. Create a new active clone
    final newGoal = GoalEntity(
      id: const Uuid().v4(),
      title: failedGoal.title,
      description: failedGoal.description,
      horizon: failedGoal.horizon,
      status: GoalStatus.active,
      priority: failedGoal.priority,
      // reset steps
      steps: failedGoal.steps.map((s) => s.copyWith(isCompleted: false)).toList(),
      retryOfGoalId: failedGoal.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      targetDate: failedGoal.targetDate, // maybe shift this if needed, but keeping same for now
    );
    await repository.saveGoal(newGoal);
  }
}
