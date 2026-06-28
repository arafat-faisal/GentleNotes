// Scrollable source selector pill bar for the Knowledge Hub.

import 'package:flutter/material.dart';
import '../../data/models/knowledge_article.dart';

class KnowledgeSourceBar extends StatelessWidget {
  final KnowledgeSource activeSource;
  final ValueChanged<KnowledgeSource> onSourceChanged;

  const KnowledgeSourceBar({
    super.key,
    required this.activeSource,
    required this.onSourceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.cardColor,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: KnowledgeSource.values
                  .map((src) => _SourcePill(
                        source: src,
                        isActive: activeSource == src,
                        onTap: () => onSourceChanged(src),
                      ))
                  .toList(),
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
        ],
      ),
    );
  }
}

class _SourcePill extends StatelessWidget {
  final KnowledgeSource source;
  final bool isActive;
  final VoidCallback onTap;

  const _SourcePill({
    required this.source,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = source.accentColor;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? color : theme.dividerColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                source.icon,
                size: 14,
                color: isActive
                    ? Colors.white
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                source.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive
                      ? Colors.white
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
