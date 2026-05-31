import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../editor_body_widget.dart';
import 'aesthetic_layouts.dart';

class JournalLayout extends StatelessWidget {
  final AestheticLayout layout;
  const JournalLayout({super.key, required this.layout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    final bg = isDark ? const Color(0xFF0F1A0A) : const Color(0xFFFFFDF5);
    final lineColor = isDark ? const Color(0xFF1E2D15) : const Color(0xFFE2EDD0);

    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${months[now.month - 1]} ${now.day}, ${now.year}';

    return Container(
      color: bg,
      child: Column(
        children: [
          // ── Date header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withOpacity(isDark ? 0.18 : 0.09),
              border: Border(bottom: BorderSide(color: lineColor, width: 1)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  color: accent,
                  onPressed: () {
                    layout.onSave();
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      context.go('/home');
                    }
                  },
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 13, color: accent),
                      const SizedBox(width: 5),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.save_outlined, size: 18, color: accent),
                  onPressed: layout.onSave,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),

          // ── Title ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: TextField(
              controller: layout.titleController,
              maxLines: 2,
              minLines: 1,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A2E08),
                height: 1.2,
              ),
              decoration: InputDecoration(
                hintText: 'Dear Diary...',
                hintStyle: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: lineColor.withOpacity(0.8),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          Divider(height: 1, indent: 20, endIndent: 20, color: accent.withOpacity(0.3)),

          // ── Ruled-line editor ──
          Expanded(
            child: Stack(
              children: [
                // Ruled lines background
                LayoutBuilder(
                  builder: (ctx, box) {
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
                  },
                ),
                // Left red margin line
                Positioned(
                  left: 48,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 1.5,
                    color: const Color(0xFFFFB3B3).withOpacity(isDark ? 0.3 : 0.7),
                  ),
                ),
                // Editor padded to write on ruled paper, leaves 80px room at bottom for FloatingToolbar
                Padding(
                  padding: const EdgeInsets.only(left: 56, right: 16, top: 4, bottom: 80),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
