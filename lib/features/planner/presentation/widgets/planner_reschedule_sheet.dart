import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/planner_item_entity.dart';

class PlannerRescheduleSheet extends StatefulWidget {
  const PlannerRescheduleSheet({
    super.key,
    required this.item,
    required this.onReschedule,
  });

  final PlannerItemEntity item;
  final Function(
    DateTime newDate,
    int? newStartTime,
    int? newEndTime,
    bool isAllDay,
    String reason,
  ) onReschedule;

  static void show({
    required BuildContext context,
    required PlannerItemEntity item,
    required Function(
      DateTime newDate,
      int? newStartTime,
      int? newEndTime,
      bool isAllDay,
      String reason,
    ) onReschedule,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: PlannerRescheduleSheet(item: item, onReschedule: onReschedule),
      ),
    );
  }

  @override
  State<PlannerRescheduleSheet> createState() => _PlannerRescheduleSheetState();
}

class _PlannerRescheduleSheetState extends State<PlannerRescheduleSheet> {
  late DateTime _date;
  int? _startTime;
  int? _endTime;
  late bool _isAllDay;
  String _selectedPresetReason = 'Not enough time';
  final TextEditingController _customReasonCtrl = TextEditingController();

  static final _dateFmt = DateFormat('EEE, MMM d yyyy');
  static final _timeFmt = DateFormat('HH:mm');

  static const _presetReasons = [
    'Not enough time',
    'Felt tired / exhausted',
    'Urgent priority came up',
    'Procrastinated / Lazy',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _date = widget.item.date;
    _startTime = widget.item.startTime;
    _endTime = widget.item.endTime;
    _isAllDay = widget.item.isAllDay;
  }

  @override
  void dispose() {
    _customReasonCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final isOther = _selectedPresetReason == 'Other';
    final reasonText = _customReasonCtrl.text.trim();
    final reason = isOther 
        ? (reasonText.isEmpty ? 'Rescheduled' : reasonText) 
        : (reasonText.isEmpty ? _selectedPresetReason : '$_selectedPresetReason ($reasonText)');

    widget.onReschedule(
      _date,
      _isAllDay ? null : _startTime,
      _isAllDay ? null : _endTime,
      _isAllDay,
      reason,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Handlebar indicator ──
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Sheet Title ──
              Text(
                'Shift / Reschedule Plan',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // ── Date Selector ──
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.calendar_today_outlined, color: theme.colorScheme.primary),
                title: Text(_dateFmt.format(_date)),
                subtitle: const Text('Change Day'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _date = picked);
                  }
                },
              ),
              const SizedBox(height: 12),

              // ── All Day toggle ──
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('All day'),
                value: _isAllDay,
                onChanged: (v) => setState(() => _isAllDay = v),
              ),

              // ── Times Picker ──
              if (!_isAllDay) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeButton(context, 'Start', _startTime, (v) => setState(() => _startTime = v), theme),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTimeButton(context, 'End', _endTime, (v) => setState(() => _endTime = v), theme),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // ── Reason Selection Title ──
              Text(
                'Reason for rescheduling',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 10),

              // ── Reason Choice Chips ──
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetReasons.map((reason) {
                  final isSelected = reason == _selectedPresetReason;
                  return ChoiceChip(
                    label: Text(reason),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedPresetReason = reason);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // ── Custom Reason / Details TextField ──
              TextFormField(
                controller: _customReasonCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: _selectedPresetReason == 'Other' 
                      ? 'Please specify your reason...' 
                      : 'Additional notes or reason (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 28),

              // ── Submit Button ──
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save & Shift Plan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeButton(
    BuildContext context,
    String label,
    int? current,
    ValueChanged<int?> onPicked,
    ThemeData theme,
  ) {
    final now = DateTime.now();
    final displayDt = current != null
        ? DateTime(now.year, now.month, now.day, current ~/ 60, current % 60)
        : null;
    return OutlinedButton.icon(
      icon: const Icon(Icons.access_time_outlined, size: 16),
      label: Text(displayDt != null ? _timeFmt.format(displayDt) : label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () async {
        final tod = await showTimePicker(
          context: context,
          initialTime: displayDt != null ? TimeOfDay.fromDateTime(displayDt) : TimeOfDay.now(),
        );
        if (tod != null) {
          onPicked(tod.hour * 60 + tod.minute);
        }
      },
    );
  }
}
