import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../../../core/widgets/gentle_scaffold.dart';
import '../../../../core/utils/clipboard_helper.dart';
import '../../../../core/utils/quill_markdown_converter.dart';
import '../../../../models/models.dart';
import '../../../folders/data/folders_repository.dart';
import '../../../notes/data/notes_repository.dart';
import '../../../templates/data/templates_repository.dart';
import '../../../settings/data/settings_repository.dart';
import '../../../../services/export_import_service.dart';
import '../../../../services/pdf_export_service.dart';
import 'inline_audio_player.dart';


// Lightweight Markdown view wrapper to render markup
// Custom Markdown formatting handling and rendering system
class MarkdownWidget extends ConsumerWidget {
  final String data;
  final List<AttachmentModel> attachments;

  const MarkdownWidget({super.key, required this.data, required this.attachments});

  List<_CustomBlock> _parseContent(String content) {
    final List<_CustomBlock> blocks = [];
    final lines = content.split('\n');

    bool inCodeBlock = false;
    String codeLanguage = '';
    final List<String> currentCodeBlockLines = [];

    List<List<String>> currentTableRows = [];
    bool inTable = false;

    bool inMathBlock = false;
    final List<String> currentMathBlockLines = [];

    bool inDetails = false;
    String detailsSummary = 'Click to expand';
    final List<String> currentDetailsLines = [];

    final RegExp imageRegex = RegExp(r'!\[(.*?)\]\((.*?)\)');
    final RegExp hrRegex = RegExp(r'^\s*(\*|-|_)\s*\1\s*\1\s*(\1|\s)*$');

    for (var line in lines) {
      final trimmed = line.trim();

      // HTML details summary block
      if (trimmed.startsWith('<details>')) {
        inDetails = true;
        detailsSummary = 'Click to expand';
        continue;
      }
      if (inDetails) {
        if (trimmed.startsWith('<summary>') && trimmed.endsWith('</summary>')) {
          detailsSummary = trimmed.substring(9, trimmed.length - 10).trim();
          continue;
        }
        if (trimmed.startsWith('</details>')) {
          blocks.add(_CustomBlock(
            type: _BlockType.details,
            text: currentDetailsLines.join('\n'),
            altText: detailsSummary,
          ));
          currentDetailsLines.clear();
          inDetails = false;
          continue;
        }
        currentDetailsLines.add(line);
        continue;
      }

      // Block Math $$
      if (trimmed == '\$\$' || (trimmed.startsWith('\$\$') && trimmed.endsWith('\$\$') && trimmed.length > 2)) {
        if (inMathBlock) {
          blocks.add(_CustomBlock(
            type: _BlockType.math,
            text: currentMathBlockLines.join('\n'),
          ));
          currentMathBlockLines.clear();
          inMathBlock = false;
        } else {
          if (trimmed.startsWith('\$\$') && trimmed.endsWith('\$\$') && trimmed.length > 4) {
            final formula = trimmed.substring(2, trimmed.length - 2).trim();
            blocks.add(_CustomBlock(
              type: _BlockType.math,
              text: formula,
            ));
          } else {
            inMathBlock = true;
          }
        }
        continue;
      }

      if (inMathBlock) {
        currentMathBlockLines.add(line);
        continue;
      }

      // Fenced Code Blocks
      if (trimmed.startsWith('```')) {
        if (inCodeBlock) {
          blocks.add(_CustomBlock(
            type: _BlockType.code,
            text: currentCodeBlockLines.join('\n'),
            altText: codeLanguage,
          ));
          currentCodeBlockLines.clear();
          inCodeBlock = false;
        } else {
          inCodeBlock = true;
          codeLanguage = trimmed.substring(3).trim();
          if (codeLanguage.isEmpty) codeLanguage = 'code';
        }
        continue;
      }

      if (inCodeBlock) {
        currentCodeBlockLines.add(line);
        continue;
      }

      // Tables
      final isTableRow = trimmed.startsWith('|') && trimmed.endsWith('|');
      if (isTableRow) {
        if (!inTable) {
          inTable = true;
          currentTableRows = [];
        }
        final isDelimiter = RegExp(r'^\s*\|(?:\s*:?-+:?\s*\|)+\s*$').hasMatch(line);
        if (!isDelimiter) {
          final rawCells = line.split('|');
          if (rawCells.length > 2) {
            final cells = rawCells
                .sublist(1, rawCells.length - 1)
                .map((c) => c.trim())
                .toList();
            currentTableRows.add(cells);
          }
        }
        continue;
      } else {
        if (inTable) {
          if (currentTableRows.isNotEmpty) {
            blocks.add(_CustomBlock(
              type: _BlockType.table,
              text: '',
              tableData: List.from(currentTableRows),
            ));
          }
          currentTableRows.clear();
          inTable = false;
        }
      }

      // Horizontal Rules
      if (hrRegex.hasMatch(line)) {
        blocks.add(_CustomBlock(type: _BlockType.divider, text: ''));
        continue;
      }

      // Embedded HTML div block styling
      if (trimmed.startsWith('<div') && trimmed.endsWith('</div>')) {
        final content = trimmed.replaceAll(RegExp(r'<[^>]+>'), '').trim();
        blocks.add(_CustomBlock(type: _BlockType.paragraph, text: content));
        continue;
      }

      // Images
      final imageMatch = imageRegex.firstMatch(line);
      if (imageMatch != null) {
        final alt = imageMatch.group(1) ?? '';
        final url = imageMatch.group(2) ?? '';
        blocks.add(_CustomBlock(
          type: _BlockType.image,
          text: url,
          altText: alt,
        ));
        continue;
      }

      // Headings
      if (line.startsWith('# ')) {
        blocks.add(_CustomBlock(type: _BlockType.heading1, text: line.substring(2)));
      } else if (line.startsWith('## ')) {
        blocks.add(_CustomBlock(type: _BlockType.heading2, text: line.substring(3)));
      } else if (line.startsWith('### ')) {
        blocks.add(_CustomBlock(type: _BlockType.heading3, text: line.substring(4)));
      } else if (line.startsWith('#### ')) {
        blocks.add(_CustomBlock(type: _BlockType.heading4, text: line.substring(5)));
      } else if (line.startsWith('##### ')) {
        blocks.add(_CustomBlock(type: _BlockType.heading5, text: line.substring(6)));
      } else if (line.startsWith('###### ')) {
        blocks.add(_CustomBlock(type: _BlockType.heading6, text: line.substring(7)));
      }
      // Blockquotes
      else if (trimmed.startsWith('>')) {
        var content = trimmed;
        int level = 0;
        while (content.startsWith('>')) {
          level++;
          content = content.substring(1).trim();
        }
        blocks.add(_CustomBlock(
          type: _BlockType.blockquote,
          text: content,
          level: level,
        ));
      }
      // Checklists
      else if (trimmed.startsWith('- [ ]') || trimmed.startsWith('[ ]')) {
        final text = line.replaceFirst('- [ ]', '').replaceFirst('[ ]', '').trim();
        blocks.add(_CustomBlock(
          type: _BlockType.checklist,
          text: text,
          isChecked: false,
        ));
      } else if (trimmed.startsWith('- [x]') || trimmed.startsWith('[x]') || trimmed.startsWith('- [X]') || trimmed.startsWith('[X]')) {
        final text = line.replaceFirst('- [x]', '').replaceFirst('[x]', '').replaceFirst('- [X]', '').replaceFirst('[X]', '').trim();
        blocks.add(_CustomBlock(
          type: _BlockType.checklist,
          text: text,
          isChecked: true,
        ));
      }
      // Bullet lists
      else if (line.trimLeft().startsWith('- ') || line.trimLeft().startsWith('* ')) {
        final leadingSpaces = line.length - line.trimLeft().length;
        final text = line.trimLeft().substring(2);
        blocks.add(_CustomBlock(
          type: _BlockType.bullet,
          text: text,
          level: (leadingSpaces / 2).floor() + 1,
        ));
      }
      // Ordered lists
      else if (RegExp(r'^\s*(\d+)\.\s+(.*)').hasMatch(line)) {
        final match = RegExp(r'^\s*(\d+)\.\s+(.*)').firstMatch(line)!;
        final leadingSpaces = line.length - line.trimLeft().length;
        final num = match.group(1)!;
        final text = match.group(2)!;
        blocks.add(_CustomBlock(
          type: _BlockType.ordered,
          text: text,
          level: (leadingSpaces / 2).floor() + 1,
          altText: num,
        ));
      }
      // General paragraph
      else {
        if (trimmed.isEmpty) continue;
        blocks.add(_CustomBlock(type: _BlockType.paragraph, text: line));
      }
    }

    if (inTable && currentTableRows.isNotEmpty) {
      blocks.add(_CustomBlock(
        type: _BlockType.table,
        text: '',
        tableData: List.from(currentTableRows),
      ));
    }

    if (inCodeBlock && currentCodeBlockLines.isNotEmpty) {
      blocks.add(_CustomBlock(
        type: _BlockType.code,
        text: currentCodeBlockLines.join('\n'),
        altText: codeLanguage,
      ));
    }

    if (inMathBlock && currentMathBlockLines.isNotEmpty) {
      blocks.add(_CustomBlock(
        type: _BlockType.math,
        text: currentMathBlockLines.join('\n'),
      ));
    }

    return blocks;
  }

