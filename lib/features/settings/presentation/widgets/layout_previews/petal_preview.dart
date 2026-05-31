import 'package:flutter/material.dart';
import 'shared_preview_helpers.dart';

class LayoutPreviewPetal extends StatelessWidget {
  final bool isDark;
  const LayoutPreviewPetal({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A0710) : const Color(0xFFFFF5F9);
    return Container(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipPath(
            clipper: PetalClipper(),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF9B1B5A), const Color(0xFF4A0B2A)]
                      : [const Color(0xFFFF9EC8), const Color(0xFFFFCDE0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  previewBar(Colors.white.withOpacity(0.9), 0.6),
                  const SizedBox(height: 4),
                  previewBar(Colors.white.withOpacity(0.6), 0.4),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  previewBar(isDark ? const Color(0xFF7A3050) : const Color(0xFFD4557A), 0.7),
                  const SizedBox(height: 5),
                  previewBar(isDark ? const Color(0xFF5A2A40) : const Color(0xFFE8A0B8), 0.85),
                  const SizedBox(height: 5),
                  previewBar(isDark ? const Color(0xFF5A2A40) : const Color(0xFFE8A0B8), 0.6),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
            child: Row(children: [
              previewPill(const Color(0xFFFFCDE0), const Color(0xFFFF9EC8), 28),
              const SizedBox(width: 4),
              previewPill(const Color(0xFFFFDDEC), const Color(0xFFFFB3CE), 20),
              const SizedBox(width: 4),
              previewPill(const Color(0xFFFFEEF5), const Color(0xFFFF9EC8), 24),
            ]),
          ),
        ],
      ),
    );
  }
}

class PetalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 12);
    path.quadraticBezierTo(size.width / 2, size.height + 6, size.width, size.height - 12);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_) => false;
}
