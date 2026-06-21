/// Create / Edit planner item form screen.
///
/// Handles both creation (when [existingItem] is null) and editing.
/// All validation is delegated to the use cases.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../controllers/planner_controller.dart';
import '../widgets/planner_color_picker.dart';
import '../widgets/planner_note_link_picker.dart';
import '../widgets/planner_goal_link_picker.dart';
import '../widgets/planner_priority_selector.dart';
import '../widgets/planner_recurrence_picker.dart';
import '../widgets/planner_reminder_picker.dart';
import '../../domain/entities/planner_enums.dart';
import '../../domain/entities/planner_item_entity.dart';

class CreateEditPlannerItemScreen extends ConsumerStatefulWidget {
  const CreateEditPlannerItemScreen({super.key, this.existingItem});

  final PlannerItemEntity? existingItem;

  @override
  ConsumerState<CreateEditPlannerItemScreen> createState() =>
      _CreateEditPlannerItemScreenState();
}

class _CreateEditPlannerItemScreenState
    extends ConsumerState<CreateEditPlannerItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _locationCtrl;

  late PlannerItemType _type;
  late DateTime _date;
  int? _startTime;
  int? _endTime;
  late bool _isAllDay;
  int? _reminderMinutes;
  late RecurrenceFrequency _recurrence;
  String? _linkedNoteId;
  String? _linkedGoalId;
  late String _colorHex;
  late PlannerPriority _priority;
  bool _isSaving = false;

  static final _dateFmt = DateFormat('EEE, MMM d yyyy');
  static final _timeFmt = DateFormat('HH:mm');

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _titleCtrl = TextEditingController(text: item?.title ?? '');
    _descCtrl = TextEditingController(text: item?.description ?? '');
    _locationCtrl = TextEditingController(text: item?.locationOrLink ?? '');
    _type = item?.type ?? PlannerItemType.task;
    _date = item?.date ?? DateTime.now();
    _startTime = item?.startTime;
    _endTime = item?.endTime;
    _isAllDay = item?.isAllDay ?? false;
    _reminderMinutes = item?.reminderMinutesBefore;
    _recurrence = item?.recurrenceFrequency ?? RecurrenceFrequency.none;
    _linkedNoteId = item?.linkedNoteId;
    _linkedGoalId = item?.linkedGoalId;
    _colorHex = item?.colorHex ?? '#8B5CF6';
    _priority = item?.priority ?? PlannerPriority.medium;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final controller = ref.read(plannerProvider.notifier);
      if (_isEditing) {
        final updated = widget.existingItem!.copyWith(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          type: _type,
          date: _date,
          startTime: _startTime,
          endTime: _endTime,
          isAllDay: _isAllDay,
          reminderMinutesBefore: _reminderMinutes,
          clearReminder: _reminderMinutes == null,
          recurrenceFrequency: _recurrence,
          linkedNoteId: _linkedNoteId,
          clearLinkedNote: _linkedNoteId == null,
          linkedGoalId: _linkedGoalId,
          clearLinkedGoal: _linkedGoalId == null,
          locationOrLink: _locationCtrl.text.trim(),
          colorHex: _colorHex,
          priority: _priority,
          updatedAt: DateTime.now(),
        );
        await controller.updateItem(updated);
      } else {
        await controller.createItem(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          type: _type,
          date: _date,
          startTime: _startTime,
          endTime: _endTime,
          isAllDay: _isAllDay,
          reminderMinutesBefore: _reminderMinutes,
          recurrenceFrequency: _recurrence,
          linkedNoteId: _linkedNoteId,
          linkedGoalId: _linkedGoalId,
          locationOrLink: _locationCtrl.text.trim(),
          colorHex: _colorHex,
          priority: _priority,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Plan' : 'New Plan'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildTitleField(theme),
            const SizedBox(height: 16),
            _buildTypeSelector(theme),
            const SizedBox(height: 16),
            _buildDateRow(context, theme),
            const SizedBox(height: 16),
            _buildAllDayRow(theme),
            if (!_isAllDay) ...[
              const SizedBox(height: 16),
              _buildTimeRow(context, theme),
            ],
            const SizedBox(height: 16),
            _buildSectionLabel('Priority', theme),
            const SizedBox(height: 8),
            PlannerPrioritySelector(selected: _priority, onChanged: (p) => setState(() => _priority = p)),
            const SizedBox(height: 16),
            _buildSectionLabel('Color', theme),
            const SizedBox(height: 8),
            PlannerColorPicker(selectedHex: _colorHex, onChanged: (h) => setState(() => _colorHex = h)),
            const SizedBox(height: 16),
            _buildReminderRow(context, theme),
            const SizedBox(height: 16),
            _buildRecurrenceRow(context, theme),
            const SizedBox(height: 16),
            _buildDescriptionField(theme),
            const SizedBox(height: 16),
            _buildLocationField(theme),
            const SizedBox(height: 16),
            _buildNoteLinkRow(context, theme),
            const SizedBox(height: 16),
            _buildGoalLinkRow(context, theme),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField(ThemeData theme) {
    return TextFormField(
      controller: _titleCtrl,
      autofocus: !_isEditing,
      decoration: InputDecoration(
        hintText: 'What are you planning?',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(14),
      ),
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
    );
  }

  Widget _buildTypeSelector(ThemeData theme) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: PlannerItemType.values.map((t) {
          final isSelected = t == _type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('${t.emoji} ${t.displayName}'),
              selected: isSelected,
              onSelected: (_) => setState(() => _type = t),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateRow(BuildContext context, ThemeData theme) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.calendar_today_outlined, color: theme.colorScheme.primary),
      title: Text(_dateFmt.format(_date)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) setState(() => _date = picked);
      },
    );
  }

  Widget _buildAllDayRow(ThemeData theme) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('All day'),
      value: _isAllDay,
      onChanged: (v) => setState(() => _isAllDay = v),
    );
  }

  Widget _buildTimeRow(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(child: _buildTimePicker(context, 'Start', _startTime, (v) => _startTime = v, theme)),
        const SizedBox(width: 12),
        Expanded(child: _buildTimePicker(context, 'End', _endTime, (v) => _endTime = v, theme)),
      ],
    );
  }

  Widget _buildTimePicker(BuildContext context, String label, int? current, ValueChanged<int?> onPicked, ThemeData theme) {
    final now = DateTime.now();
    final displayDt = current != null
        ? DateTime(now.year, now.month, now.day, current ~/ 60, current % 60)
        : null;
    return OutlinedButton.icon(
      icon: const Icon(Icons.access_time_outlined, size: 16),
      label: Text(displayDt != null ? _timeFmt.format(displayDt) : label),
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
      onPressed: () async {
        final tod = await showTimePicker(
          context: context,
          initialTime: displayDt != null ? TimeOfDay.fromDateTime(displayDt) : TimeOfDay.now(),
        );
        if (tod != null) setState(() => onPicked(tod.hour * 60 + tod.minute));
      },
    );
  }

  Widget _buildReminderRow(BuildContext context, ThemeData theme) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.alarm_outlined, color: theme.colorScheme.primary),
      title: const Text('Reminder'),
      subtitle: Text(_reminderLabel()),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => PlannerReminderPicker.show(
        context: context,
        current: _reminderMinutes,
        onChanged: (v) => setState(() => _reminderMinutes = v),
      ),
    );
  }

  Widget _buildRecurrenceRow(BuildContext context, ThemeData theme) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.repeat_rounded, color: theme.colorScheme.primary),
      title: const Text('Repeat'),
      subtitle: Text(_recurrence.displayName),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => PlannerRecurrencePicker.show(
        context: context,
        current: _recurrence,
        onChanged: (v) => setState(() => _recurrence = v),
      ),
    );
  }

  Widget _buildDescriptionField(ThemeData theme) {
    return TextFormField(
      controller: _descCtrl,
      minLines: 2,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: 'Description (optional)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(14),
      ),
    );
  }

  Widget _buildLocationField(ThemeData theme) {
    return TextFormField(
      controller: _locationCtrl,
      decoration: InputDecoration(
        hintText: 'Location or meeting link (optional)',
        prefixIcon: const Icon(Icons.place_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(14),
      ),
    );
  }

  Widget _buildNoteLinkRow(BuildContext context, ThemeData theme) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.link_rounded, color: theme.colorScheme.primary),
      title: const Text('Linked Note'),
      subtitle: Text(_linkedNoteId != null ? 'Note linked' : 'No note linked'),
      trailing: _linkedNoteId != null
          ? IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => setState(() => _linkedNoteId = null),
            )
          : const Icon(Icons.chevron_right_rounded),
      onTap: () => PlannerNoteLinkPicker.show(
        context: context,
        currentNoteId: _linkedNoteId,
        onChanged: (id) => setState(() => _linkedNoteId = id),
      ),
    );
  }

  Widget _buildGoalLinkRow(BuildContext context, ThemeData theme) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.flag_outlined, color: theme.colorScheme.primary),
      title: const Text('Linked Goal'),
      subtitle: Text(_linkedGoalId != null ? 'Goal linked' : 'No goal linked'),
      trailing: _linkedGoalId != null
          ? IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => setState(() => _linkedGoalId = null),
            )
          : const Icon(Icons.chevron_right_rounded),
      onTap: () => PlannerGoalLinkPicker.show(
        context: context,
        currentGoalId: _linkedGoalId,
        onChanged: (id) => setState(() => _linkedGoalId = id),
      ),
    );
  }

  Widget _buildSectionLabel(String label, ThemeData theme) {
    return Text(
      label,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }

  String _reminderLabel() {
    if (_reminderMinutes == null) return 'No reminder';
    if (_reminderMinutes! < 60) return '$_reminderMinutes min before';
    if (_reminderMinutes == 60) return '1 hour before';
    if (_reminderMinutes! < 1440) return '${_reminderMinutes! ~/ 60} hours before';
    return '1 day before';
  }
}
