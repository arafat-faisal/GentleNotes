import 'dart:convert';
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

class MarkdownWidget extends ConsumerWidget {
  final String data;
  final List<AttachmentModel> attachments;
  final String? fontFamily;

  const MarkdownWidget({super.key, required this.data, required this.attachments, this.fontFamily});

  List<MarkdownCustomBlock> _parseContent(String content) {
    final List<MarkdownCustomBlock> blocks = [];
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
    
    bool inBlockquote = false;
    final List<String> currentBlockquoteLines = [];

    bool inDiv = false;
    String divStyle = '';
    final List<String> currentDivLines = [];

    final RegExp imageRegex = RegExp(r'!\[(.*?)\]\((.*?)\)');
    final RegExp hrRegex = RegExp(r'^\s*(\*|-|_)\s*\1\s*\1\s*(\1|\s)*$');

    for (var line in lines) {
      final trimmed = line.trim();

      // HTML details summary block
      if (trimmed.startsWith(RegExp(r'<details\s*>', caseSensitive: false))) {
        if (inBlockquote) {
          blocks.add(MarkdownCustomBlock(type: MarkdownBlockType.blockquote, text: currentBlockquoteLines.join('\n')));
          currentBlockquoteLines.clear();
          inBlockquote = false;
        }
        inDetails = true;
        detailsSummary = 'Click to expand';
        continue;
      }
      if (inDetails) {
        if (trimmed.startsWith(RegExp(r'<summary\s*>', caseSensitive: false)) && trimmed.endsWith('</summary>')) {
          final summaryMatch = RegExp(r'<summary\s*>(.*?)</summary>', caseSensitive: false).firstMatch(trimmed);
          detailsSummary = summaryMatch?.group(1)?.trim() ?? 'Click to expand';
          continue;
        }
        if (trimmed.startsWith(RegExp(r'</details\s*>', caseSensitive: false))) {
          blocks.add(MarkdownCustomBlock(
            type: MarkdownBlockType.details,
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
        if (inBlockquote) {
          blocks.add(MarkdownCustomBlock(type: MarkdownBlockType.blockquote, text: currentBlockquoteLines.join('\n')));
          currentBlockquoteLines.clear();
          inBlockquote = false;
        }
        if (inMathBlock) {
          blocks.add(MarkdownCustomBlock(
            type: MarkdownBlockType.math,
            text: currentMathBlockLines.join('\n'),
          ));
          currentMathBlockLines.clear();
          inMathBlock = false;
        } else {
          if (trimmed.startsWith('\$\$') && trimmed.endsWith('\$\$') && trimmed.length > 4) {
            final formula = trimmed.substring(2, trimmed.length - 2).trim();
            blocks.add(MarkdownCustomBlock(
              type: MarkdownBlockType.math,
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
        if (inBlockquote) {
          blocks.add(MarkdownCustomBlock(type: MarkdownBlockType.blockquote, text: currentBlockquoteLines.join('\n')));
          currentBlockquoteLines.clear();
          inBlockquote = false;
        }
        if (inCodeBlock) {
          blocks.add(MarkdownCustomBlock(
            type: MarkdownBlockType.code,
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

      // Multi-line HTML Div Block collector
      if (trimmed.startsWith(RegExp(r'<div\s', caseSensitive: false)) && !trimmed.endsWith('</div>') && !inDiv) {
        if (inBlockquote) {
          blocks.add(MarkdownCustomBlock(type: MarkdownBlockType.blockquote, text: currentBlockquoteLines.join('\n')));
          currentBlockquoteLines.clear();
          inBlockquote = false;
        }
        inDiv = true;
        final styleMatch = RegExp(r'style="([^"]*)"', caseSensitive: false).firstMatch(line);
        divStyle = styleMatch?.group(1) ?? '';
        continue;
      }

      if (inDiv) {
        if (trimmed.contains('</div>')) {
          final parts = line.split('</div>');
          if (parts.first.isNotEmpty) {
            currentDivLines.add(parts.first);
          }
          final rawText = currentDivLines.join('\n');
          String processedText = rawText;
          
          final style = divStyle.toLowerCase();
          if (style.contains('color:')) {
            final colorMatch = RegExp(r'color[:\s]*([#\w]+)').firstMatch(style);
            if (colorMatch != null) {
              processedText = '<span style="color:${colorMatch.group(1)}">$processedText</span>';
            }
          }
          if (style.contains('font-weight: bold') || style.contains('font-weight:bold')) {
            processedText = '**$processedText**';
          }
          if (style.contains('font-style: italic') || style.contains('font-style:italic')) {
            processedText = '*$processedText*';
          }
          if (style.contains('text-decoration: underline') || style.contains('text-decoration:underline')) {
            processedText = '<u>$processedText</u>';
          }
          if (style.contains('text-align:')) {
            final alignMatch = RegExp(r'text-align[:\s]*(left|center|right|justify)').firstMatch(style);
            if (alignMatch != null) {
              processedText = '<div align="${alignMatch.group(1)}">$processedText</div>';
            }
          }

          blocks.add(MarkdownCustomBlock(type: MarkdownBlockType.paragraph, text: processedText));
          currentDivLines.clear();
          inDiv = false;
          continue;
        }
        currentDivLines.add(line);
        continue;
      }

      // Blockquotes collector (groups consecutive blockquotes)
      if (trimmed.startsWith('>')) {
        inBlockquote = true;
        String rest = trimmed.substring(1);
        if (rest.startsWith(' ')) rest = rest.substring(1);
        currentBlockquoteLines.add(rest);
        continue;
      } else {
        if (inBlockquote) {
          blocks.add(MarkdownCustomBlock(
            type: MarkdownBlockType.blockquote,
            text: currentBlockquoteLines.join('\n'),
          ));
          currentBlockquoteLines.clear();
          inBlockquote = false;
        }
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
            blocks.add(MarkdownCustomBlock(
              type: MarkdownBlockType.table,
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
        blocks.add(MarkdownCustomBlock(type: MarkdownBlockType.divider, text: ''));
        continue;
      }

      // Single line HTML div block styling
      if (trimmed.startsWith(RegExp(r'<div\s', caseSensitive: false)) && trimmed.endsWith('</div>')) {
        final styleMatch = RegExp(r'style="([^"]*)"', caseSensitive: false).firstMatch(line);
        final style = styleMatch?.group(1) ?? '';
        final innerMatch = RegExp(r'<div[^>]*>([\s\S]*?)</div>', caseSensitive: false).firstMatch(trimmed);
        String innerText = innerMatch?.group(1) ?? trimmed.replaceAll(RegExp(r'<[^>]+>', caseSensitive: false), '').trim();
        
        String processedText = innerText;
        if (style.isNotEmpty) {
          final s = style.toLowerCase();
          if (s.contains('color:')) {
            final colorMatch = RegExp(r'color[:\s]*([#\w]+)').firstMatch(s);
            if (colorMatch != null) {
              processedText = '<span style="color:${colorMatch.group(1)}">$processedText</span>';
            }
          }
          if (s.contains('font-weight: bold') || s.contains('font-weight:bold')) {
            processedText = '**$processedText**';
          }
          if (s.contains('font-style: italic') || s.contains('font-style:italic')) {
            processedText = '*$processedText*';
          }
          if (s.contains('text-decoration: underline') || s.contains('text-decoration:underline')) {
            processedText = '<u>$processedText</u>';
          }
          if (s.contains('text-align:')) {
            final alignMatch = RegExp(r'text-align[:\s]*(left|center|right|justify)').firstMatch(s);
            if (alignMatch != null) {
              processedText = '<div align="${alignMatch.group(1)}">$processedText</div>';
            }
          }
        }
        blocks.add(MarkdownCustomBlock(type: MarkdownBlockType.paragraph, text: processedText));
        continue;
      }

      // Stickers
      final stickerMatch = RegExp(r'^!\[sticker:(.*?)\]\(sticker://(.*?)\)$').firstMatch(trimmed);
      if (stickerMatch != null) {
        final stickerName = stickerMatch.group(2) ?? '';
        blocks.add(MarkdownCustomBlock(
          type: MarkdownBlockType.sticker,
          text: stickerName,
        ));
        continue;
      }

      // Images
      final imageMatch = imageRegex.firstMatch(line);
      if (imageMatch != null) {
        final alt = imageMatch.group(1) ?? '';
        final url = imageMatch.group(2) ?? '';
        blocks.add(MarkdownCustomBlock(
          type: MarkdownBlockType.image,
          text: url,
          altText: alt,
        ));
        continue;
      }

      // Headings
      if (trimmed.startsWith('# ')) {
        blocks.add(MarkdownCustomBlock(type: MarkdownBlockType.heading1, text: trimmed.substring(2)));
      } else if (trimmed.startsWith('## ')) {
        blocks.add(MarkdownCustomBlock(type: MarkdownBlockType.heading2, text: trimmed.substring(3)));
      } else if (trimmed.startsWith('### ')) {
        blocks.add(MarkdownCustomBlock(type: MarkdownBlockType.heading3, text: trimmed.substring(4)));
      } else if (trimmed.startsWith('#### ')) {
        blocks.add(MarkdownCustomBlock(type: MarkdownBlockType.heading4, text: trimmed.substring(5)));
      } else if (trimmed.startsWith('##### ')) {
        blocks.add(MarkdownCustomBlock(type: MarkdownBlockType.heading5, text: trimmed.substring(6)));
      } else if (trimmed.startsWith('###### ')) {
        blocks.add(MarkdownCustomBlock(type: MarkdownBlockType.heading6, text: trimmed.substring(7)));
      }
      // Checklists
      else if (trimmed.startsWith('- [ ]') || trimmed.startsWith('[ ]')) {
        final text = line.replaceFirst('- [ ]', '').replaceFirst('[ ]', '').trim();
        blocks.add(MarkdownCustomBlock(
          type: MarkdownBlockType.checklist,
          text: text,
          isChecked: false,
        ));
      } else if (trimmed.startsWith('- [x]') || trimmed.startsWith('[x]') || trimmed.startsWith('- [X]') || trimmed.startsWith('[X]')) {
        final text = line.replaceFirst('- [x]', '').replaceFirst('[x]', '').replaceFirst('- [X]', '').replaceFirst('[X]', '').trim();
        blocks.add(MarkdownCustomBlock(
          type: MarkdownBlockType.checklist,
          text: text,
          isChecked: true,
        ));
      }
      // Bullet lists
      else if (line.trimLeft().startsWith('- ') || line.trimLeft().startsWith('* ')) {
        final leadingSpaces = line.length - line.trimLeft().length;
        final text = line.trimLeft().substring(2);
        blocks.add(MarkdownCustomBlock(
          type: MarkdownBlockType.bullet,
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
        blocks.add(MarkdownCustomBlock(
          type: MarkdownBlockType.ordered,
          text: text,
          level: (leadingSpaces / 2).floor() + 1,
          altText: num,
        ));
      }
      // General paragraph
      else {
        if (trimmed.isEmpty) continue;
        blocks.add(MarkdownCustomBlock(type: MarkdownBlockType.paragraph, text: line));
      }
    }

    if (inBlockquote && currentBlockquoteLines.isNotEmpty) {
      blocks.add(MarkdownCustomBlock(
        type: MarkdownBlockType.blockquote,
        text: currentBlockquoteLines.join('\n'),
      ));
    }

    if (inTable && currentTableRows.isNotEmpty) {
      blocks.add(MarkdownCustomBlock(
        type: MarkdownBlockType.table,
        text: '',
        tableData: List.from(currentTableRows),
      ));
    }

    if (inCodeBlock && currentCodeBlockLines.isNotEmpty) {
      blocks.add(MarkdownCustomBlock(
        type: MarkdownBlockType.code,
        text: currentCodeBlockLines.join('\n'),
        altText: codeLanguage,
      ));
    }

    if (inMathBlock && currentMathBlockLines.isNotEmpty) {
      blocks.add(MarkdownCustomBlock(
        type: MarkdownBlockType.math,
        text: currentMathBlockLines.join('\n'),
      ));
    }

    return blocks;
  }

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
                  color: theme.colorScheme.primary.withOpacity(0.4),
                  width: 3.5,
                ),
              ),
              color: theme.colorScheme.surfaceVariant.withOpacity(0.1),
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