  Widget _buildBlockWidget(BuildContext context, _CustomBlock block, String activeCodeTheme, ThemeData theme) {
    final isDarkTheme = activeCodeTheme.contains('dark') || activeCodeTheme == 'monokai';

    switch (block.type) {
      case _BlockType.heading1:
        return Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: _renderInlineText(context, block.text, theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        );
      case _BlockType.heading2:
        return Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: _renderInlineText(context, block.text, theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        );
      case _BlockType.heading3:
        return Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: _renderInlineText(context, block.text, theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        );
      case _BlockType.heading4:
        return Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: _renderInlineText(context, block.text, theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        );
      case _BlockType.heading5:
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: _renderInlineText(context, block.text, theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        );
      case _BlockType.heading6:
        return Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 4),
          child: _renderInlineText(context, block.text, theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        );
      case _BlockType.divider:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Divider(thickness: 1.5, color: theme.colorScheme.outlineVariant),
        );
      case _BlockType.blockquote:
        return Padding(
          padding: EdgeInsets.only(left: 12.0 * block.level, top: 8, bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.5),
                  width: 3.5,
                ),
              ),
              color: theme.colorScheme.surfaceVariant.withOpacity(0.15),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _renderInlineText(context, block.text, theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant)),
          ),
        );
      case _BlockType.bullet:
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
                child: _renderInlineText(context, block.text, theme.textTheme.bodyMedium),
              ),
            ],
          ),
        );
      case _BlockType.ordered:
        return Padding(
          padding: EdgeInsets.only(left: 16.0 * block.level, top: 4, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${block.altText}. ', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              Expanded(
                child: _renderInlineText(context, block.text, theme.textTheme.bodyMedium),
              ),
            ],
          ),
        );
      case _BlockType.checklist:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                block.isChecked! ? Icons.check_box : Icons.check_box_outline_blank,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _renderInlineText(
                  context,
                  block.text,
                  theme.textTheme.bodyMedium?.copyWith(
                    decoration: block.isChecked! ? TextDecoration.lineThrough : null,
                    color: block.isChecked! ? theme.colorScheme.onSurface.withOpacity(0.5) : null,
                  ),
                ),
              ),
            ],
          ),
        );
      case _BlockType.math:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
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
      case _BlockType.details:
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
      case _BlockType.code:
        final codeText = block.text;
        final language = block.altText ?? 'code';
        final highlighter = GentleSyntaxHighlighter(context, activeCodeTheme);
        final formattedSpan = highlighter.format(codeText);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDarkTheme ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      language.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: isDarkTheme ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: codeText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code copied to clipboard!'),
                            duration: Duration(seconds: 1),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.copy_rounded,
                            size: 12,
                            color: isDarkTheme ? Colors.grey.shade400 : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'COPY',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isDarkTheme ? Colors.grey.shade400 : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText.rich(
                    formattedSpan,
                  ),
                ),
              ),
            ],
          ),
        );
      case _BlockType.table:
        if (block.tableData == null || block.tableData!.isEmpty) return const SizedBox();
        final headers = block.tableData!.first;
        final rows = block.tableData!.skip(1).toList();

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(theme.colorScheme.surfaceVariant.withOpacity(0.3)),
              columns: headers.map((h) {
                return DataColumn(
                  label: _renderInlineText(context, h, theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                );
              }).toList(),
              rows: rows.map((row) {
                return DataRow(
                  cells: row.map((cell) {
                    return DataCell(
                      _renderInlineText(context, cell, theme.textTheme.bodyMedium),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        );
      case _BlockType.image:
        return _buildImageBlock(block);
      case _BlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: _renderInlineText(context, block.text, theme.textTheme.bodyMedium),
        );
    }
  }

  Widget _renderInlineText(BuildContext context, String text, TextStyle? baseStyle, {TextAlign textAlign = TextAlign.start}) {
    // Parse alignment from <div align="..."> HTML wrapper (Fix 4)
    TextAlign align = textAlign;
    String processedText = text;
    final divAlignMatch = RegExp(r'<div\s+align="(left|center|right|justify)">([\s\S]*?)</div>', caseSensitive: false).firstMatch(text);
    if (divAlignMatch != null) {
      final alignStr = divAlignMatch.group(1)!;
      processedText = divAlignMatch.group(2)!;
      switch (alignStr) {
        case 'center': align = TextAlign.center; break;
        case 'right': align = TextAlign.right; break;
        case 'justify': align = TextAlign.justify; break;
        default: align = TextAlign.left;
      }
    }
    final spans = _parseInlineSpans(context, processedText, baseStyle ?? const TextStyle());
    return RichText(
      text: TextSpan(children: spans),
      textAlign: align,
      textWidthBasis: TextWidthBasis.parent,
    );
  }

  List<InlineSpan> _parseInlineSpans(BuildContext context, String text, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];
    // Extended regex: adds <mark>, <span style="color:">, <u>, ~~, **, *, `, links
    final RegExp inlineRegex = RegExp(
      r'(\*\*\*.*?\*\*\*|\*\*.*?\*\*|\*.*?\*|~~.*?~~|`.*?`|<u>.*?</u>|<mark[^>]*>.*?</mark>|<span[^>]*>.*?</span>|\[.*?\]\(.*?\)|https?://\S+)',
      dotAll: true,
    );

    int lastIndex = 0;
    for (final match in inlineRegex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      final token = match.group(1)!;

      if (token.startsWith('***') && token.endsWith('***')) {
        spans.addAll(_parseInlineSpans(
          context,
          token.substring(3, token.length - 3),
          baseStyle.copyWith(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
        ));
      } else if (token.startsWith('**') && token.endsWith('**')) {
        spans.addAll(_parseInlineSpans(
          context,
          token.substring(2, token.length - 2),
          baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (token.startsWith('*') && token.endsWith('*')) {
        spans.addAll(_parseInlineSpans(
          context,
          token.substring(1, token.length - 1),
          baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (token.startsWith('~~') && token.endsWith('~~')) {
        spans.addAll(_parseInlineSpans(
          context,
          token.substring(2, token.length - 2),
          baseStyle.copyWith(decoration: TextDecoration.lineThrough),
        ));
      } else if (token.startsWith('`') && token.endsWith('`')) {
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: (baseStyle.fontSize ?? 14) - 1,
            backgroundColor: Colors.grey.shade200,
            color: Colors.red.shade800,
          ),
        ));
      } else if (token.startsWith('<u>') && token.endsWith('</u>')) {
        spans.addAll(_parseInlineSpans(
          context,
          token.substring(3, token.length - 4),
          baseStyle.copyWith(decoration: TextDecoration.underline),
        ));
      } else if (token.startsWith('<mark')) {
        // Parse: <mark style="background:#HEX">text</mark>
        final bgMatch = RegExp(r'background[:\s]*([#\w]+)').firstMatch(token);
        final innerMatch = RegExp(r'<mark[^>]*>(.*?)</mark>', dotAll: true).firstMatch(token);
        final innerText = innerMatch?.group(1) ?? token;
        Color bgColor = const Color(0xFFFFFF00);
        if (bgMatch != null) {
          final hexStr = bgMatch.group(1)!.replaceAll('#', '');
          if (hexStr.length == 6) bgColor = Color(int.parse('FF$hexStr', radix: 16));
        }
        spans.addAll(_parseInlineSpans(
          context, 
          innerText, 
          baseStyle.copyWith(backgroundColor: bgColor),
        ));
      } else if (token.startsWith('<span')) {
        // Parse: <span style="color:#HEX">text</span>
        final colorMatch = RegExp(r'color[:\s]*([#\w]+)').firstMatch(token);
        final innerMatch = RegExp(r'<span[^>]*>(.*?)</span>', dotAll: true).firstMatch(token);
        final innerText = innerMatch?.group(1) ?? token;
        Color textColor = baseStyle.color ?? Colors.black;
        if (colorMatch != null) {
          final hexStr = colorMatch.group(1)!.replaceAll('#', '');
          if (hexStr.length == 6) textColor = Color(int.parse('FF$hexStr', radix: 16));
        }
        spans.addAll(_parseInlineSpans(
          context, 
          innerText, 
          baseStyle.copyWith(color: textColor),
        ));
      } else if (token.startsWith('[') && token.contains('](')) {
        final closingBrace = token.indexOf(']');
        final label = token.substring(1, closingBrace);
        final url = token.substring(closingBrace + 2, token.length - 1);
        if (url.startsWith('audio://')) {
          final attachmentId = url.replaceFirst('audio://', '');
          final attachment = attachments.cast<AttachmentModel?>().firstWhere(
                (a) => a?.id == attachmentId,
                orElse: () => null,
              );
          if (attachment != null) {
            spans.add(WidgetSpan(
              child: InlineAudioPlayer(
                filePath: attachment.pathOrUrl,
                name: attachment.name,
              ),
            ));
          } else {
            spans.add(TextSpan(
              text: label,
              style: baseStyle.copyWith(color: Colors.red, decoration: TextDecoration.lineThrough),
            ));
          }
        } else {
          spans.add(WidgetSpan(
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening Link: $url'),
                    backgroundColor: Colors.blue,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Text(
                label,
                style: baseStyle.copyWith(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ));
        }
      } else {
        spans.add(WidgetSpan(
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening Link: $token'),
                  backgroundColor: Colors.blue,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Text(
              token,
              style: baseStyle.copyWith(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return spans;
  }

  Widget _buildImageBlock(_CustomBlock block) {
    var uriStr = block.text;

    if (uriStr.startsWith('attachment://')) {
      final attachmentId = uriStr.replaceFirst('attachment://', '');
      final attachment = attachments.cast<AttachmentModel?>().firstWhere(
            (a) => a?.id == attachmentId,
            orElse: () => null,
          );
      if (attachment != null) {
        uriStr = attachment.pathOrUrl;
      }
    }

    final altTextRaw = block.altText ?? '';
    String size = 'medium';
    String align = 'center';

    if (altTextRaw.contains('|')) {
      final parts = altTextRaw.split('|');
      for (var part in parts.skip(1)) {
        final trimmed = part.trim();
        if (trimmed.startsWith('size=')) {
          size = trimmed.substring('size='.length).trim();
        } else if (trimmed.startsWith('align=')) {
          align = trimmed.substring('align='.length).trim();
        }
      }
    }

    double? width;
    double? height;
    if (size == 'small') {
      width = 200;
      height = 150;
    } else if (size == 'large') {
      width = double.infinity;
    } else {
      width = 400;
      height = 300;
    }

    Alignment alignment = Alignment.center;
    if (align == 'left') {
      alignment = Alignment.centerLeft;
    } else if (align == 'right') {
      alignment = Alignment.centerRight;
    }

    Widget imageWidget;

    if (uriStr.startsWith('data:image')) {
      try {
        final base64Str = uriStr.split(',').last;
        final bytes = base64Decode(base64Str);
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey);
            },
          ),
        );
      } catch (e) {
        imageWidget = const Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey);
      }
    } else if (uriStr.startsWith('file://')) {
      final filePath = uriStr.replaceFirst('file://', '');
      if (kIsWeb) {
        imageWidget = const Text('[Local Image (Unavailable on Web)]');
      } else {
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            io.File(filePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey);
            },
          ),
        );
      }
    } else {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          uriStr,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey);
          },
        ),
      );
    }

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          width: width,
          height: size == 'large' ? null : height,
          constraints: size == 'large' ? const BoxConstraints(maxHeight: 450) : null,
          child: imageWidget,
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
          return _buildBlockWidget(context, block, activeCodeTheme, theme);
        },
      ),
    );
  }
}

