import 'package:flutter/material.dart';
import '../editor_blocks_list.dart';
import 'aesthetic_layouts.dart';

class CardsLayout extends StatelessWidget {
  final AestheticLayout layout;
  const CardsLayout({super.key, required this.layout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final coverBg = isDark ? const Color(0xFF2E2845) : const Color(0xFFE3DCF5);

    return Column(
      children: [
        layout.buildAestheticHeader(context, 'Cards Layout', Icons.view_agenda_outlined),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C182B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: coverBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: layout.titleController,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Card Note Title',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: EditorBlocksList(
                      blocks: layout.blocks,
                      focusNodes: layout.focusNodes,
                      scrollController: layout.scrollController,
                      shrinkWrap: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
