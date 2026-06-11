/// Low-level Hive read/write operations for planner items.
///
/// Mirrors the pattern used by [NoteStorage] and [FolderStorage].
/// No business logic lives here — that belongs in the repository/use cases.
library;

import 'package:hive_flutter/hive_flutter.dart';
import '../../../features/planner/data/models/planner_item_model.dart';
import '../../../features/planner/domain/entities/planner_item_entity.dart';

class PlannerStorage {
  const PlannerStorage({required Box plannerBox}) : _box = plannerBox;

  final Box _box;

  List<PlannerItemEntity> getPlannerItems() {
    final items = <PlannerItemEntity>[];
    for (final key in _box.keys) {
      final val = _box.get(key);
      if (val is Map) {
        try {
          final model = PlannerItemModel.fromMap(Map<String, dynamic>.from(val));
          items.add(model.toEntity());
        } catch (_) {
          // Skip corrupted entries silently — log in future.
        }
      }
    }
    // Sort by date ascending, then startTime ascending.
    items.sort((a, b) {
      final dateCmp = a.date.compareTo(b.date);
      if (dateCmp != 0) return dateCmp;
      final aStart = a.startTime ?? 0;
      final bStart = b.startTime ?? 0;
      return aStart.compareTo(bStart);
    });
    return items;
  }

  Future<void> savePlannerItem(PlannerItemEntity item) async {
    final model = PlannerItemModel.fromEntity(item);
    await _box.put(item.id, model.toMap());
  }

  Future<void> deletePlannerItem(String id) async {
    await _box.delete(id);
  }
}
