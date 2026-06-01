import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../../models/models.dart';
import '../../domain/entities/block_entity.dart';
import '../../../../core/utils/quill_paste_handler.dart';
import 'editor_blocks_list.dart';
import 'embeds/image_embed_builder.dart';
import 'embeds/audio_embed_builder.dart';
import 'embeds/horizontal_rule_embed_builder.dart';

class EditorBodyWidget extends StatelessWidget {
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

  double get _currentFontHeight {
    return noteType == NoteType.mixed ? 1.75 : 1.5;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (editorMode == EditorMode.gentleNote && quillController != null && editorFocusNode != null) {
      return DefaultTextStyle(
        style: TextStyle(
          fontFamily: _currentFontFamily,
          fontSize: 16,
          height: _currentFontHeight,
          color: isDark ? Colors.white.withOpacity(0.92) : const Color(0xFF1A1A2E),
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
    }

    return EditorBlocksList(
      blocks: blocks,
      focusNodes: focusNodes,
      scrollController: scrollController,
      isReorderable: isReorderable,
    );
  }
}
