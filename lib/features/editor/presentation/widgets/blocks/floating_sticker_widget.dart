import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../../../models/models.dart';
import '../../controllers/floating_stickers_controller.dart';

class FloatingStickerWidget extends ConsumerStatefulWidget {
  final FloatingStickerModel sticker;
  final ScrollController scrollController;
  final QuillController? quillController;
  final EditorMode editorMode;

  const FloatingStickerWidget({
    super.key,
    required this.sticker,
    required this.scrollController,
    this.quillController,
    required this.editorMode,
  });

  @override
  ConsumerState<FloatingStickerWidget> createState() =>
      _FloatingStickerWidgetState();
}

class _FloatingStickerWidgetState extends ConsumerState<FloatingStickerWidget> {
  late TextEditingController _textController;
  final FocusNode _textFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.sticker.textOver);
  }

  @override
  void didUpdateWidget(covariant FloatingStickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sticker.textOver != widget.sticker.textOver &&
        !_textFocusNode.hasFocus) {
      _textController.text = widget.sticker.textOver;
    }
    if (oldWidget.sticker.textBehavior != widget.sticker.textBehavior &&
        widget.sticker.textBehavior == 'over') {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _textFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sticker = widget.sticker;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Main sticker body (draggable) ──────────────────────────────
          GestureDetector(
            onTap: () {
              final selectedId = ref.read(selectedStickerIdProvider);
              if (selectedId == sticker.id) {
                ref.read(selectedStickerIdProvider.notifier).state = null;
              } else {
                ref.read(selectedStickerIdProvider.notifier).state = sticker.id;
              }
            },
            onPanUpdate: (details) {
              final screenWidth = MediaQuery.of(context).size.width;
              final newX = (sticker.x + details.delta.dx)
                  .clamp(0.0, (screenWidth - sticker.width).clamp(0.0, screenWidth));
              final newY = (sticker.y + details.delta.dy).clamp(0.0, double.infinity);
              ref.read(floatingStickersProvider.notifier).updateSticker(
                    sticker.copyWith(
                      x: newX,
                      y: newY,
                    ),
                  );
            },
            child: Opacity(
              opacity: sticker.opacity,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: sticker.width,
                height: sticker.height,
                decoration: sticker.hasBackground
                    ? BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1F1B2E)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF332A54)
                              : const Color(0xFFE5DEFA),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      )
                    : null,
                padding: sticker.hasBackground
                    ? const EdgeInsets.all(12)
                    : EdgeInsets.zero,
                child: Stack(
                  children: [
                    // Sticker image
                    Positioned.fill(
                      child: _buildStickerImage(sticker.name),
                    ),

                    // Overlay text layer
                    if (sticker.textBehavior == 'over')
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: IntrinsicWidth(
                              child: TextField(
                                controller: _textController,
                                focusNode: _textFocusNode,
                                textAlign: TextAlign.center,
                                maxLines: null,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black87,
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Add text…',
                                  hintStyle: TextStyle(
                                      color: Colors.white60, fontSize: 12),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 4),
                                ),
                                onChanged: (text) {
                                  ref
                                      .read(floatingStickersProvider.notifier)
                                      .updateSticker(
                                          sticker.copyWith(textOver: text));
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Resize handle (bottom-right) ───────────────────────────────
          Positioned(
            bottom: -6,
            right: -6,
            child: GestureDetector(
              onPanUpdate: (details) {
                final screenWidth = MediaQuery.of(context).size.width;
                final maxW = screenWidth - sticker.x;
                final newW = (sticker.width + details.delta.dx)
                    .clamp(60.0, maxW.clamp(60.0, 320.0));
                final newH =
                    (sticker.height + details.delta.dy).clamp(60.0, 320.0);
                ref.read(floatingStickersProvider.notifier).updateSticker(
                      sticker.copyWith(width: newW, height: newH),
                    );
              },
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.zoom_out_map_rounded,
                  size: 11,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickerImage(String name) {
    if (name.startsWith('/') ||
        name.contains(':\\') ||
        name.contains(':/') ||
        name.startsWith('content:')) {
      return Image.file(
        File(name),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(
            Icons.broken_image_rounded,
            size: 40,
            color: Colors.redAccent,
          ),
        ),
      );
    }
    return Image.asset(
      'assets/images/stickers/$name.png',
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(
          Icons.sticky_note_2_outlined,
          size: 40,
        ),
      ),
    );
  }
}
