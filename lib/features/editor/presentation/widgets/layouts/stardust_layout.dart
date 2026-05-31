import 'package:flutter/material.dart';
import '../editor_blocks_list.dart';
import 'aesthetic_layouts.dart';

class StardustLayout extends StatelessWidget {
  final AestheticLayout layout;
  const StardustLayout({super.key, required this.layout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        layout.buildAestheticHeader(
          context,
          'Stardust Mode',
          Icons.star_border_rounded,
          darkThemeColor: const Color(0xFFCFA8FF),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: TextField(
            controller: layout.titleController,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE8D0FF),
            ),
            decoration: const InputDecoration(
              hintText: 'Stardust writing...',
              hintStyle: TextStyle(color: Colors.white30),
              border: InputBorder.none,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              const Positioned(
                top: 40,
                right: 20,
                child: Icon(Icons.star_rounded, color: Color(0x30E8D0FF), size: 24),
              ),
              const Positioned(
                bottom: 80,
                left: 30,
                child: Icon(Icons.star_rounded, color: Color(0x20CFA8FF), size: 16),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: EditorBlocksList(
                  blocks: layout.blocks,
                  focusNodes: layout.focusNodes,
                  scrollController: layout.scrollController,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
