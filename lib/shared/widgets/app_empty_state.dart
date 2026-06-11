/// Generic empty state widget used across features.
///
/// Displays an icon, message, and optional call-to-action button when
/// a list or collection is empty. Fully themeable.
library;

import 'package:flutter/material.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  /// The icon to display prominently.
  final IconData icon;

  /// Short, bold title (e.g., "No notes yet").
  final String title;

  /// Optional descriptive subtitle.
  final String? subtitle;

  /// Label for the optional CTA button.
  final String? actionLabel;

  /// Callback for the optional CTA button.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon container with gradient background ──
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.12),
                    theme.colorScheme.secondary.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                size: 36,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),

            const SizedBox(height: 20),

            // ── Title ──
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),

            // ── Subtitle ──
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],

            // ── CTA Button ──
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
