import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../models/models.dart';
import '../../core/services/notification_service.dart';
import '../notes/data/notes_repository.dart';
import '../../shared/widgets/gentle_scaffold.dart';

// ─── Reminder Model ────────────────────────────────────────────────────────────
class ReminderModel {
  final String id;
  final String noteId;
  final String noteTitle;
  final DateTime scheduledAt;
  final bool isRecurring;
  final String? repeatInterval; // 'daily', 'weekly', 'monthly'

  ReminderModel({
    required this.id,
    required this.noteId,
    required this.noteTitle,
    required this.scheduledAt,
    this.isRecurring = false,
    this.repeatInterval,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'noteId': noteId,
        'noteTitle': noteTitle,
        'scheduledAt': scheduledAt.toIso8601String(),
        'isRecurring': isRecurring,
        'repeatInterval': repeatInterval,
      };

  factory ReminderModel.fromMap(Map<String, dynamic> m) => ReminderModel(
        id: m['id'] ?? '',
        noteId: m['noteId'] ?? '',
        noteTitle: m['noteTitle'] ?? '',
        scheduledAt: DateTime.parse(m['scheduledAt']),
        isRecurring: m['isRecurring'] ?? false,
        repeatInterval: m['repeatInterval'],
      );
}

// ─── Reminders Repository ──────────────────────────────────────────────────────
class RemindersRepository extends StateNotifier<List<ReminderModel>> {
  RemindersRepository() : super([]) {
    _load();
  }

  static const _key = 'gentle_reminders';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      state = list
          .map((e) => ReminderModel.fromMap(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.map((r) => r.toMap()).toList()));
  }

  Future<void> addReminder(ReminderModel reminder) async {
    state = [...state, reminder]
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    await _save();
    // Schedule notification
    final hash = reminder.id.hashCode.abs() % 100000;
    await NotificationService().scheduleReminder(
      id: hash,
      title: '📝 ${reminder.noteTitle}',
      body: 'You have a reminder for this note.',
      scheduledAt: reminder.scheduledAt,
    );
  }

  Future<void> deleteReminder(String id) async {
    final reminder = state.firstWhere((r) => r.id == id, orElse: () => state.first);
    final hash = reminder.id.hashCode.abs() % 100000;
    await NotificationService().cancelReminder(hash);
    state = state.where((r) => r.id != id).toList();
    await _save();
  }

  List<ReminderModel> getRemindersForDate(DateTime date) {
    return state.where((r) {
      final d = r.scheduledAt;
      return d.year == date.year && d.month == date.month && d.day == date.day;
    }).toList();
  }
}

final remindersProvider = StateNotifierProvider<RemindersRepository, List<ReminderModel>>(
    (ref) => RemindersRepository());

