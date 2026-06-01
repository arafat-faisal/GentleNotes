import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/models.dart';
import '../controllers/settings_controller.dart';
import 'layout_previews.dart';

class EditorLayoutPicker extends ConsumerWidget {
  final AppSettingsModel settings;
  const EditorLayoutPicker({super.key, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final allowedLayouts = settings.allowedLayouts;
    final filteredVariants = [
      (
        variant: EditorLayoutVariant.classic,
        icon: Icons.view_agenda_outlined,
        previewBuilder: (bool dark) => LayoutPreviewClassic(isDark: dark),
      ),
      (
        variant: EditorLayoutVariant.minimal,
        icon: Icons.article_outlined,
        previewBuilder: (bool dark) => LayoutPreviewMinimal(isDark: dark),
      ),
      (
        variant: EditorLayoutVariant.notebook,
        icon: Icons.menu_book_outlined,
        previewBuilder: (bool dark) => LayoutPreviewNotebook(isDark: dark),
      ),
      (
        variant: EditorLayoutVariant.zen,
        icon: Icons.self_improvement_rounded,
        previewBuilder: (bool dark) => LayoutPreviewZen(isDark: dark),
      ),
      (
        variant: EditorLayoutVariant.cards,
        icon: Icons.style_rounded,
        previewBuilder: (bool dark) => LayoutPreviewCards(isDark: dark),
      ),
      (
        variant: EditorLayoutVariant.journal,
        icon: Icons.edit_note_rounded,
        previewBuilder: (bool dark) => LayoutPreviewJournal(isDark: dark),
      ),
      (
        variant: EditorLayoutVariant.scrapbook,
        icon: Icons.dashboard_customize_outlined,
        previewBuilder: (bool dark) => LayoutPreviewScrapbook(isDark: dark),
      ),
      (
        variant: EditorLayoutVariant.petal,
        icon: Icons.local_florist_outlined,
        previewBuilder: (bool dark) => LayoutPreviewPetal(isDark: dark),
      ),
      (
        variant: EditorLayoutVariant.stardust,
        icon: Icons.auto_awesome_rounded,
        previewBuilder: (bool dark) => LayoutPreviewStardust(isDark: dark),
      ),
    ].where((item) => allowedLayouts.contains(item.variant)).toList();

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filteredVariants.length,
        itemBuilder: (context, index) {
          final item = filteredVariants[index];
          final isSelected = settings.editorLayout == item.variant;
          final accentColor = theme.colorScheme.primary;

          return GestureDetector(
            onTap: () {
              ref.read(settingsProvider.notifier).updateEditorLayout(item.variant);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 130,
              margin: EdgeInsets.only(
                left: index == 0 ? 8 : 6,
                right: index == filteredVariants.length - 1 ? 8 : 6,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? accentColor : theme.colorScheme.outlineVariant.withOpacity(0.4),
                  width: isSelected ? 2.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accentColor.withOpacity(0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
                color: isDark
                    ? (isSelected ? accentColor.withOpacity(0.08) : const Color(0xFF1C1829))
                    : (isSelected ? accentColor.withOpacity(0.05) : Colors.white),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: 130,
                          height: 130,
                          child: item.previewBuilder(isDark),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: isSelected
                              ? accentColor.withOpacity(0.3)
                              : theme.colorScheme.outlineVariant.withOpacity(0.2),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.variant.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? accentColor : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, size: 16, color: accentColor)
                        else
                          Icon(Icons.circle_outlined, size: 16,
                              color: theme.colorScheme.onSurface.withOpacity(0.3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
