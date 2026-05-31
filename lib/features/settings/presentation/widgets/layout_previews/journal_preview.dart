import 'package:flutter/material.dart';
import 'shared_preview_helpers.dart';

class LayoutPreviewJournal extends StatelessWidget {
  final bool isDark;
  const LayoutPreviewJournal({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0F1A0A) : const Color(0xFFFFFDF5);
    final lineColor = isDark ? const Color(0xFF1E2D15) : const Color(0xFFE8F0DA);
    final accent = isDark ? const Color(0xFF88C070) : const Color(0xFF5A8A3C);
    final textLine = isDark ? const Color(0xFF2A3D20) : const Color(0xFFD5E8BE);

    return Container(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 22,
            color: accent.withOpacity(isDark ? 0.25 : 0.12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              previewBar(accent.withOpacity(0.6), 0.35),
              const Spacer(),
              previewBar(accent.withOpacity(0.4), 0.2),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            child: previewBar(isDark ? Colors.white70 : const Color(0xFF2A3D20), 0.7),
          ),
          Divider(height: 1, color: accent.withOpacity(0.3)),
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: List.generate(6, (i) => Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: lineColor, width: 1)),
                      ),
                    ),
                  )),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      previewBar(textLine, 0.8),
                      const SizedBox(height: 6),
                      previewBar(textLine, 0.65),
                      const SizedBox(height: 6),
                      previewBar(textLine, 0.75),
                    ],
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
