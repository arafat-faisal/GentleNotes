import 'package:flutter/material.dart';
import 'shared_preview_helpers.dart';

class LayoutPreviewClassic extends StatelessWidget {
  final bool isDark;
  const LayoutPreviewClassic({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF13111C) : const Color(0xFFFAF9FF);
    final bar = isDark ? const Color(0xFF1E1B2C) : Colors.white;
    final line = isDark ? const Color(0xFF2E2845) : const Color(0xFFE8E4F5);
    final accent = Theme.of(context).colorScheme.primary;
    final textMuted = isDark ? const Color(0xFF4A4370) : const Color(0xFFD1CBE8);
    final textMain = isDark ? const Color(0xFFCCC7E0) : const Color(0xFF3D3557);

    return Container(
      color: bg,
      child: Column(
        children: [
          Container(
            height: 28,
            color: bar,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(Icons.arrow_back_ios_new_rounded, size: 8, color: accent),
                const SizedBox(width: 4),
                Expanded(child: Container(height: 6, decoration: BoxDecoration(color: textMain, borderRadius: BorderRadius.circular(3)))),
                const SizedBox(width: 4),
                Container(width: 8, height: 8, decoration: BoxDecoration(color: accent.withOpacity(0.5), shape: BoxShape.circle)),
              ],
            ),
          ),
          Container(height: 1, color: line),
          Container(
            height: 18,
            color: bar,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                previewPill(accent.withOpacity(0.15), accent, 28),
                const SizedBox(width: 4),
                previewPill(accent.withOpacity(0.15), accent, 22),
                const SizedBox(width: 4),
                previewColorDots(),
              ],
            ),
          ),
          Container(height: 1, color: line),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  previewLine(textMain, 0.7),
                  const SizedBox(height: 4),
                  previewLine(textMuted, 0.5),
                  const SizedBox(height: 3),
                  previewLine(textMuted, 0.65),
                  const SizedBox(height: 3),
                  previewLine(textMuted, 0.4),
                ],
              ),
            ),
          ),
          Container(height: 1, color: line),
          Container(
            height: 16,
            color: bar,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(Icons.local_offer_outlined, size: 8, color: accent),
                const SizedBox(width: 4),
                Container(height: 5, width: 50, decoration: BoxDecoration(color: textMuted, borderRadius: BorderRadius.circular(2))),
              ],
            ),
          ),
          Container(height: 1, color: line),
          Container(
            height: 22,
            color: bar,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (i) => Icon(Icons.circle, size: 6, color: accent.withOpacity(0.5))),
            ),
          ),
        ],
      ),
    );
  }
}
