import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../../models/models.dart';
import '../../domain/entities/block_entity.dart';
import '../../../../core/utils/quill_paste_handler.dart';
import 'editor_blocks_list.dart';
import 'embeds/image_embed_builder.dart';
import 'embeds/audio_embed_builder.dart';
import 'embeds/horizontal_rule_embed_builder.dart';
import 'embeds/sticker_embed_builder.dart';
import '../controllers/floating_stickers_controller.dart';
import 'blocks/floating_stickers_overlay.dart';

class EditorBodyWidget extends ConsumerWidget {
  final EditorMode editorMode;
  final QuillController? quillController;
  final FocusNode? editorFocusNode;
  final NoteType noteType;
  final List<AttachmentModel> attachments;
  final List<BlockEntity> blocks;
  final Map<String, FocusNode> focusNodes;
  final ScrollController scrollController;
  final bool isReorderable;

  const EditorBodyWidget({
    super.key,
    required this.editorMode,
    this.quillController,
    this.editorFocusNode,
    required this.noteType,
    required this.attachments,
    required this.blocks,
    required this.focusNodes,
    required this.scrollController,
    this.isReorderable = true,
  });

  String get _currentFontFamily {
    return noteType == NoteType.mixed
        ? 'Georgia'
        : (noteType == NoteType.code ? 'Courier' : 'Inter');
  }

  TextStyle _getEditorStyle(AppSettingsModel settings, Color color) {
    final family = settings.editorFontFamily;
    final size = settings.editorFontSize;
    final height = settings.editorLineHeight;

    final resolvedFamily = family == 'System' ? _currentFontFamily : family;
    final base = TextStyle(fontSize: size, height: height, color: color);

    switch (resolvedFamily) {
      case 'Inter':
        return GoogleFonts.inter(textStyle: base);
      case 'Outfit':
        return GoogleFonts.outfit(textStyle: base);
      case 'Roboto Mono':
        return GoogleFonts.robotoMono(textStyle: base);
      case 'Lora':
        return GoogleFonts.lora(textStyle: base);
      case 'Lexend':
        return GoogleFonts.lexend(textStyle: base);
      case 'Georgia':
        return base.copyWith(fontFamily: 'Georgia');
      case 'Courier':
      case 'Courier New':
        return base.copyWith(fontFamily: 'Courier');
      default:
        return base.copyWith(fontFamily: resolvedFamily);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final floatingStickers = ref.watch(floatingStickersProvider);
    final settings = ref.watch(settingsProvider);

    Widget editorContent;
    if (editorMode == EditorMode.gentleNote && quillController != null && editorFocusNode != null) {
      editorContent = DefaultTextStyle(
        style: _getEditorStyle(
          settings,
          isDark ? Colors.white.withOpacity(0.92) : const Color(0xFF1A1A2E),
        ),
        child: Actions(
          actions: <Type, Action<Intent>>{
            PasteTextIntent: CallbackAction<PasteTextIntent>(
              onInvoke: (intent) {
                Clipboard.getData(Clipboard.kTextPlain).then((data) {
                  if (data != null && data.text != null) {
                    QuillPasteHandler.handlePasteText(quillController!, data.text!);
                  }
                });
                return null;
              },
            ),
          },
          child: QuillEditor.basic(
            controller: quillController!,
            focusNode: editorFocusNode!,
            scrollController: scrollController,
            config: QuillEditorConfig(
              placeholder: noteType == NoteType.mixed ? 'Write something beautiful...' : 'Start writing...',
              autoFocus: false,
              expands: true,
              padding: EdgeInsets.zero,
              embedBuilders: [
                ImageEmbedBuilder(),
                AudioEmbedBuilder(getAttachments: () => attachments),
                HorizontalRuleEmbedBuilder(key: 'horizontal-rule'),
                HorizontalRuleEmbedBuilder(key: 'divider'),
                StickerEmbedBuilder(),
              ],
              customActions: <Type, Action<Intent>>{
                PasteTextIntent: CallbackAction<PasteTextIntent>(
                  onInvoke: (intent) {
                    Clipboard.getData(Clipboard.kTextPlain).then((data) {
                      if (data != null && data.text != null) {
                        QuillPasteHandler.handlePasteText(quillController!, data.text!);
                      }
                    });
                    return null;
                  },
                ),
              },
            ),
          ),
        ),
      );
    } else {
      editorContent = EditorBlocksList(
        blocks: blocks,
        focusNodes: focusNodes,
        scrollController: scrollController,
        isReorderable: isReorderable,
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: editorContent),
        if (floatingStickers.isNotEmpty)
          Positioned.fill(
            child: FloatingStickersOverlay(
              scrollController: scrollController,
              quillController: quillController,
              editorMode: editorMode,
            ),
          ),
      ],
    );
  }
}