// ─── Calendar Screen ───────────────────────────────────────────────────────────
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    NotificationService().requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reminders = ref.watch(remindersProvider);

    final today = DateTime.now();
    _selectedDay ??= today;

    final selectedDay = _selectedDay;
    final dayReminders = reminders.where((r) {
      if (selectedDay == null) return false;
      final d = r.scheduledAt;
      return d.year == selectedDay.year &&
          d.month == selectedDay.month &&
          d.day == selectedDay.day;
    }).toList();

    return GentleScaffold(
      title: 'Calendar & Reminders',
      showBackButton: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.today_rounded),
          tooltip: 'Go to today',
          onPressed: () => setState(() {
            _selectedMonth = DateTime.now();
            _selectedDay = DateTime.now();
          }),
        ),
      ],
      body: Container(
        color: isDark ? const Color(0xFF0D0B18) : const Color(0xFFF5F3FF),
        child: Column(
          children: [
            // ── Month Navigator ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? const Color(0xFF13111C) : Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () => setState(() {
                      _selectedMonth = DateTime(
                          _selectedMonth.year, _selectedMonth.month - 1);
                    }),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () => setState(() {
                      _selectedMonth = DateTime(
                          _selectedMonth.year, _selectedMonth.month + 1);
                    }),
                  ),
                ],
              ),
            ),

            // ── Calendar Grid ────────────────────────────────────────────────────
            Container(
              color: isDark ? const Color(0xFF13111C) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: _buildCalendarGrid(reminders, isDark, theme),
            ),

            const Divider(height: 1),

            // ── Selected Day Reminders ───────────────────────────────────────────
            Expanded(
              child: _buildDayView(dayReminders, isDark, theme),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReminderDialog(context),
        backgroundColor: const Color(0xFF8B5CF6),
        icon: const Icon(Icons.alarm_add_rounded),
        label: const Text('Add Reminder'),
      ),
    );
  }

  Widget _buildCalendarGrid(
      List<ReminderModel> reminders, bool isDark, ThemeData theme) {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final startOffset = firstDay.weekday % 7; // Sunday = 0

    final dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Column(
      children: [
        // Day labels
        Row(
          children: dayLabels
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        // Date cells
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
          ),
          itemCount: startOffset + lastDay.day,
          itemBuilder: (context, index) {
            if (index < startOffset) return const SizedBox();
            final day = index - startOffset + 1;
            final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
            final hasReminder = reminders.any((r) {
              final d = r.scheduledAt;
              return d.year == date.year &&
                  d.month == date.month &&
                  d.day == date.day;
            });
            final isToday = _isSameDay(date, DateTime.now());
            final isSelected = _selectedDay != null && _isSameDay(date, _selectedDay!);

            return GestureDetector(
              onTap: () => setState(() => _selectedDay = date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF8B5CF6)
                      : isToday
                          ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday && !isSelected
                      ? Border.all(color: const Color(0xFF8B5CF6), width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? const Color(0xFF8B5CF6)
                                : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (hasReminder)
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : const Color(0xFF8B5CF6),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDayView(
      List<ReminderModel> dayReminders, bool isDark, ThemeData theme) {
    final selectedDay = _selectedDay;
    final dateStr = selectedDay != null
        ? DateFormat('EEEE, MMMM d').format(selectedDay)
        : 'Select a day';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            dateStr,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (dayReminders.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.alarm_off_rounded,
                      size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 8),
                  Text('No reminders for this day',
                      style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: dayReminders.length,
              itemBuilder: (ctx, i) {
                final r = dayReminders[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  color: isDark ? const Color(0xFF1E1B2E) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF8B5CF6), width: 0.5),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF8B5CF6),
                      child: Icon(Icons.alarm_rounded, color: Colors.white, size: 18),
                    ),
                    title: Text(r.noteTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      DateFormat('h:mm a').format(r.scheduledAt),
                      style: TextStyle(
                          color: const Color(0xFF8B5CF6),
                          fontWeight: FontWeight.w500),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Color(0xFFF87171), size: 18),
                      onPressed: () => _deleteReminder(r.id),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _deleteReminder(String id) {
    ref.read(remindersProvider.notifier).deleteReminder(id);
  }

  void _showAddReminderDialog(BuildContext context) {
    final notes = ref.read(notesProvider);
    NoteModel? selectedNote;
    DateTime pickedDate = _selectedDay ?? DateTime.now();
    TimeOfDay pickedTime = TimeOfDay.fromDateTime(
        DateTime.now().add(const Duration(hours: 1)));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            backgroundColor:
                Theme.of(ctx).brightness == Brightness.dark
                    ? const Color(0xFF13111C)
                    : Colors.white,
            title: const Text('Add Reminder',
                style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Note selector
                  DropdownButtonFormField<NoteModel>(
                    initialValue: selectedNote,
                    decoration: const InputDecoration(
                      labelText: 'Select Note',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note_outlined),
                    ),
                    items: notes
                        .map((n) => DropdownMenuItem(
                              value: n,
                              child: Text(n.title.isEmpty ? 'Untitled' : n.title,
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (n) => setModalState(() => selectedNote = n),
                  ),
                  const SizedBox(height: 16),

                  // Date picker row
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_rounded),
                    label: Text(DateFormat('MMM d, yyyy').format(pickedDate)),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: pickedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (d != null) setModalState(() => pickedDate = d);
                    },
                  ),
                  const SizedBox(height: 8),

                  // Time picker row
                  OutlinedButton.icon(
                    icon: const Icon(Icons.access_time_rounded),
                    label: Text(pickedTime.format(context)),
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: ctx,
                        initialTime: pickedTime,
                      );
                      if (t != null) setModalState(() => pickedTime = t);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6)),
                onPressed: selectedNote == null
                    ? null
                    : () {
                        final scheduled = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        final reminder = ReminderModel(
                          id: const Uuid().v4(),
                          noteId: selectedNote!.id,
                          noteTitle: selectedNote!.title.isEmpty
                              ? 'Untitled Note'
                              : selectedNote!.title,
                          scheduledAt: scheduled,
                        );
                        ref
                            .read(remindersProvider.notifier)
                            .addReminder(reminder);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('✅ Reminder set!'),
                          backgroundColor: Color(0xFF8B5CF6),
                          duration: Duration(seconds: 2),
                        ));
                      },
                child: const Text('Set Reminder'),
              ),
            ],
          );
        },
      ),
    );
  }
}
