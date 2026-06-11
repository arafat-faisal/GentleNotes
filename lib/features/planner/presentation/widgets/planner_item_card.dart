import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/planner_item_entity.dart';
import '../controllers/planner_filter_controller.dart';
import 'planner_type_chip.dart';

class PlannerItemCard extends ConsumerWidget {
  const PlannerItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onComplete,
    this.showDate = false,
  });

  final PlannerItemEntity item;
  final VoidCallback onTap;
  final VoidCallback? onComplete;
  final bool showDate;

  static final _timeFmt = DateFormat('HH:mm');
  static final _dateFmt = DateFormat('MMM d');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accentColor = _hexToColor(item.colorHex);
    final isCompleted = item.isCompleted;

    final isSelectionMode = ref.watch(plannerSelectionModeProvider);
    final selectedIds = ref.watch(plannerSelectedIdsProvider);
    final isSelected = selectedIds.contains(item.id);

    return Opacity(
      opacity: isCompleted ? 0.6 : 1.0,
      child: GestureDetector(
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
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
              width: isSelected ? 1.5 : 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13.5),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Left accent border line ──
                  Container(
                    width: 4,
                    color: accentColor,
                  ),
                  // ── Main Content ──
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Complete checkbox / Selection checkbox ──
                          Padding(
                            padding: const EdgeInsets.only(top: 1, right: 12),
                            child: isSelectionMode
                                ? Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, color: Colors.white, size: 12)
                                        : null,
                                  )
                                : GestureDetector(
                                    onTap: onComplete,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: isCompleted ? accentColor : Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isCompleted ? accentColor : accentColor.withValues(alpha: 0.5),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: isCompleted
                                          ? const Icon(Icons.check, color: Colors.white, size: 12)
                                          : null,
                                    ),
                                  ),
                          ),
                          // ── Content ──
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                                    color: isCompleted
                                        ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                                        : theme.colorScheme.onSurface,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    PlannerTypeChip(type: item.type, small: true),
                                    const SizedBox(width: 8),
                                    if (_timeLabel(item).isNotEmpty) ...[
                                      Text(
                                        _timeLabel(item),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    if (showDate) ...[
                                      Text(
                                        _dateFmt.format(item.date),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    if (item.hasReminder) ...[
                                      Icon(Icons.alarm_outlined, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                                      const SizedBox(width: 6),
                                    ],
                                    if (item.isRecurring) ...[
                                      Icon(Icons.repeat_rounded, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                                    ],
                                  ],
                                ),
                                if (item.description.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    item.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _timeLabel(PlannerItemEntity item) {
    if (item.isAllDay) return 'All day';
    final start = item.startTime;
    if (start == null) return '';
    final startDt = _minutesToDt(start);
    final end = item.endTime;
    if (end == null) return _timeFmt.format(startDt);
    return '${_timeFmt.format(startDt)} – ${_timeFmt.format(_minutesToDt(end))}';
  }

  DateTime _minutesToDt(int m) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, m ~/ 60, m % 60);
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}
