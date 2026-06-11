/// State object for the Planner controller.
///
/// Immutable — all mutations create a new instance via [copyWith].
library;

import '../../domain/entities/planner_item_entity.dart';

class PlannerState {
  const PlannerState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<PlannerItemEntity> items;
  final bool isLoading;
  final String? errorMessage;

  bool get hasError => errorMessage != null;

  PlannerState copyWith({
    List<PlannerItemEntity>? items,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlannerState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
