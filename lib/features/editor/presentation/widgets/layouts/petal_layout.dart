import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../folders/presentation/controllers/folders_controller.dart';
import '../../../../../models/models.dart';
import '../editor_body_widget.dart';
import 'aesthetic_layouts.dart';

class PetalLayout extends ConsumerWidget {
  final AestheticLayout layout;
  const PetalLayout({super.key, required this.layout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    final bg = isDark ? const Color(0xFF1A0710) : const Color(0xFFFFF5F9);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final headerGradient = isDark
        ? [const Color(0xFF9B1B5A), const Color(0xFF4A0B2A)]
        : [const Color(0xFFFF9EC8), const Color(0xFFFFCDE0)];

    final folders = ref.watch(foldersProvider);
    final folder = folders.cast<FolderModel?>().firstWhere(
          (f) => f?.id == layout.selectedFolderId,
          orElse: () => null,
        );
    final folderName = folder?.name ?? 'No Folder';

    return Container(
      color: bg,
      child: Column(
        children: [
          // ── Curved petal header ──
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back + actions
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          layout.onSave();
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            context.go('/home');
                          }
                        },
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          layout.onPinChanged(!layout.isPinned);
                          layout.onSave();
                        },
                        child: Icon(
                          layout.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          size: 18,
                          color: Colors.white,
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
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: layout.onSave,
                        child: const Icon(Icons.save_outlined, size: 18, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  TextField(
                    controller: layout.titleController,
                    maxLines: 2,
                    minLines: 1,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Beautiful title...',
                      hintStyle: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.55),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Editor content ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 80), // 80 padding for FloatingToolbar
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

          // ── Rounded pill meta row ──
          if (!isKeyboardOpen)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 80), // extra padding for bottom alignment
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _petalChip(
                      icon: Icons.local_offer_outlined,
                      label: layout.tagController.text.isEmpty ? 'Tags' : layout.tagController.text,
                      accent: accent,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),
                    _petalChip(
                      icon: Icons.folder_outlined,
                      label: folderName,
                      accent: accent,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _petalChip({
    required IconData icon,
    required String label,
    required Color accent,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withOpacity(isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
