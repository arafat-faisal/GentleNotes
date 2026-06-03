import 'package:flutter/material.dart';

class HistoryActionGroup extends StatelessWidget {
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool canUndo;
  final bool canRedo;

  const HistoryActionGroup({
    super.key,
    required this.onUndo,
    required this.onRedo,
    required this.canUndo,
    required this.canRedo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.undo_rounded, size: 20, color: canUndo ? theme.colorScheme.primary : theme.disabledColor),
          onPressed: canUndo ? onUndo : null,
          tooltip: 'Undo',
        ),
        IconButton(
          icon: Icon(Icons.redo_rounded, size: 20, color: canRedo ? theme.colorScheme.primary : theme.disabledColor),
          onPressed: canRedo ? onRedo : null,
          tooltip: 'Redo',
        ),
      ],
    );
  }
}
