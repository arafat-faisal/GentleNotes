import 'package:flutter/material.dart';

/// A small circular icon button used as navigation/action controls
/// inside the fullscreen gallery overlay.
class GalleryCircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const GalleryCircleBtn({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: size),
        ),
      ),
    );
  }
}
