import 'package:flutter/material.dart';
import 'shared_preview_helpers.dart';

class LayoutPreviewMinimal extends StatelessWidget {
  final bool isDark;
  const LayoutPreviewMinimal({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0D0B18) : const Color(0xFFFBFAFF);
    final line = isDark ? const Color(0xFF252234) : const Color(0xFFEEEBFF);
    final accent = Theme.of(context).colorScheme.primary;
    final textMuted = isDark ? const Color(0xFF4A4370) : const Color(0xFFD1CBE8);
    final textMain = isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF1A1A2E);

    return Container(
      color: bg,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.arrow_back_ios_new_rounded, size: 8, color: accent),
              const Spacer(),
              Icon(Icons.more_vert, size: 8, color: textMuted),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 10, width: 80, decoration: BoxDecoration(color: textMain, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 4),
          Container(height: 1, color: line),
          const SizedBox(height: 8),
          previewLine(textMuted, 0.9),
          const SizedBox(height: 4),
          previewLine(textMuted, 0.7),
          const SizedBox(height: 4),
          previewLine(textMuted, 0.55),
          const Spacer(),
          Align(
            alignment: Alignment.center,
            child: Container(
              height: 16,
              width: 80,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (i) => Container(width: 5, height: 5, decoration: BoxDecoration(color: accent.withOpacity(0.6), shape: BoxShape.circle))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
