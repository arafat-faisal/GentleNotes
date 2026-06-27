library;

import '../../domain/entities/goal_enums.dart';
import '../../domain/entities/goal_entity.dart';

class GoalStepModel {
  const GoalStepModel({
    required this.id,
    required this.title,
    required this.isCompleted,
  });

  final String id;
  final String title;
  final bool isCompleted;

  factory GoalStepModel.fromMap(Map<String, dynamic> map) {
    return GoalStepModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  factory GoalStepModel.fromEntity(GoalStepEntity entity) {
    return GoalStepModel(
      id: entity.id,
      title: entity.title,
      isCompleted: entity.isCompleted,
    );
  }

  GoalStepEntity toEntity() {
    return GoalStepEntity(
      id: id,
      title: title,
      isCompleted: isCompleted,
    );
  }
}

class GoalModel {
  const GoalModel({
    required this.id,
    required this.title,
    required this.description,
    required this.horizon,
    required this.status,
    required this.priority,
    required this.steps,
    required this.failureReason,
    required this.lessonsLearned,
    required this.relatedNoteIds,
    required this.relatedPlannerItemIds,
    required this.createdAt,
    required this.updatedAt,
    this.targetDate,
    this.retryOfGoalId,
  });

  final String id;
  final String title;
  final String description;
  final String horizon;
  final String status;
  final String priority;
  final List<GoalStepModel> steps;
  final String failureReason;
  final String lessonsLearned;
  final List<String> relatedNoteIds;
  final List<String> relatedPlannerItemIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? targetDate;
  final String? retryOfGoalId;

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    final stepsRaw = map['steps'];
    final List<GoalStepModel> parsedSteps = [];
    if (stepsRaw is List) {
      for (final element in stepsRaw) {
        if (element is Map) {
          try {
            final stepMap = Map<String, dynamic>.from(element);
            parsedSteps.add(GoalStepModel.fromMap(stepMap));
          } catch (_) {
            // Silently filter out malformed steps
          }
        }
      }
    }

    final rawNoteIds = map['relatedNoteIds'];
    final List<String> relatedNoteIds = [];
    if (rawNoteIds is List) {
      for (final id in rawNoteIds) {
        if (id != null) {
          relatedNoteIds.add(id.toString());
        }
      }
    }

    final rawPlannerIds = map['relatedPlannerItemIds'];
    final List<String> relatedPlannerItemIds = [];
    if (rawPlannerIds is List) {
      for (final id in rawPlannerIds) {
        if (id != null) {
          relatedPlannerItemIds.add(id.toString());
        }
      }
    }

    DateTime createdAt;
    try {
      createdAt = map['createdAt'] != null
          ? DateTime.parse(map['createdAt'].toString())
          : DateTime.now();
    } catch (_) {
      createdAt = DateTime.now();
    }

    DateTime updatedAt;
    try {
      updatedAt = map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'].toString())
          : DateTime.now();
    } catch (_) {
      updatedAt = DateTime.now();
    }

    DateTime? targetDate;
    if (map['targetDate'] != null) {
      try {
        targetDate = DateTime.parse(map['targetDate'].toString());
      } catch (_) {}
    }

    return GoalModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      horizon: map['horizon']?.toString() ?? GoalHorizon.weekly.name,
      status: map['status']?.toString() ?? GoalStatus.active.name,
      priority: map['priority']?.toString() ?? GoalPriority.medium.name,
      steps: parsedSteps,
      failureReason: map['failureReason']?.toString() ?? '',
      lessonsLearned: map['lessonsLearned']?.toString() ?? '',
      relatedNoteIds: relatedNoteIds,
      relatedPlannerItemIds: relatedPlannerItemIds,
      createdAt: createdAt,
      updatedAt: updatedAt,
      targetDate: targetDate,
      retryOfGoalId: map['retryOfGoalId']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'horizon': horizon,
      'status': status,
      'priority': priority,
      'steps': steps.map((s) => s.toMap()).toList(),
      'failureReason': failureReason,
      'lessonsLearned': lessonsLearned,
      'relatedNoteIds': relatedNoteIds,
      'relatedPlannerItemIds': relatedPlannerItemIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'targetDate': targetDate?.toIso8601String(),
      'retryOfGoalId': retryOfGoalId,
    };
  }

  factory GoalModel.fromEntity(GoalEntity entity) {
    return GoalModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      horizon: entity.horizon.name,
      status: entity.status.name,
      priority: entity.priority.name,
      steps: entity.steps.map((s) => GoalStepModel.fromEntity(s)).toList(),
      failureReason: entity.failureReason,
      lessonsLearned: entity.lessonsLearned,
      relatedNoteIds: entity.relatedNoteIds,
      relatedPlannerItemIds: entity.relatedPlannerItemIds,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      targetDate: entity.targetDate,
      retryOfGoalId: entity.retryOfGoalId,
    );
  }

  GoalEntity toEntity() {
    return GoalEntity(
      id: id,
      title: title,
      description: description,
      horizon: GoalHorizon.values.firstWhere((e) => e.name == horizon, orElse: () => GoalHorizon.weekly),
      status: GoalStatus.values.firstWhere((e) => e.name == status, orElse: () => GoalStatus.active),
      priority: GoalPriority.values.firstWhere((e) => e.name == priority, orElse: () => GoalPriority.medium),
      steps: steps.map((s) => s.toEntity()).toList(),
      failureReason: failureReason,
      lessonsLearned: lessonsLearned,
      relatedNoteIds: relatedNoteIds,
      relatedPlannerItemIds: relatedPlannerItemIds,
      createdAt: createdAt,
      updatedAt: updatedAt,
      targetDate: targetDate,
      retryOfGoalId: retryOfGoalId,
    );
  }
}
