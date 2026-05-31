import 'package:flutter/material.dart';
import 'shared_preview_helpers.dart';

class LayoutPreviewScrapbook extends StatelessWidget {
  final bool isDark;
  const LayoutPreviewScrapbook({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A0F1A) : const Color(0xFFFFF8FF);
    return Container(
      color: bg,
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: Row(
              children: [
                _stickyNote(const Color(0xFFFFE4F0), const Color(0xFFFF69B4), 'Title', isDark),
                const SizedBox(width: 4),
                _stickyNote(const Color(0xFFE4F0FF), const Color(0xFF69B4FF), 'Folder', isDark),
                const SizedBox(width: 4),
                _stickyNote(const Color(0xFFE4FFE4), const Color(0xFF69C869), 'Tags', isDark),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF241824) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF69B4).withOpacity(0.2)),
              ),
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  previewBar(isDark ? const Color(0xFFFF69B4) : const Color(0xFFCC5599), 0.5),
                  const SizedBox(height: 4),
                  previewBar(isDark ? const Color(0xFFBB90BB) : const Color(0xFF8855AA), 0.75),
                  const SizedBox(height: 4),
                  previewBar(isDark ? const Color(0xFFBB90BB) : const Color(0xFF8855AA), 0.6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stickyNote(Color bg, Color accent, String label, bool isDark) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? accent.withOpacity(0.15) : bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: accent.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 20, height: 3, color: accent, margin: const EdgeInsets.only(bottom: 2)),
            Container(height: 2, color: accent.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}
