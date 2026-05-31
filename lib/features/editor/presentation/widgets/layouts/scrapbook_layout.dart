import 'package:flutter/material.dart';
import '../editor_blocks_list.dart';
import 'aesthetic_layouts.dart';

class ScrapbookLayout extends StatelessWidget {
  final AestheticLayout layout;
  const ScrapbookLayout({super.key, required this.layout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        layout.buildAestheticHeader(context, 'Scrapbook', Icons.auto_awesome_mosaic_outlined),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 2,
            color: isDark ? const Color(0xFF23142B) : const Color(0xFFFFF0FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? const Color(0xFF3B1E45) : const Color(0xFFFFD1FF),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: layout.titleController,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'A Memory to Keep...',
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: EditorBlocksList(
                      blocks: layout.blocks,
                      focusNodes: layout.focusNodes,
                      scrollController: layout.scrollController,
                      shrinkWrap: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