enum _BlockType {
  paragraph,
  heading1,
  heading2,
  heading3,
  heading4,
  heading5,
  heading6,
  code,
  bullet,
  ordered,
  checklist,
  image,
  divider,
  blockquote,
  table,
  details,
  math;
}

class _CustomBlock {
  final _BlockType type;
  final String text;
  final String? altText;
  final bool? isChecked;
  final int level;
  final List<List<String>>? tableData;

  _CustomBlock({
    required this.type,
    required this.text,
    this.altText,
    this.isChecked,
    this.level = 0,
    this.tableData,
  });
}

class GentleSyntaxHighlighter {
  final BuildContext context;
  final String theme;

  GentleSyntaxHighlighter(this.context, this.theme);

  TextSpan format(String code) {
    final List<TextSpan> spans = [];
    final lines = code.split('\n');
    final isDark = theme.contains('dark') || theme == 'monokai';

    final keywordStyle = TextStyle(color: isDark ? const Color(0xFFF97316) : const Color(0xFFC2410C), fontWeight: FontWeight.bold);
    final stringStyle = TextStyle(color: isDark ? const Color(0xFF10B981) : const Color(0xFF047857));
    final commentStyle = TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B), fontStyle: FontStyle.italic);
    final numberStyle = TextStyle(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1));
    final defaultStyle = TextStyle(color: isDark ? Colors.white : Colors.black87);

    final keywords = {
      'class', 'struct', 'enum', 'void', 'int', 'double', 'float', 'bool', 'string', 'final', 'const',
      'var', 'let', 'function', 'def', 'import', 'from', 'as', 'return', 'if', 'else', 'for', 'while',
      'switch', 'case', 'break', 'continue', 'true', 'false', 'null', 'package', 'public',
      'private', 'protected', 'extends', 'implements', 'override', 'async', 'await', 'yield'
    };

    final keywordRegex = RegExp('\\b(${keywords.join('|')})\\b');
    final stringRegex = RegExp(r"'(.*?)'|&quot;(.*?)&quot;|\u0022(.*?)\u0022");
    final numberRegex = RegExp(r'\b\d+(\.\d+)?\b');
    final commentRegex = RegExp(r'//.*|#.*|/\*[\s\S]*?\*/');

    final combinedRegex = RegExp(
      '(${commentRegex.pattern})|(${stringRegex.pattern})|(${keywordRegex.pattern})|(${numberRegex.pattern})',
      multiLine: true,
    );

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      int lastIndex = 0;

      for (final match in combinedRegex.allMatches(line)) {
        if (match.start > lastIndex) {
          spans.add(TextSpan(text: line.substring(lastIndex, match.start), style: defaultStyle));
        }

        final matchedText = match.group(0)!;
        if (match.group(1) != null) {
          spans.add(TextSpan(text: matchedText, style: commentStyle));
        } else if (match.group(2) != null) {
          spans.add(TextSpan(text: matchedText, style: stringStyle));
        } else if (match.group(5) != null) {
          spans.add(TextSpan(text: matchedText, style: keywordStyle));
        } else {
          if (keywords.contains(matchedText)) {
            spans.add(TextSpan(text: matchedText, style: keywordStyle));
          } else if (double.tryParse(matchedText) != null) {
            spans.add(TextSpan(text: matchedText, style: numberStyle));
          } else {
            spans.add(TextSpan(text: matchedText, style: defaultStyle));
          }
        }
        lastIndex = match.end;
      }

      if (lastIndex < line.length) {
        spans.add(TextSpan(text: line.substring(lastIndex), style: defaultStyle));
      }

      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return TextSpan(children: spans, style: const TextStyle(fontFamily: 'Courier', fontSize: 13));
  }
}

