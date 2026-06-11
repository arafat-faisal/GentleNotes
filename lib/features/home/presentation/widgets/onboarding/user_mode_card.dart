import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../models/models.dart';
import '../../../../settings/presentation/controllers/settings_controller.dart';

class UserModeCard extends ConsumerWidget {
  final AppUserMode mode;

  const UserModeCard({
    super.key,
    required this.mode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final isSelected = settings.userMode == mode;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.04)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.dividerColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              ref.read(settingsProvider.notifier).updateUserMode(mode);
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      mode.icon,
                      size: 20,
                      color: isSelected ? Colors.white : theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mode.displayName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Outfit',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          mode.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    )
                  else
                    Icon(
                      Icons.circle_outlined,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
          if (isSelected && mode != AppUserMode.custom && !settings.isAdvancedMode) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Simple Mode applied: Layout: ${settings.editorLayout.displayName} | Theme: ${settings.themePreset.displayName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isSelected && mode == AppUserMode.custom && !settings.isAdvancedMode) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Custom profile settings are locked. Toggle "Advanced Mode" above to choose custom configurations.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isSelected && mode == AppUserMode.custom && settings.isAdvancedMode) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enabled Layouts',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: EditorLayoutVariant.values.map((variant) {
                      final isEnabled = settings.customEnabledLayouts.contains(variant);
                      return FilterChip(
                        label: Text(variant.displayName),
                        selected: isEnabled,
                        onSelected: (selected) {
                          final list = List<EditorLayoutVariant>.from(settings.customEnabledLayouts);
                          if (selected) {
                            list.add(variant);
                          } else {
                            if (list.length > 1) list.remove(variant);
                          }
                          ref.read(settingsProvider.notifier).updateCustomEnabledLayouts(list);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enabled Themes',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppThemePreset.values.map((preset) {
                      final isEnabled = settings.customEnabledThemes.contains(preset);
                      return FilterChip(
                        label: Text('${preset.emoji} ${preset.displayName}'),
                        selected: isEnabled,
                        onSelected: (selected) {
                          final list = List<AppThemePreset>.from(settings.customEnabledThemes);
                          if (selected) {
                            list.add(preset);
                          } else {
                            if (list.length > 1) list.remove(preset);
                          }
                          ref.read(settingsProvider.notifier).updateCustomEnabledThemes(list);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enabled Editor Toolbar Groups',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ('format', 'Basic Format (Bold, Italic...)'),
                      ('color', 'Colors & Highlights'),
                      ('heading', 'Headers (H1-H6)'),
                      ('align', 'Alignments'),
                      ('lists', 'Bullet/Checkbox Lists'),
                      ('insert', 'Inserts (Media, Drawing, Record...)'),
                      ('indent', 'Indentation & Line Breaks'),
                    ].map((t) {
                      final isEnabled = settings.customEnabledTools.contains(t.$1);
                      return FilterChip(
                        label: Text(t.$2),
                        selected: isEnabled,
                        onSelected: (selected) {
                          final list = List<String>.from(settings.customEnabledTools);
                          if (selected) {
                            list.add(t.$1);
                          } else {
                            if (list.length > 1) list.remove(t.$1);
                          }
                          ref.read(settingsProvider.notifier).updateCustomEnabledTools(list);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
