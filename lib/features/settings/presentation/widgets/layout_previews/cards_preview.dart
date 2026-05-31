import 'package:flutter/material.dart';
import 'shared_preview_helpers.dart';

class LayoutPreviewCards extends StatelessWidget {
  final bool isDark;
  const LayoutPreviewCards({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF13111C) : const Color(0xFFF5F3FF);
    final card = isDark ? const Color(0xFF1E1B2C) : Colors.white;
    final line = isDark ? const Color(0xFF2E2845) : const Color(0xFFE8E4F5);
    final accent = Theme.of(context).colorScheme.primary;
    final coverColor = accent;
    final textMuted = isDark ? const Color(0xFF4A4370) : const Color(0xFFD1CBE8);
    final textMain = isDark ? Colors.white.withOpacity(0.85) : Colors.white;

    return Container(
      color: bg,
      child: Column(
        children: [
          Container(
            height: 52,
            color: coverColor,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.arrow_back_ios_new_rounded, size: 7, color: Colors.white.withOpacity(0.8)),
                    const Spacer(),
                    Icon(Icons.more_vert, size: 7, color: Colors.white.withOpacity(0.8)),
                  ],
                ),
                const SizedBox(height: 6),
                Container(height: 8, width: 65, decoration: BoxDecoration(color: textMain.withOpacity(0.9), borderRadius: BorderRadius.circular(3))),
                const SizedBox(height: 3),
                Container(height: 5, width: 40, decoration: BoxDecoration(color: textMain.withOpacity(0.5), borderRadius: BorderRadius.circular(2))),
              ],
            ),
          ),
          Container(
            height: 18,
            color: card,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                previewPill(accent.withOpacity(0.15), accent, 24),
                const SizedBox(width: 4),
                previewPill(accent.withOpacity(0.15), accent, 18),
              ],
            ),
          ),
          Container(height: 1, color: line),
          Expanded(
            child: Container(
              color: card,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  previewLine(textMuted, 0.9),
                  const SizedBox(height: 3),
                  previewLine(textMuted, 0.65),
                ],
              ),
            ),
          ),
          Container(height: 1, color: line),
          Container(
            height: 20,
            color: card,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (i) => Icon(Icons.circle, size: 5, color: accent.withOpacity(0.5))),
            ),
          ),
        ],
      ),
    );
  }
}
