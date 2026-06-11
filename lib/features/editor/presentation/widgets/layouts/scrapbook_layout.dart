import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../editor_body_widget.dart';
import 'aesthetic_layouts.dart';

class ScrapbookLayout extends StatelessWidget {
  final AestheticLayout layout;
  const ScrapbookLayout({super.key, required this.layout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    final bg = isDark ? const Color(0xFF160A1A) : const Color(0xFFFFF8FF);

    // Sticky note colors
    final stickyColors = [
      (bg: isDark ? const Color(0xFF2E1030) : const Color(0xFFFFE4F6), border: const Color(0xFFFF69B4)),
      (bg: isDark ? const Color(0xFF0E2030) : const Color(0xFFE4F0FF), border: const Color(0xFF69B4FF)),
      (bg: isDark ? const Color(0xFF102010) : const Color(0xFFE4FFE8), border: const Color(0xFF69C880)),
    ];

    return Container(
      color: bg,
      child: Column(
        children: [
          // ── Back + Save bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: accent),
                  onPressed: () {
                    layout.onSave();
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      context.go('/home');
                    }
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.save_outlined, size: 18, color: accent),
                  onPressed: layout.onSave,
                ),
              ],
            ),
          ),

          // ── Sticky-note metadata panels ──
          SizedBox(
            height: 88,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                // Title sticky
                _scrapbookSticky(
                  bgColor: stickyColors[0].bg,
                  borderColor: stickyColors[0].border,
                  label: 'TITLE',
                  width: 130,
                  child: TextField(
                    controller: layout.titleController,
                    maxLines: 2,
                    minLines: 1,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1A0030),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Note title...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Tags sticky
                _scrapbookSticky(
                  bgColor: stickyColors[2].bg,
                  borderColor: stickyColors[2].border,
                  label: 'TAGS',
                  width: 110,
                  child: TextField(
                    controller: layout.tagController,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white : const Color(0xFF1A0030),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'tag1, tag2...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Actions sticky
                _scrapbookSticky(
                  bgColor: stickyColors[1].bg,
                  borderColor: stickyColors[1].border,
                  label: 'ACTIONS',
                  width: 100,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          layout.onPinChanged(!layout.isPinned);
                          layout.onSave();
                        },
                        child: Icon(
                          layout.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          size: 18,
                          color: layout.isPinned ? accent : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          layout.onFavoriteChanged(!layout.isFavorite);
                          layout.onSave();
                        },
                        child: Icon(
                          layout.isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: layout.isFavorite ? const Color(0xFFF43F5E) : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Editor card ──
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF200A28) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // 80 padding for FloatingToolbar
                  child: EditorBodyWidget(
                    editorMode: layout.editorMode,
                    quillController: layout.quillController,
                    editorFocusNode: layout.editorFocusNode,
                    noteType: layout.noteType,
                    attachments: layout.attachments,
                    blocks: layout.blocks,
                    focusNodes: layout.focusNodes,
                    scrollController: layout.scrollController,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scrapbookSticky({
    required Color bgColor,
    required Color borderColor,
    required String label,
    required Widget child,
    required double width,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: borderColor,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: child),
        ],
      ),
    );
  }
}
