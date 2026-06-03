import 'package:flutter/material.dart';

class CustomModeSelectorGrid extends StatelessWidget {
  final bool isAdvanced;
  final ValueChanged<bool> onModeChanged;

  const CustomModeSelectorGrid({
    super.key,
    required this.isAdvanced,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Simple Mode Choice Card
        Expanded(
          child: GestureDetector(
            onTap: () => onModeChanged(false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: !isAdvanced 
                    ? theme.colorScheme.primary.withOpacity(0.06) 
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: !isAdvanced 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.outlineVariant.withOpacity(0.3),
                  width: !isAdvanced ? 2 : 1,
                ),
                boxShadow: !isAdvanced
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.spa_rounded, 
                        color: !isAdvanced ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.4),
                        size: 22,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Simple Mode',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: !isAdvanced ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Keep layouts minimal (Classic, Minimal) and use 5 standard themes.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withOpacity(0.55),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                  if (!isAdvanced)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Advanced Mode Choice Card
        Expanded(
          child: GestureDetector(
            onTap: () => onModeChanged(true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isAdvanced 
                    ? theme.colorScheme.primary.withOpacity(0.06) 
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isAdvanced 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.outlineVariant.withOpacity(0.3),
                  width: isAdvanced ? 2 : 1,
                ),
                boxShadow: isAdvanced
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.tune_rounded, 
                        color: isAdvanced ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.4),
                        size: 22,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Advanced Mode',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isAdvanced ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Unlock all layout variations, cover designs, themes, and fine-tune permissions.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withOpacity(0.55),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                  if (isAdvanced)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
