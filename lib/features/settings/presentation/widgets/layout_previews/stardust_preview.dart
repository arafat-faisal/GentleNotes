import 'package:flutter/material.dart';
import 'shared_preview_helpers.dart';

class LayoutPreviewStardust extends StatelessWidget {
  final bool isDark;
  const LayoutPreviewStardust({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0A051A), const Color(0xFF14083A)]
              : [const Color(0xFF1A0E3A), const Color(0xFF2D1060)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          ..._buildStars(),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                previewBar(const Color(0xFFDDB8FF), 0.6),
                const SizedBox(height: 5),
                previewBar(const Color(0xFFAA80DD), 0.4),
                const SizedBox(height: 10),
                previewBar(const Color(0xFFCC99FF).withValues(alpha: 0.7), 0.8),
                const SizedBox(height: 4),
                previewBar(const Color(0xFFCC99FF).withValues(alpha: 0.7), 0.65),
                const SizedBox(height: 4),
                previewBar(const Color(0xFFCC99FF).withValues(alpha: 0.7), 0.72),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStars() {
    final positions = [
      (left: 10.0, top: 12.0, size: 2.0),
      (left: 60.0, top: 6.0, size: 1.5),
      (left: 95.0, top: 18.0, size: 2.0),
      (left: 30.0, top: 30.0, size: 1.0),
      (left: 80.0, top: 40.0, size: 1.5),
      (left: 50.0, top: 50.0, size: 1.0),
      (left: 15.0, top: 60.0, size: 1.5),
      (left: 110.0, top: 55.0, size: 1.0),
    ];
    return positions
        .map((s) => Positioned(
              left: s.left,
              top: s.top,
              child: Container(
                width: s.size,
                height: s.size,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ))
        .toList();
  }
}
