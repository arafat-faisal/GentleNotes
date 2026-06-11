import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/models.dart';
import '../controllers/settings_controller.dart';

class ThemeModeToggle extends ConsumerWidget {
  final AppSettingsModel settings;
  const ThemeModeToggle({super.key, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    const modes = [
      (mode: ThemeModeSetting.light, icon: Icons.wb_sunny_rounded, label: 'Light'),
      (mode: ThemeModeSetting.system, icon: Icons.phone_android_rounded, label: 'Device'),
      (mode: ThemeModeSetting.dark, icon: Icons.nightlight_round, label: 'Dark'),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.brightness_6_rounded, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Theme Mode', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: modes.asMap().entries.map((entry) {
                  final item = entry.value;
                  final isSelected = settings.themeMode == item.mode;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(settingsProvider.notifier).updateThemeMode(item.mode);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isSelected ? primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: isSelected
                              ? [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item.icon,
                              size: 14,
                              color: isSelected
                                  ? (theme.brightness == Brightness.dark ? Colors.black : Colors.white)
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? (theme.brightness == Brightness.dark ? Colors.black : Colors.white)
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
