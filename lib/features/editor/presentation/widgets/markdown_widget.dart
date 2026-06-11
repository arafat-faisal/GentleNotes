import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/models.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import 'markdown/markdown_checklist_renderer.dart';
import 'markdown/markdown_code_block.dart';
import 'markdown/markdown_error_view.dart';
import 'markdown/markdown_image_renderer.dart';
import 'markdown/markdown_renderer.dart';
import 'markdown/markdown_style_builder.dart';
import 'markdown/markdown_table_renderer.dart';
import 'markdown/markdown_parser.dart';

class MarkdownWidget extends ConsumerWidget {
  final String data;
  final List<AttachmentModel> attachments;
  final String? fontFamily;

  const MarkdownWidget({super.key, required this.data, required this.attachments, this.fontFamily});

  List<MarkdownCustomBlock> _parseContent(String content) => MarkdownParser.parse(content);

  Widget _buildBlockWidget(BuildContext context, MarkdownCustomBlock block, String activeCodeTheme, ThemeData theme) {
    final isDarkTheme = activeCodeTheme.contains('dark') || activeCodeTheme == 'monokai';

    switch (block.type) {
      case MarkdownBlockType.heading1:
        return Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: MarkdownStyleBuilder.renderInlineText(context, block.text, theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface), fontFamily: fontFamily, attachments: attachments),
        );
      case MarkdownBlockType.heading2:
        return Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: MarkdownStyleBuilder.renderInlineText(context, block.text, theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface), fontFamily: fontFamily, attachments: attachments),
        );
      case MarkdownBlockType.heading3:
        return Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: MarkdownStyleBuilder.renderInlineText(context, block.text, theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface), fontFamily: fontFamily, attachments: attachments),
        );
      case MarkdownBlockType.heading4:
        return Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: MarkdownStyleBuilder.renderInlineText(context, block.text, theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface), fontFamily: fontFamily, attachments: attachments),
        );
      case MarkdownBlockType.heading5:
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: MarkdownStyleBuilder.renderInlineText(context, block.text, theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface), fontFamily: fontFamily, attachments: attachments),
        );
      case MarkdownBlockType.heading6:
        return Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 4),
          child: MarkdownStyleBuilder.renderInlineText(context, block.text, theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface), fontFamily: fontFamily, attachments: attachments),
        );
      case MarkdownBlockType.divider:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Divider(thickness: 1.5, color: theme.colorScheme.outlineVariant),
        );
      case MarkdownBlockType.blockquote:
        final innerBlocks = _parseContent(block.text);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  width: 3.5,
                ),
              ),
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
            ),
            padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8, right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: innerBlocks.map((subBlock) {
                return _buildBlockWidget(context, subBlock, activeCodeTheme, theme);
              }).toList(),
            ),
          ),
        );
      case MarkdownBlockType.bullet:
        return Padding(
          padding: EdgeInsets.only(left: 16.0 * block.level, top: 4, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6, right: 8),
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: MarkdownStyleBuilder.renderInlineText(context, block.text, theme.textTheme.bodyMedium, fontFamily: fontFamily, attachments: attachments),
              ),
            ],
          ),
        );
      case MarkdownBlockType.ordered:
        return Padding(
          padding: EdgeInsets.only(left: 16.0 * block.level, top: 4, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${block.altText}. ', style: (theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold) ?? const TextStyle()).copyWith(fontFamily: fontFamily)),
              Expanded(
                child: MarkdownStyleBuilder.renderInlineText(context, block.text, theme.textTheme.bodyMedium, fontFamily: fontFamily, attachments: attachments),
              ),
            ],
          ),
        );
      case MarkdownBlockType.checklist:
        return MarkdownChecklistRenderer(block: block, fontFamily: fontFamily, attachments: attachments);
      case MarkdownBlockType.math:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calculate_outlined, size: 14, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text(
                        'FORMULA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: isDarkTheme ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: block.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Formula copied to clipboard!'),
                          duration: Duration(seconds: 1),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    },
                    child: Text(
                      'COPY',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isDarkTheme ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: SelectableText(
                  block.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Georgia',
                    color: isDarkTheme ? Colors.white : Colors.black,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      case MarkdownBlockType.details:
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: ExpansionTile(
            title: Text(
              block.altText ?? 'Click to expand',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SelectionArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _parseContent(block.text).map((subBlock) {
                      return _buildBlockWidget(context, subBlock, activeCodeTheme, theme);
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      case MarkdownBlockType.code:
        return MarkdownCodeBlock(block: block, activeCodeTheme: activeCodeTheme);
      case MarkdownBlockType.table:
        return MarkdownTableRenderer(block: block, fontFamily: fontFamily, attachments: attachments);
      case MarkdownBlockType.image:
        return MarkdownImageRenderer(block: block, attachments: attachments);
      case MarkdownBlockType.sticker:
        return _buildStickerBlock(block.text);
      case MarkdownBlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: MarkdownStyleBuilder.renderInlineText(context, block.text, theme.textTheme.bodyMedium, fontFamily: fontFamily, attachments: attachments),
        );
    }
  }

  Widget _buildStickerBlock(String stickerName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: SizedBox(
          width: 120,
          height: 120,
          child: Image.asset(
            'assets/images/stickers/$stickerName.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.sticky_note_2_outlined, size: 48, color: Colors.grey);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final activeCodeTheme = settings.activeCodeTheme;
    final theme = Theme.of(context);

    final blocks = _parseContent(data);

    return SelectionArea(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: blocks.length,
        itemBuilder: (context, index) {
          final block = blocks[index];
          try {
            return _buildBlockWidget(context, block, activeCodeTheme, theme);
          } catch (e, stack) {
            debugPrint('Error rendering block: $e\n$stack');
            return MarkdownErrorView(block: block);
          }
        },
      ),
    );
  }
}
