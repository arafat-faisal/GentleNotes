import 'package:flutter/material.dart';

class GoalFailureSheet extends StatefulWidget {
  final Function(String reason, String lessons) onSubmit;

  const GoalFailureSheet({
    super.key,
    required this.onSubmit,
  });

  @override
  State<GoalFailureSheet> createState() => _GoalFailureSheetState();
}

class _GoalFailureSheetState extends State<GoalFailureSheet> {
  final _reasonController = TextEditingController();
  final _lessonsController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    _lessonsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reflect on this goal',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Failing is part of the process. Write down what happened and what you can learn from it.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Why did it fail?',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _lessonsController,
            decoration: const InputDecoration(
              labelText: 'Lessons Learned',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onSubmit(
                  _reasonController.text.trim(),
                  _lessonsController.text.trim(),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Mark as Failed'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
