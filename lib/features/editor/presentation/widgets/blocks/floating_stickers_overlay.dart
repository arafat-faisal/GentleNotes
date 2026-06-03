import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../../../models/models.dart';
import '../../controllers/floating_stickers_controller.dart';
import '../../controllers/editor_block_controller.dart';
import '../../../domain/entities/block_type.dart';
import 'floating_sticker_widget.dart';

class FloatingStickersOverlay extends ConsumerWidget {
  final ScrollController scrollController;
  final QuillController? quillController;
  final EditorMode editorMode;

  const FloatingStickersOverlay({
    super.key,
    required this.scrollController,
    this.quillController,
    required this.editorMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stickers = ref.watch(floatingStickersProvider);
    final selectedStickerId = ref.watch(selectedStickerIdProvider);

    return ListenableBuilder(
      listenable: scrollController,
      builder: (context, child) {
        final scrollOffset = scrollController.hasClients ? scrollController.offset : 0.0;

        // Find the selected sticker if it exists
        FloatingStickerModel? selectedSticker;
        if (selectedStickerId != null) {
          for (final s in stickers) {
            if (s.id == selectedStickerId) {
              selectedSticker = s;
              break;
            }
          }
        }

        final screenWidth = MediaQuery.of(context).size.width;

        double? toolbarTop;
        double? toolbarLeft;
        if (selectedSticker != null) {
          double top = selectedSticker.y - scrollOffset - 58;
          if (top < 8.0) {
            // Not enough space above! Render below instead.
            top = selectedSticker.y - scrollOffset + selectedSticker.height + 8;
          }
          toolbarTop = top;
          toolbarLeft = (selectedSticker.x + (selectedSticker.width - 260) / 2)
              .clamp(12.0, (screenWidth - 260 - 12.0).clamp(12.0, screenWidth));
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Render all stickers
            ...stickers.map((sticker) {
              final top = sticker.y - scrollOffset;
              final left = sticker.x;

              return Positioned(
                top: top,
                left: left,
                width: sticker.width,
                height: sticker.height,
                child: FloatingStickerWidget(
                  key: ValueKey(sticker.id),
                  sticker: sticker,
                  scrollController: scrollController,
                  quillController: quillController,
                  editorMode: editorMode,
                ),
              );
            }),

            // Render options toolbar above/below the active sticker
            if (selectedSticker != null && toolbarTop != null && toolbarLeft != null)
              Positioned(
                top: toolbarTop,
                left: toolbarLeft,
                width: 260,
                height: 48,
                child: Center(
                  child: FloatingStickerToolbarWidget(
                    sticker: selectedSticker,
                    quillController: quillController,
                    editorMode: editorMode,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class FloatingStickerToolbarWidget extends ConsumerStatefulWidget {
  final FloatingStickerModel sticker;
  final QuillController? quillController;
  final EditorMode editorMode;

  const FloatingStickerToolbarWidget({
    super.key,
    required this.sticker,
    this.quillController,
    required this.editorMode,
  });

  @override
  ConsumerState<FloatingStickerToolbarWidget> createState() =>
      _FloatingStickerToolbarWidgetState();
}

class _FloatingStickerToolbarWidgetState
    extends ConsumerState<FloatingStickerToolbarWidget> {
  String _optionsMode = 'main'; // 'main', 'opacity'

  void _convertToInline() {
    final sticker = widget.sticker;
    ref.read(selectedStickerIdProvider.notifier).state = null;
    ref.read(floatingStickersProvider.notifier).removeSticker(sticker.id);

    if (widget.editorMode == EditorMode.gentleNote &&
        widget.quillController != null) {
      int index = widget.quillController!.selection.baseOffset;
      if (index < 0) {
        index = widget.quillController!.document.length - 1;
        if (index < 0) index = 0;
      }
      widget.quillController!
          .replaceText(index, 0, BlockEmbed('sticker', sticker.name), null);
    } else {
      final blockState = ref.read(editorBlockControllerProvider);
      final insertIndex = blockState.selectedIndex >= 0
          ? blockState.selectedIndex
          : blockState.blocks.length - 1;
      ref.read(editorBlockControllerProvider.notifier).insertBlock(
            insertIndex,
            BlockType.sticker,
            content: sticker.name,
          );
    }
  }

  void _deleteSticker() {
    ref.read(selectedStickerIdProvider.notifier).state = null;
    ref.read(floatingStickersProvider.notifier).removeSticker(widget.sticker.id);
  }

  Widget _divider(bool isDark) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.10),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sticker = widget.sticker;

    final bgColor = isDark
        ? const Color(0xFF13111C).withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.92);
    final borderColor =
        isDark ? const Color(0xFF332A54) : const Color(0xFFE5DEFA);
    final iconColor =
        isDark ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF1A1A2E);

    Widget smallBtn({
      required IconData icon,
      required VoidCallback onPressed,
      Color? color,
      String? tooltip,
    }) {
      final btn = InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color ?? iconColor),
        ),
      );
      return tooltip != null
          ? Tooltip(message: tooltip, child: btn)
          : btn;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: _optionsMode == 'opacity'
                ? Row(
                    key: const ValueKey('opacity_mode'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      smallBtn(
                        icon: Icons.arrow_back_ios_new,
                        tooltip: 'Back',
                        onPressed: () =>
                            setState(() => _optionsMode = 'main'),
                      ),
                      const SizedBox(width: 2),
                      SizedBox(
                        width: 120,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12),
                          ),
                          child: Slider(
                            value: sticker.opacity,
                            min: 0.1,
                            max: 1.0,
                            onChanged: (val) {
                              ref
                                  .read(floatingStickersProvider.notifier)
                                  .updateSticker(
                                      sticker.copyWith(opacity: val));
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${(sticker.opacity * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  )
                : Row(
                    key: const ValueKey('main_mode'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      smallBtn(
                        icon: sticker.hasBackground
                            ? Icons.layers_clear_outlined
                            : Icons.crop_din,
                        tooltip: sticker.hasBackground
                            ? 'Cutout style'
                            : 'Add background frame',
                        onPressed: () {
                          ref
                              .read(floatingStickersProvider.notifier)
                              .updateSticker(sticker.copyWith(
                                  hasBackground: !sticker.hasBackground));
                        },
                      ),
                      _divider(isDark),
                      smallBtn(
                        icon: Icons.opacity,
                        tooltip: 'Adjust opacity',
                        onPressed: () =>
                            setState(() => _optionsMode = 'opacity'),
                      ),
                      _divider(isDark),
                      smallBtn(
                        icon: sticker.textBehavior == 'over'
                            ? Icons.title
                            : Icons.text_fields_outlined,
                        tooltip: sticker.textBehavior == 'over'
                            ? 'Remove text overlay'
                            : 'Add text over sticker',
                        onPressed: () {
                          final next = sticker.textBehavior == 'over'
                              ? 'under'
                              : 'over';
                          ref
                              .read(floatingStickersProvider.notifier)
                              .updateSticker(
                                  sticker.copyWith(textBehavior: next));
                        },
                      ),
                      _divider(isDark),
                      smallBtn(
                        icon: Icons.vertical_align_center_rounded,
                        tooltip: 'Embed inline in text',
                        onPressed: _convertToInline,
                      ),
                      _divider(isDark),
                      smallBtn(
                        icon: Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        tooltip: 'Delete sticker',
                        onPressed: _deleteSticker,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
