/// Riverpod providers and controller for the Planner feature.
///
/// Wires together:
///   HiveLocalStorage → PlannerLocalDatasource → PlannerRepositoryImpl
///   → use cases → PlannerController
///
/// Controllers must NOT contain UI code (no BuildContext, no widgets).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/services/storage/hive_local_storage.dart';
import '../../../../core/services/storage/i_local_storage.dart';
import '../../data/datasources/planner_local_datasource.dart';
import '../../data/repositories/planner_repository_impl.dart';
import '../../data/services/ics_export_service.dart';
import '../../data/services/planner_share_service.dart';
import '../../domain/entities/planner_enums.dart';
import '../../domain/entities/planner_item_entity.dart';
import '../../domain/repositories/i_planner_repository.dart';
import '../../domain/usecases/create_planner_item_usecase.dart';
import '../../domain/usecases/delete_planner_item_usecase.dart';
import '../../domain/usecases/get_planner_items_usecase.dart';
import '../../domain/usecases/update_planner_item_usecase.dart';
import 'planner_state.dart';

// ── Dependency Injection ──────────────────────────────────────────────────────

final plannerStorageProvider = Provider<ILocalStorage>((ref) => HiveLocalStorage());

final plannerDatasourceProvider = Provider<PlannerLocalDatasource>((ref) {
  return PlannerLocalDatasource(ref.watch(plannerStorageProvider));
});

final plannerRepositoryProvider = Provider<IPlannerRepository>((ref) {
  return PlannerRepositoryImpl(ref.watch(plannerDatasourceProvider));
});

// ── Singleton services ────────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>(
  (_) => NotificationService(),
);

final plannerShareServiceProvider = Provider<PlannerShareService>(
  (_) => const PlannerShareService(),
);

final icsExportServiceProvider = Provider<IcsExportService>(
  (_) => const IcsExportService(),
);

// ── Controller ────────────────────────────────────────────────────────────────

class PlannerController extends StateNotifier<PlannerState> {
  PlannerController({
    required IPlannerRepository repository,
    required NotificationService notificationService,
  })  : _repository = repository,
        _notifService = notificationService,
        _createUseCase = CreatePlannerItemUseCase(repository),
        _updateUseCase = UpdatePlannerItemUseCase(repository),
        _deleteUseCase = DeletePlannerItemUseCase(repository),
        _getUseCase = GetPlannerItemsUseCase(repository),
        super(const PlannerState()) {
    _load();
  }

  final IPlannerRepository _repository;
  final NotificationService _notifService;
  final CreatePlannerItemUseCase _createUseCase;
  final UpdatePlannerItemUseCase _updateUseCase;
  final DeletePlannerItemUseCase _deleteUseCase;
  final GetPlannerItemsUseCase _getUseCase;

  void _load() {
    state = state.copyWith(items: _getUseCase.getAll(), clearError: true);
  }

  Future<void> createItem({
    required String title,
    String description = '',
    required PlannerItemType type,
    required DateTime date,
    int? startTime,
    int? endTime,
    bool isAllDay = false,
    int? reminderMinutesBefore,
    RecurrenceFrequency recurrenceFrequency = RecurrenceFrequency.none,
    String? linkedNoteId,
    String? linkedGoalId,
    String locationOrLink = '',
    String colorHex = '#8B5CF6',
    PlannerPriority priority = PlannerPriority.medium,
  }) async {
    try {
      final item = await _createUseCase(
        title: title,
        description: description,
        type: type,
        date: date,
        startTime: startTime,
        endTime: endTime,
        isAllDay: isAllDay,
        reminderMinutesBefore: reminderMinutesBefore,
        recurrenceFrequency: recurrenceFrequency,
        linkedNoteId: linkedNoteId,
        linkedGoalId: linkedGoalId,
        locationOrLink: locationOrLink,
        colorHex: colorHex,
        priority: priority,
      );
      await _scheduleReminder(item);
      _load();
    } catch (error, stackTrace) {
      // TODO: Replace with app-level logger.
      state = state.copyWith(errorMessage: 'Could not create planner item: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> updateItem(PlannerItemEntity item) async {
    try {
      await _updateUseCase(item);
      await _notifService.cancelPlannerReminder(_notifId(item.id));
      await _scheduleReminder(item);
      _load();
    } catch (error, stackTrace) {
      state = state.copyWith(errorMessage: 'Could not update planner item: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _notifService.cancelPlannerReminder(_notifId(id));
      await _deleteUseCase(id);
      _load();
    } catch (error, stackTrace) {
      state = state.copyWith(errorMessage: 'Could not delete planner item: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> deleteMultipleItems(List<String> ids) async {
    try {
      for (final id in ids) {
        await _notifService.cancelPlannerReminder(_notifId(id));
        await _deleteUseCase(id);
      }
      _load();
    } catch (error, stackTrace) {
      state = state.copyWith(errorMessage: 'Could not delete planner items: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> markCompleted(String id) async {
    try {
      await _repository.markCompleted(id);
      _load();
    } catch (error, stackTrace) {
      state = state.copyWith(errorMessage: 'Could not update status: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  // ── Reminder Scheduling ───────────────────────────────────────────────────

  Future<void> _scheduleReminder(PlannerItemEntity item) async {
    if (!item.hasReminder || item.reminderMinutesBefore == null) return;
    final reminderAt = _reminderDateTime(item);
    if (reminderAt == null) return;
    await _notifService.schedulePlannerReminder(
      notifId: _notifId(item.id),
      title: item.title,
      body: '${item.type.emoji} ${item.type.displayName} reminder',
      scheduledAt: reminderAt,
      payload: item.id,
    );
  }

  DateTime? _reminderDateTime(PlannerItemEntity item) {
    final minutesBefore = item.reminderMinutesBefore;
    if (minutesBefore == null) return null;
    final start = item.startTime;
    final baseMinutes = start ?? 480; // Default 08:00 if no start time.
    final triggerMinutes = baseMinutes - minutesBefore;
    return DateTime(
      item.date.year,
      item.date.month,
      item.date.day,
      triggerMinutes ~/ 60,
      triggerMinutes.abs() % 60,
    );
  }

  /// Derives a stable int notification ID from a UUID string.
  int _notifId(String uuid) => uuid.hashCode.abs() % 2147483647;
}

final plannerProvider =
    StateNotifierProvider<PlannerController, PlannerState>((ref) {
  return PlannerController(
    repository: ref.watch(plannerRepositoryProvider),
    notificationService: ref.watch(notificationServiceProvider),
  );
});

// ── Derived Providers ─────────────────────────────────────────────────────────

/// Today's items sorted by start time.
final todayPlannerItemsProvider = Provider<List<PlannerItemEntity>>((ref) {
  final items = ref.watch(plannerProvider).items;
  final today = DateTime.now();
  final todayDay = DateTime(today.year, today.month, today.day);
  return items
      .where((i) => i.date == todayDay)
      .toList()
    ..sort((a, b) => (a.startTime ?? 0).compareTo(b.startTime ?? 0));
});

/// Upcoming items (today or later).
final upcomingPlannerItemsProvider = Provider<List<PlannerItemEntity>>((ref) {
  final items = ref.watch(plannerProvider).items;
  final today = DateTime.now();
  final todayDay = DateTime(today.year, today.month, today.day);
  return items.where((i) => !i.date.isBefore(todayDay)).toList();
});
