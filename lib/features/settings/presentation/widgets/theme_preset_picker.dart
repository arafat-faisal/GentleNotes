import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/models.dart';
import '../controllers/settings_controller.dart';

class ThemePresetPicker extends ConsumerWidget {
  final AppSettingsModel settings;
  const ThemePresetPicker({super.key, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final presets = settings.allowedThemes;

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        itemBuilder: (context, index) {
          final preset = presets[index];
          final isSelected = settings.themePreset == preset;
          final swatches = preset.swatchColors;
          final accentSwatch = swatches[0];

          return GestureDetector(
            onTap: () {
              ref.read(settingsProvider.notifier).updateThemePreset(preset);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 110,
              margin: EdgeInsets.only(
                left: index == 0 ? 8 : 6,
                right: index == presets.length - 1 ? 8 : 6,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? accentSwatch : theme.colorScheme.outlineVariant.withOpacity(0.4),
                  width: isSelected ? 2.5 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: accentSwatch.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))]
                    : null,
                color: isDark
                    ? (isSelected ? accentSwatch.withOpacity(0.1) : const Color(0xFF1C1829))
                    : (isSelected ? accentSwatch.withOpacity(0.06) : Colors.white),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: swatches
                        .map((c) => Container(
                              width: 18,
                              height: 18,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.3), width: 1),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(preset.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      preset.displayName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? accentSwatch : theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Icon(Icons.check_circle_rounded, size: 13, color: accentSwatch),
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
