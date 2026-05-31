import 'package:flutter/material.dart';
import '../editor_blocks_list.dart';
import 'aesthetic_layouts.dart';

class PetalLayout extends StatelessWidget {
  final AestheticLayout layout;
  const PetalLayout({super.key, required this.layout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headerGradient = isDark
        ? [const Color(0xFF9B1B5A), const Color(0xFF4A0B2A)]
        : [const Color(0xFFFF9EC8), const Color(0xFFFFCDE0)];

    return Column(
      children: [
        ClipPath(
          clipper: PetalHeaderClipper(),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: headerGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              children: [
                layout.buildAestheticHeader(context, 'Petal Layout', Icons.spa_outlined, darkThemeColor: Colors.white),
                TextField(
                  controller: layout.titleController,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Petal Note...',
                    hintStyle: TextStyle(color: Colors.white60),
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: EditorBlocksList(
              blocks: layout.blocks,
              focusNodes: layout.focusNodes,
              scrollController: layout.scrollController,
            ),
          ),
        ),
      ],
    );
  }
}

class PetalHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 16);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 10,
      size.width,
      size.height - 16,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(PetalHeaderClipper oldClipper) => false;
}
