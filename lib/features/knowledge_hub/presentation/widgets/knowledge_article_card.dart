// Article card widget for the Knowledge Hub article list.

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/knowledge_article.dart';

class KnowledgeArticleCard extends StatelessWidget {
  final KnowledgeArticle article;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onSaveToggle;

  const KnowledgeArticleCard({
    super.key,
    required this.article,
    required this.isSaved,
    required this.onTap,
    required this.onSaveToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = article.source.accentColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCoverImage(),
              _buildSourceRow(theme, accent),
              const SizedBox(height: 8),
              _buildTitle(theme),
              if (article.subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildSubtitle(theme),
              ],
              if (article.author.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildAuthorRow(theme, accent),
              ],
              if (article.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildTags(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    if (article.imageUrl == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          article.imageUrl!,
          height: 130,
          width: double.infinity,
          fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildSourceRow(ThemeData theme, Color accent) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            article.source.label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accent),
          ),
        ),
        const Spacer(),
        if (article.readTime != null)
          Text(
            article.readTime!,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        const SizedBox(width: 6),
        InkWell(
          onTap: onSaveToggle,
          borderRadius: BorderRadius.circular(20),
          child: Icon(
            isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            size: 16,
            color: isSaved ? accent : theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Text(
      article.title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSubtitle(ThemeData theme) {
    return Text(
      article.subtitle,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildAuthorRow(ThemeData theme, Color accent) {
    return Row(
      children: [
        CircleAvatar(
          radius: 9,
          backgroundColor: accent.withValues(alpha: 0.2),
          child: Text(
            article.author[0].toUpperCase(),
            style: TextStyle(fontSize: 9, color: accent, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          article.author,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildTags(ThemeData theme) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: article.tags.take(3).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '#$tag',
            style: TextStyle(fontSize: 10, color: theme.colorScheme.primary),
          ),
        );
      }).toList(),
    );
  }
}
