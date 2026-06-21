import 'package:flutter/material.dart';

class PdfFlashcardDialog extends StatefulWidget {
  final String initialQuestion;
  final String? initialAnswer;
  final Function(String question, String answer) onSave;

  const PdfFlashcardDialog({
    super.key,
    required this.initialQuestion,
    this.initialAnswer,
    required this.onSave,
  });

  @override
  State<PdfFlashcardDialog> createState() => _PdfFlashcardDialogState();
}

class _PdfFlashcardDialogState extends State<PdfFlashcardDialog> {
  late final TextEditingController _questionController;
  late final TextEditingController _answerController;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.initialQuestion);
    _answerController = TextEditingController(text: widget.initialAnswer ?? '');
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E1E2F) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.style_outlined, color: Colors.amber, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'Create Study Flashcard',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Question (Front of Card)',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _questionController,
              maxLines: 3,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter question text...',
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Answer (Back of Card)',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _answerController,
              maxLines: 4,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter answer or study explanation...',
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final question = _questionController.text.trim();
                    final answer = _answerController.text.trim();
                    if (question.isNotEmpty) {
                      widget.onSave(question, answer);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Save Card'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
