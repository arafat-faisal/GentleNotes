import 'package:flutter/material.dart';
import 'shared_preview_helpers.dart';

class LayoutPreviewZen extends StatelessWidget {
  final bool isDark;
  const LayoutPreviewZen({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF090B16) : const Color(0xFFFDFCFF);
    final accent = Theme.of(context).colorScheme.primary;
    final textMuted = isDark ? const Color(0xFF3D3557) : const Color(0xFFD8D4EE);
    final textMain = isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF2A2540);

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.arrow_back_ios_new_rounded, size: 7, color: accent.withValues(alpha: 0.3)),
          const SizedBox(height: 10),
          Container(height: 9, width: 70, decoration: BoxDecoration(color: textMain.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 6),
          previewLine(textMuted, 1.0),
          const SizedBox(height: 5),
          previewLine(textMuted, 0.8),
          const SizedBox(height: 5),
          previewLine(textMuted, 0.6),
          const SizedBox(height: 5),
          previewLine(textMuted, 0.9),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.2)),
              ),
              child: Icon(Icons.save_outlined, size: 8, color: accent.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}
