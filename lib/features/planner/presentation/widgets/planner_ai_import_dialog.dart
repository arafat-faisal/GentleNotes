import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/planner_controller.dart';
import '../../domain/entities/planner_enums.dart';

class PlannerAiImportDialog extends ConsumerStatefulWidget {
  const PlannerAiImportDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const PlannerAiImportDialog(),
    );
  }

  @override
  ConsumerState<PlannerAiImportDialog> createState() => _PlannerAiImportDialogState();
}

class _PlannerAiImportDialogState extends ConsumerState<PlannerAiImportDialog> {
  final _textController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  static const String _promptTemplate = '''
Act as a personal planning assistant. Create a structured daily, weekly, or monthly schedule for reading books (or any other study/work routine).
Provide a detailed plan.
You must output the schedule strictly as a valid JSON array of objects with the exact structure below. Do not wrap the output in markdown block format (no ```json code blocks), do not add any explanations, introductory text, or concluding text. Output ONLY the raw JSON array.

JSON Structure:
[
  {
    "title": "Short title describing the task (e.g. Read Book Name: Chapter 1)",
    "description": "Short details (e.g. Pages 1-25, key focus points)",
    "type": "studySession", // MUST be one of: "studySession", "task", "meeting", "exam", "deadline", "habit"
    "date": "YYYY-MM-DD", // Date of the item
    "startTime": 540, // Optional: start time as minutes from midnight (e.g. 9:00 AM is 540, 2:30 PM is 870). Set to null if all-day.
    "endTime": 600, // Optional: end time as minutes from midnight. Set to null if none.
    "isAllDay": false, // true if it is an all-day event
    "reminderMinutesBefore": 15, // Optional: minutes before the event to send a notification (e.g. 15, 30, 60, or null)
    "recurrenceFrequency": "none", // MUST be one of: "none", "daily", "weekly", "monthly"
    "priority": "medium", // MUST be one of: "low", "medium", "high"
    "colorHex": "#8B5CF6", // Optional: Hex color (e.g. #8B5CF6, #F43F5E, #10B981)
    "locationOrLink": "" // Optional: Location, Zoom link, or book details
  }
]
''';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _copyPrompt() {
    Clipboard.setData(const ClipboardData(text: _promptTemplate));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('AI Prompt Template copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Future<void> _importPlan() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    var rawText = _textController.text.trim();
    if (rawText.isEmpty) {
      setState(() {
        _errorMessage = 'Please paste the AI output first.';
        _isLoading = false;
      });
      return;
    }

    // Strip markdown code blocks if the AI added them
    if (rawText.contains('```')) {
      final startIdx = rawText.indexOf('[');
      final endIdx = rawText.lastIndexOf(']');
      if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
        rawText = rawText.substring(startIdx, endIdx + 1);
      }
    }

    try {
      final decoded = jsonDecode(rawText);
      if (decoded is! List) {
        throw const FormatException('Imported content must be a JSON array of plan items.');
      }

      final controller = ref.read(plannerProvider.notifier);
      int importedCount = 0;

      for (final rawItem in decoded) {
        if (rawItem is! Map) continue;
        final map = Map<String, dynamic>.from(rawItem);

        // Required fields check
        final title = map['title'] as String?;
        final dateStr = map['date'] as String?;

        if (title == null || title.trim().isEmpty) {
          throw const FormatException('Every plan item must have a non-empty "title".');
        }
        if (dateStr == null) {
          throw const FormatException('Every plan item must have a "date" (YYYY-MM-DD).');
        }

        DateTime date;
        try {
          date = DateTime.parse(dateStr);
        } catch (_) {
          throw FormatException('Invalid date format for "$title": "$dateStr". Use YYYY-MM-DD.');
        }

        // Parsing type
        final rawType = map['type'] as String?;
        final type = PlannerItemType.values.firstWhere(
          (e) => e.name.toLowerCase() == rawType?.toLowerCase(),
          orElse: () => PlannerItemType.studySession,
        );

        // Parsing recurrence
        final rawRecurrence = map['recurrenceFrequency'] as String?;
        final recurrence = RecurrenceFrequency.values.firstWhere(
          (e) => e.name.toLowerCase() == rawRecurrence?.toLowerCase(),
          orElse: () => RecurrenceFrequency.none,
        );

        // Parsing priority
        final rawPriority = map['priority'] as String?;
        final priority = PlannerPriority.values.firstWhere(
          (e) => e.name.toLowerCase() == rawPriority?.toLowerCase(),
          orElse: () => PlannerPriority.medium,
        );

        await controller.createItem(
          title: title,
          description: map['description'] as String? ?? '',
          type: type,
          date: date,
          startTime: map['startTime'] as int?,
          endTime: map['endTime'] as int?,
          isAllDay: map['isAllDay'] as bool? ?? false,
          reminderMinutesBefore: map['reminderMinutesBefore'] as int?,
          recurrenceFrequency: recurrence,
          locationOrLink: map['locationOrLink'] as String? ?? '',
          colorHex: map['colorHex'] as String? ?? '#8B5CF6',
          priority: priority,
        );
        importedCount++;
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported $importedCount plans from AI!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e is FormatException ? e.message : 'Invalid JSON content: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Import from AI',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              // ── Instruction 1: Prompt ──
              Text(
                'Step 1: Copy the prompt template, paste it in Gemini/ChatGPT/Claude, and request your custom routine.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _copyPrompt,
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy AI Prompt Template'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // ── Instruction 2: Paste ──
              Text(
                'Step 2: Paste the JSON output generated by the AI:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _textController,
                maxLines: 6,
                minLines: 3,
                style: const TextStyle(fontFamily: 'Courier', fontSize: 13),
                decoration: InputDecoration(
                  hintText: '[\n  {\n    "title": "Read Chapter 1",\n    "date": "2026-06-12",\n    ...\n  }\n]',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                ),
              ),

              // ── Error text ──
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage ?? '',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],

              const SizedBox(height: 24),

              // ── Bottom Action Buttons ──
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else
                    FilledButton(
                      onPressed: _importPlan,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Import Plans'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
