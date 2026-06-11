import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../editor_body_widget.dart';
import 'aesthetic_layouts.dart';

class StardustLayout extends StatelessWidget {
  final AestheticLayout layout;
  const StardustLayout({super.key, required this.layout});

  @override
  Widget build(BuildContext context) {
    const starPrimary = Color(0xFFCFA8FF);
    const starSecondary = Color(0xFFE8D0FF);

    return Stack(
      children: [
        // ── Decorative stars ──
        ..._buildStarParticles(),

        // ── Content ──
        Column(
          children: [
            // Toolbar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: starPrimary),
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
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18, color: starPrimary),
                    onPressed: layout.onSave,
                  ),
                ],
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: TextField(
                controller: layout.titleController,
                maxLines: 2,
                minLines: 1,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: starSecondary,
                  height: 1.2,
                ),
                decoration: InputDecoration(
                  hintText: 'A dream note...',
                  hintStyle: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: starPrimary.withValues(alpha: 0.4),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),

            // Editor on frosted glass card
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: starPrimary.withValues(alpha: 0.2)),
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
      ],
    );
  }

  List<Widget> _buildStarParticles() {
    const stars = [
      (left: 20.0, top: 40.0, size: 2.0, opacity: 0.8),
      (left: 80.0, top: 15.0, size: 1.5, opacity: 0.6),
      (left: 150.0, top: 60.0, size: 2.5, opacity: 0.9),
      (left: 250.0, top: 25.0, size: 1.5, opacity: 0.7),
      (left: 310.0, top: 70.0, size: 2.0, opacity: 0.8),
      (left: 50.0, top: 120.0, size: 1.0, opacity: 0.5),
      (left: 190.0, top: 100.0, size: 1.5, opacity: 0.6),
      (left: 340.0, top: 130.0, size: 1.0, opacity: 0.4),
      (left: 120.0, top: 160.0, size: 2.0, opacity: 0.7),
      (left: 280.0, top: 180.0, size: 1.5, opacity: 0.5),
    ];
    return stars.map((s) => Positioned(
      left: s.left,
      top: s.top,
      child: Opacity(
        opacity: s.opacity,
        child: Container(
          width: s.size,
          height: s.size,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
      ),
    )).toList();
  }
}
