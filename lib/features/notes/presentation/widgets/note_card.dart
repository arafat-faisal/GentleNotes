/// Reusable NoteCard widget for displaying a note preview.
///
/// Used on the home screen, folder detail screen, and search results.
/// This widget is purely presentational — it receives data and callbacks,
/// contains no business logic, and never accesses providers directly.
library;

import 'package:flutter/material.dart';
import '../../../../models/models.dart';
import '../../../../core/theme/app_colors.dart';

/// A card widget that displays a preview of a [NoteModel].
///
/// Tapping the card triggers [onTap]. Long-press triggers [onLongPress]
/// (useful for multi-select or context menus).
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onLongPress,
    this.onTogglePin,
    this.onToggleFavorite,
    this.onDelete,
    this.compact = false,
  });

  /// The note data to display.
  final NoteModel note;

  /// Called when the card is tapped (navigate to editor).
  final VoidCallback onTap;

  /// Called on long-press (e.g., show context menu).
  final VoidCallback? onLongPress;

  /// Called when the pin icon is tapped.
  final VoidCallback? onTogglePin;

  /// Called when the favorite icon is tapped.
  final VoidCallback? onToggleFavorite;

  /// Called when the delete action is triggered.
  final VoidCallback? onDelete;

  /// When true, renders a more compact single-line layout.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use note's custom color if it's not default white/dark
    final noteColor = _resolveCardColor(note.colorHex, isDark);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: noteColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppColors.violet).withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: compact ? _buildCompactLayout(context, theme) : _buildFullLayout(context, theme),
      ),
    );
  }

  Widget _buildFullLayout(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row: type icon + pin/fav indicators ──
          Row(
            children: [
              Icon(note.noteType.icon, size: 14, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text(
                note.noteType.displayName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (note.isPinned) ...[
                Icon(Icons.push_pin_rounded, size: 14, color: AppColors.violet.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
              ],
              if (note.isFavorite)
                Icon(Icons.favorite_rounded, size: 14, color: AppColors.rose.withValues(alpha: 0.8)),
            ],
          ),

          const SizedBox(height: 10),

          // ── Title ──
          if (note.title.isNotEmpty)
            Text(
              note.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

          // ── Content preview ──
          if (note.content.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _contentPreview(note.plainText),
              style: theme.textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // ── Tags ──
          if (note.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: note.tags.take(3).map((tag) => _buildTag(context, tag)).toList(),
            ),
          ],

          const SizedBox(height: 12),

          // ── Footer: date + attachment indicator ──
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 12,
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
              const SizedBox(width: 4),
              Text(
                _formatDate(note.updatedAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              if (note.attachments.isNotEmpty) ...[
                Icon(Icons.attach_file_rounded, size: 12,
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
                const SizedBox(width: 2),
                Text(
                  '${note.attachments.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(note.noteType.icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title.isNotEmpty ? note.title : 'Untitled',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatDate(note.updatedAt),
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          if (note.isPinned)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(Icons.push_pin_rounded, size: 14, color: AppColors.violet),
            ),
        ],
      ),
    );
  }

  Widget _buildTag(BuildContext context, String tag) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Color _resolveCardColor(String hex, bool isDark) {
    if (hex == '#FFFFFF' || hex.isEmpty) {
      return isDark ? AppColors.darkCard : AppColors.lightCard;
    }
    try {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) {
        return Color(int.parse('FF$h', radix: 16));
      }
    } catch (_) {}
    return isDark ? AppColors.darkCard : AppColors.lightCard;
  }

  String _contentPreview(String content) {
    final cleaned = content
        .replaceAll(RegExp(r'#{1,6}\s'), '')
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'_+'), '')
        .replaceAll(RegExp(r'`+'), '')
        .replaceAll(RegExp(r'\n+'), ' ')
        .trim();
    return cleaned.length > 120 ? '${cleaned.substring(0, 120)}…' : cleaned;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
