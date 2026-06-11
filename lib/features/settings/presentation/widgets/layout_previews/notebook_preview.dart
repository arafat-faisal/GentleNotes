import 'package:flutter/material.dart';
import 'shared_preview_helpers.dart';

class LayoutPreviewNotebook extends StatelessWidget {
  final bool isDark;
  const LayoutPreviewNotebook({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF13111C) : const Color(0xFFF8F6FF);
    final sidebar = isDark ? const Color(0xFF1C1829) : Colors.white;
    final line = isDark ? const Color(0xFF2E2845) : const Color(0xFFE8E4F5);
    final accent = Theme.of(context).colorScheme.primary;
    final textMuted = isDark ? const Color(0xFF4A4370) : const Color(0xFFD1CBE8);
    final textMain = isDark ? const Color(0xFFCCC7E0) : const Color(0xFF3D3557);

    return Container(
      color: bg,
      child: Row(
        children: [
          Container(
            width: 40,
            color: sidebar,
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_back_ios_new_rounded, size: 8, color: accent),
                const SizedBox(height: 8),
                Container(height: 5, width: 28, decoration: BoxDecoration(color: textMuted, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 5),
                Container(height: 5, width: 20, decoration: BoxDecoration(color: accent.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 8),
                Container(height: 1, color: line),
                const SizedBox(height: 8),
                Icon(Icons.folder_outlined, size: 8, color: textMuted),
                const SizedBox(height: 5),
                Container(height: 4, width: 24, decoration: BoxDecoration(color: textMuted.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 6),
                Icon(Icons.local_offer_outlined, size: 8, color: textMuted),
                const SizedBox(height: 5),
                Container(height: 4, width: 20, decoration: BoxDecoration(color: textMuted.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2))),
              ],
            ),
          ),
          Container(width: 1, color: line),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 20,
                  color: sidebar,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (i) => Icon(Icons.circle, size: 5, color: accent.withValues(alpha: 0.5))),
                  ),
                ),
                Container(height: 1, color: line),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                  child: Container(height: 8, decoration: BoxDecoration(color: textMain, borderRadius: BorderRadius.circular(3))),
                ),
                Container(height: 1, color: line),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        previewLine(textMuted, 0.9),
                        const SizedBox(height: 4),
                        previewLine(textMuted, 0.7),
                        const SizedBox(height: 4),
                        previewLine(textMuted, 0.5),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
