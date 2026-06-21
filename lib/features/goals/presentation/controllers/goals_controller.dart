library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/storage/hive_local_storage.dart';
import '../../data/repositories/goal_repository_impl.dart';
import '../../domain/entities/goal_entity.dart';
import '../../domain/entities/goal_enums.dart';
import '../../domain/usecases/goal_usecases.dart';

// ── Providers ───────────────────────────────────────────────────────────────

final goalRepositoryProvider = Provider((ref) {
  final storage = HiveLocalStorage();
  return GoalRepositoryImpl(storage: storage);
});

final goalsProvider = StateNotifierProvider<GoalsController, List<GoalEntity>>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  final controller = GoalsController(repository: repository);
  controller.loadGoals();
  return controller;
});

// ── Controller ──────────────────────────────────────────────────────────────

class GoalsController extends StateNotifier<List<GoalEntity>> {
  GoalsController({required this.repository}) : super([]);

  final GoalRepositoryImpl repository;

  void loadGoals() {
    state = repository.getGoals();
  }

  Future<void> createGoal({
    required String title,
    required String description,
    required GoalHorizon horizon,
    required GoalPriority priority,
    List<GoalStepEntity> steps = const [],
    DateTime? targetDate,
  }) async {
    final useCase = CreateGoalUseCase(repository);
    await useCase(
      title: title,
      description: description,
      horizon: horizon,
      priority: priority,
      steps: steps,
      targetDate: targetDate,
    );
    loadGoals();
  }

  Future<void> updateGoal(GoalEntity goal) async {
    final useCase = UpdateGoalUseCase(repository);
    await useCase(goal);
    loadGoals();
  }

  Future<void> deleteGoal(String id) async {
    final useCase = DeleteGoalUseCase(repository);
    await useCase(id);
    loadGoals();
  }

  Future<void> markAchieved(GoalEntity goal) async {
    final useCase = MarkGoalAchievedUseCase(repository);
    await useCase(goal);
    loadGoals();
  }

  Future<void> failGoal({
    required GoalEntity goal,
    required String failureReason,
    required String lessonsLearned,
  }) async {
    final useCase = FailGoalUseCase(repository);
    await useCase(
      goal: goal,
      failureReason: failureReason,
      lessonsLearned: lessonsLearned,
    );
    loadGoals();
  }

  Future<void> retryGoal(GoalEntity failedGoal) async {
    final useCase = RetryGoalUseCase(repository);
    await useCase(failedGoal);
    loadGoals();
  }

  Future<void> toggleStep(GoalEntity goal, String stepId) async {
    final steps = goal.steps.map((s) {
      if (s.id == stepId) {
        return s.copyWith(isCompleted: !s.isCompleted);
      }
      return s;
    }).toList();
    await updateGoal(goal.copyWith(steps: steps));
  }
}
