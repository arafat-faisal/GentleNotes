import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../../models/models.dart';
import '../../../../../core/theme/font_helper.dart';
import '../../domain/entities/block_entity.dart';
import '../../../../core/utils/quill_paste_handler.dart';
import 'editor_blocks_list.dart';
import 'embeds/image_embed_builder.dart';
import 'embeds/audio_embed_builder.dart';
import 'embeds/horizontal_rule_embed_builder.dart';
import 'embeds/sticker_embed_builder.dart';
import 'embeds/photo_frame_embed_builder.dart';
import 'embeds/pdf_embed_builder.dart';
import '../controllers/floating_stickers_controller.dart';
import 'blocks/floating_stickers_overlay.dart';
import 'markdown/markdown_code_block.dart';

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
  final bool readOnly;

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
    this.readOnly = false,
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

    return FontHelper.getTextStyle(resolvedFamily, baseStyle: base);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final floatingStickers = ref.watch(floatingStickersProvider);
    final settings = ref.watch(settingsProvider);

    Widget editorContent;
    if (editorMode == EditorMode.gentleNote && quillController != null && editorFocusNode != null) {
      final activeCodeTheme = settings.activeCodeTheme;
      final isDarkCodeTheme = activeCodeTheme.contains('dark') || activeCodeTheme == 'monokai';

      final codeBlockBg = isDarkCodeTheme ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
      final codeBlockBorder = theme.colorScheme.outlineVariant.withValues(alpha: 0.5);
      final codeBlockTextColor = isDarkCodeTheme ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);

      final customStyles = DefaultStyles(
        inlineCode: InlineCodeStyle(
          backgroundColor: codeBlockBg,
          radius: const Radius.circular(4),
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 13,
            color: codeBlockTextColor,
          ),
        ),
        code: DefaultTextBlockStyle(
          TextStyle(
            fontFamily: 'Courier',
            fontSize: 13,
            height: 1.4,
            color: codeBlockTextColor,
          ),
          const HorizontalSpacing(0, 0),
          const VerticalSpacing(8, 8),
          const VerticalSpacing(0, 0),
          BoxDecoration(
            color: codeBlockBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: codeBlockBorder,
              width: 1,
            ),
          ),
        ),
      );

      // Guard readOnly assignment: setting it unconditionally inside build() fires
      // the controller's listeners every frame, creating an infinite setState loop.
      if (quillController!.readOnly != readOnly) {
        quillController!.readOnly = readOnly;
      }
      final quillConfig = QuillEditorConfig(
        placeholder: noteType == NoteType.mixed ? 'Write something beautiful...' : 'Start writing...',
        autoFocus: false,
        expands: true,
        padding: EdgeInsets.zero,
        customStyles: customStyles,
        embedBuilders: [
          ImageEmbedBuilder(),
          AudioEmbedBuilder(getAttachments: () => attachments),
          HorizontalRuleEmbedBuilder(key: 'horizontal-rule'),
          HorizontalRuleEmbedBuilder(key: 'divider'),
          StickerEmbedBuilder(),
          PhotoFrameEmbedBuilder(),
          PdfEmbedBuilder(),
        ],
        textSpanBuilder: (context, node, nodeOffset, text, style, recognizer) {
          final isCodeBlock = node.style.containsKey(Attribute.codeBlock.key) ||
              (node.parent?.style.containsKey(Attribute.codeBlock.key) ?? false);

          if (isCodeBlock) {
            String? language;
            Node? current = node;
            while (current != null) {
              if (current.style.containsKey('x-md-codeblock-lang')) {
                language = current.style.attributes['x-md-codeblock-lang']?.value as String?;
                break;
              }
              current = current.parent;
            }

            if (language == null && node.parent != null) {
              final parentNode = node.parent!;
              if (parentNode is Block) {
                for (final child in parentNode.children) {
                  if (child.style.containsKey('x-md-codeblock-lang')) {
                    language = child.style.attributes['x-md-codeblock-lang']?.value as String?;
                    break;
                  }
                }
              }
            }

            final highlighter = GentleSyntaxHighlighter(context, activeCodeTheme);
            final formatted = highlighter.format(text, language ?? 'code');

            return TextSpan(
              children: formatted.children,
              style: (style ?? const TextStyle()).copyWith(
                fontFamily: 'Courier',
                fontSize: 13,
                height: 1.4,
              ),
            );
          }

          return TextSpan(
            text: text,
            style: style,
            recognizer: recognizer,
            mouseCursor: (recognizer != null) ? SystemMouseCursors.click : null,
          );
        },
        customStyleBuilder: (attribute) {
          if (attribute.key == Attribute.font.key) {
            final fontVal = attribute.value;
            if (fontVal is String && fontVal.isNotEmpty) {
              return FontHelper.getTextStyle(fontVal);
            }
          }
          if (attribute.key == Attribute.size.key) {
            final sizeVal = attribute.value;
            double? fontSize;
            if (sizeVal is String) {
              fontSize = double.tryParse(sizeVal);
              if (fontSize == null) {
                if (sizeVal == 'small') {
                  fontSize = 12.0;
                } else if (sizeVal == 'large') fontSize = 20.0;
                else if (sizeVal == 'huge') fontSize = 28.0;
              }
            } else if (sizeVal is int) {
              fontSize = sizeVal.toDouble();
            } else if (sizeVal is double) {
              fontSize = sizeVal;
            }
            if (fontSize != null) return TextStyle(fontSize: fontSize);
          }
          return const TextStyle();
        },
      );

      final quillEditor = QuillEditor.basic(
        controller: quillController!,
        focusNode: editorFocusNode!,
        scrollController: scrollController,
        config: quillConfig,
      );


      editorContent = DefaultTextStyle(
        style: _getEditorStyle(
          settings,
          isDark ? Colors.white.withValues(alpha: 0.92) : const Color(0xFF1A1A2E),
        ),
        child: kIsWeb
            ? quillEditor
            : Actions(
                actions: <Type, Action<Intent>>{
                  PasteTextIntent: CallbackAction<PasteTextIntent>(
                    onInvoke: (intent) {
                      QuillPasteHandler.pasteFromClipboard(quillController!);
                      return null;
                    },
                  ),
                },
                child: quillEditor,
              ),
      );
    } else {
      editorContent = EditorBlocksList(
        blocks: blocks,
        focusNodes: focusNodes,
        scrollController: scrollController,
        isReorderable: isReorderable && !readOnly,
        readOnly: readOnly,
      );
    }


    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        editorContent,
        if (floatingStickers.isNotEmpty)
          Positioned.fill(
            child: FloatingStickersOverlay(
              scrollController: scrollController,
              quillController: quillController,
              editorMode: editorMode,
              readOnly: readOnly,
            ),
          ),
      ],
    );
  }
}
