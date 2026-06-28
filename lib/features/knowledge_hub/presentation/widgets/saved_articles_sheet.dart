// Saved articles bottom sheet for the Knowledge Hub.

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/knowledge_article.dart';

class SavedArticlesSheet extends StatelessWidget {
  final List<KnowledgeArticle> savedArticles;
  final ValueChanged<KnowledgeArticle> onOpen;
  final ValueChanged<KnowledgeArticle> onRemove;

  const SavedArticlesSheet({
    super.key,
    required this.savedArticles,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.3,
      expand: false,
      builder: (_, sc) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHandle(theme),
              _buildHeader(theme),
              Divider(height: 1, color: theme.dividerColor),
              Expanded(child: _buildList(theme, sc)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: theme.dividerColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          const Icon(Icons.bookmark_rounded),
          const SizedBox(width: 8),
          Text(
            'Saved Articles',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            '${savedArticles.length} saved',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildList(ThemeData theme, ScrollController sc) {
    if (savedArticles.isEmpty) {
      return const Center(
        child: Text(
          'No saved articles yet.\nTap ⊕ on any article to save.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      controller: sc,
      itemCount: savedArticles.length,
      separatorBuilder: (ctx, i) =>
          Divider(height: 1, color: theme.dividerColor),
      itemBuilder: (ctx, i) {
        final a = savedArticles[i];
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: a.source.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(a.source.icon, size: 16, color: a.source.accentColor),
          ),
          title: Text(
            a.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          subtitle:
              Text(a.author, style: const TextStyle(fontSize: 11)),
          trailing: IconButton(
            icon: const Icon(Icons.bookmark_remove_rounded, size: 18),
            onPressed: () => onRemove(a),
          ),
          onTap: () => onOpen(a),
        );
      },
    );
  }
}
