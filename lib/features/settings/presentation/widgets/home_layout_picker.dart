import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/models.dart';
import '../controllers/settings_controller.dart';
import 'home_layout_previews.dart';

class HomeLayoutPicker extends ConsumerWidget {
  final AppSettingsModel settings;
  const HomeLayoutPicker({super.key, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final layoutsList = [
      (
        preset: HomeLayoutPreset.dashboard,
        previewBuilder: (bool dark) => HomePreviewDashboard(isDark: dark),
      ),
      (
        preset: HomeLayoutPreset.minimalFeed,
        previewBuilder: (bool dark) => HomePreviewMinimalFeed(isDark: dark),
      ),
      (
        preset: HomeLayoutPreset.focus,
        previewBuilder: (bool dark) => HomePreviewFocus(isDark: dark),
      ),
      (
        preset: HomeLayoutPreset.magazine,
        previewBuilder: (bool dark) => HomePreviewMagazine(isDark: dark),
      ),
      (
        preset: HomeLayoutPreset.notebook,
        previewBuilder: (bool dark) => HomePreviewNotebook(isDark: dark),
      ),
      (
        preset: HomeLayoutPreset.calendar,
        previewBuilder: (bool dark) => HomePreviewCalendar(isDark: dark),
      ),
      (
        preset: HomeLayoutPreset.compact,
        previewBuilder: (bool dark) => HomePreviewCompact(isDark: dark),
      ),
    ];

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: layoutsList.length,
        itemBuilder: (context, index) {
          final item = layoutsList[index];
          final isSelected = settings.homeLayout == item.preset;
          final accentColor = theme.colorScheme.primary;

          return GestureDetector(
            onTap: () {
              ref.read(settingsProvider.notifier).updateHomeLayout(item.preset);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 130,
              margin: EdgeInsets.only(
                left: index == 0 ? 8 : 6,
                right: index == layoutsList.length - 1 ? 8 : 6,
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
                            item.preset.displayName,
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
                          Icon(
                            Icons.circle_outlined,
                            size: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
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
