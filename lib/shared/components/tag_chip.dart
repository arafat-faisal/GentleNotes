/// Reusable tag chip component for displaying note tags.
///
/// Used in note cards, note editor, and filter chips.
library;

import 'package:flutter/material.dart';

/// A small pill-shaped chip displaying a tag label.
///
/// When [onDeleted] is provided, a close icon appears (used in editor).
/// When [onTap] is provided, the chip is tappable (used as filter).
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    this.onTap,
    this.onDeleted,
    this.isSelected = false,
    this.compact = false,
  });

  /// The tag text to display.
  final String label;

  /// Called when the chip is tapped.
  final VoidCallback? onTap;

  /// Called when the delete icon is pressed.
  final VoidCallback? onDeleted;

  /// Whether this chip is currently active (e.g., as a filter).
  final bool isSelected;

  /// Renders a smaller chip variant.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.5) : color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#$label',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: compact ? 11 : 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color.withValues(alpha: isSelected ? 1.0 : 0.8),
              ),
            ),
            if (onDeleted != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDeleted,
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
