import 'package:flutter/material.dart';
import '../editor_blocks_list.dart';
import 'aesthetic_layouts.dart';

class JournalLayout extends StatelessWidget {
  final AestheticLayout layout;
  const JournalLayout({super.key, required this.layout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lineColor = isDark ? const Color(0xFF2E381B) : const Color(0xFFE2ECD4);

    return Column(
      children: [
        layout.buildAestheticHeader(context, 'Journal Mode', Icons.book_outlined),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: TextField(
            controller: layout.titleController,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A2E08),
            ),
            decoration: const InputDecoration(
              hintText: 'Dear Diary...',
              border: InputBorder.none,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Stack(
            children: [
              LayoutBuilder(builder: (ctx, box) {
                const lineHeight = 28.0;
                final count = (box.maxHeight / lineHeight).ceil() + 1;
                return Column(
                  children: List.generate(
                    count,
                    (_) => Container(
                      height: lineHeight,
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: lineColor, width: 1)),
                      ),
                    ),
                  ),
                );
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
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
