import 'package:flutter/material.dart';

class PdfSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String matchStatus; // e.g. "3 of 12" or "No results"
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onClear;
  final VoidCallback onSaveResults;
  final Function(String) onSearch;

  const PdfSearchBar({
    super.key,
    required this.controller,
    required this.matchStatus,
    required this.onPrevious,
    required this.onNext,
    required this.onClear,
    required this.onSaveResults,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Search inside document...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: onSearch,
            ),
          ),
          if (matchStatus.isNotEmpty) ...[
            Text(
              matchStatus,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up_rounded),
              tooltip: 'Previous match',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onPrevious,
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              tooltip: 'Next match',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onNext,
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Save results as Study Note',
              child: IconButton(
                icon: const Icon(Icons.save_alt_rounded, size: 18),
                color: theme.colorScheme.primary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onSaveResults,
              ),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: const Icon(Icons.cancel_outlined, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}
