import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/planner_item_entity.dart';
import '../controllers/planner_filter_controller.dart';

class PlannerItemTile extends ConsumerWidget {
  const PlannerItemTile({
    super.key,
    required this.item,
    required this.onTap,
    this.onComplete,
  });

  final PlannerItemEntity item;
  final VoidCallback onTap;
  final VoidCallback? onComplete;

  static final _timeFmt = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accentColor = _hexToColor(item.colorHex);
    final isCompleted = item.isCompleted;

    final isSelectionMode = ref.watch(plannerSelectionModeProvider);
    final selectedIds = ref.watch(plannerSelectedIdsProvider);
    final isSelected = selectedIds.contains(item.id);

    return ListTile(
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: isSelectionMode
          ? Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 11)
                  : null,
            )
          : GestureDetector(
              onTap: onComplete,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isCompleted ? accentColor : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor, width: 1.5),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 11)
                    : null,
              ),
            ),
      title: Text(
        item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          decoration: isCompleted ? TextDecoration.lineThrough : null,
          color: isCompleted
              ? theme.colorScheme.onSurface.withValues(alpha: 0.45)
              : theme.colorScheme.onSurface,
        ),
      ),
      subtitle: _buildSubtitle(context, theme),
      trailing: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
      ),
      onTap: () {
        if (isSelectionMode) {
          final notifier = ref.read(plannerSelectedIdsProvider.notifier);
          if (isSelected) {
            notifier.state = {...selectedIds}..remove(item.id);
          } else {
            notifier.state = {...selectedIds, item.id};
          }
        } else {
          onTap();
        }
      },
      onLongPress: () {
        if (!isSelectionMode) {
          ref.read(plannerSelectionModeProvider.notifier).state = true;
          ref.read(plannerSelectedIdsProvider.notifier).state = {item.id};
        }
      },
    );
  }

  Widget? _buildSubtitle(BuildContext context, ThemeData theme) {
    final parts = <String>[];
    if (item.isAllDay) {
      parts.add('All day');
    } else if (item.startTime != null) {
      final dt = DateTime.now();
      final start = DateTime(dt.year, dt.month, dt.day, item.startTime! ~/ 60, item.startTime! % 60);
      parts.add(_timeFmt.format(start));
    }
    if (parts.isEmpty) return null;
    return Text(
      parts.join('  ·  '),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}
