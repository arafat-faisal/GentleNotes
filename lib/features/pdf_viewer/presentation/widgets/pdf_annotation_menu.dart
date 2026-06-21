import 'package:flutter/material.dart';

class PdfAnnotationMenu extends StatelessWidget {
  final String selectedText;
  final Function(String colorHex, String annotationType, String category) onApplyMarkup;
  final Function() onSaveAsNote;
  final Function() onAddStickyNote;
  final Function() onCreateFlashcard;
  final Function() onAiExplain;
  final Function() onClose;

  const PdfAnnotationMenu({
    super.key,
    required this.selectedText,
    required this.onApplyMarkup,
    required this.onSaveAsNote,
    required this.onAddStickyNote,
    required this.onCreateFlashcard,
    required this.onAiExplain,
    required this.onClose,
  });

  static const List<Map<String, dynamic>> categories = [
    {'name': 'Concept', 'color': Color(0xFFFFF176), 'hex': '#FFF176'},
    {'name': 'Exam', 'color': Color(0xFFFF8A80), 'hex': '#FF8A80'},
    {'name': 'Definition', 'color': Color(0xFFA5D6A7), 'hex': '#A5D6A7'},
    {'name': 'Doubt', 'color': Color(0xFF90CAF9), 'hex': '#90CAF9'},
    {'name': 'Formula', 'color': Color(0xFFFFCC80), 'hex': '#FFCC80'},
    {'name': 'Example', 'color': Color(0xFFE1BEE7), 'hex': '#E1BEE7'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E2F) : Colors.white,
      child: Container(
        width: 320,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Selected Text (${selectedText.length} chars)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onClose,
                ),
              ],
            ),
            const Divider(height: 12),
            // Colors row
            Text(
              'Color Categories',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: categories.map((cat) {
                return Tooltip(
                  message: cat['name'],
                  child: InkWell(
                    onTap: () => onApplyMarkup(cat['hex'], 'highlight', cat['name']),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: cat['color'],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Markup style buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStyleBtn(Icons.format_underlined_rounded, 'Underline', () {
                  onApplyMarkup('#FFF176', 'underline', 'Underline');
                }, theme),
                _buildStyleBtn(Icons.format_strikethrough_rounded, 'Strike', () {
                  onApplyMarkup('#FF8A80', 'strikethrough', 'Strikethrough');
                }, theme),
                _buildStyleBtn(Icons.gesture_rounded, 'Squiggly', () {
                  onApplyMarkup('#90CAF9', 'squiggly', 'Squiggly');
                }, theme),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 12),
            // Workspace action buttons
            _buildActionButton(
              icon: Icons.note_add_outlined,
              label: 'Save as Note',
              subtitle: 'Extract selection to GentleNotes',
              onTap: onSaveAsNote,
              theme: theme,
            ),
            const SizedBox(height: 6),
            _buildActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'PDF Margin Note',
              subtitle: 'Add a sticky comment alongside text',
              onTap: onAddStickyNote,
              theme: theme,
            ),
            const SizedBox(height: 6),
            _buildActionButton(
              icon: Icons.style_outlined,
              label: 'Make Flashcard',
              subtitle: 'Convert selection into Q&A card',
              onTap: onCreateFlashcard,
              theme: theme,
            ),
            const SizedBox(height: 6),
            _buildActionButton(
              icon: Icons.psychology_outlined,
              label: 'AI Explanation',
              subtitle: 'Explain concept / paste AI summary',
              onTap: onAiExplain,
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleBtn(IconData icon, String tooltip, VoidCallback onTap, ThemeData theme) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}
