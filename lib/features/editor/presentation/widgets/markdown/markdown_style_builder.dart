import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../models/models.dart';
import 'markdown_link_handler.dart';
import '../../../../../../core/theme/font_helper.dart';

class MarkdownStyleBuilder {
  static String? _resolveFontFamily(String? fontFamily) {
    return FontHelper.resolveFontFamily(fontFamily);
  }

  static Widget renderInlineText(
    BuildContext context, 
    String text, 
    TextStyle? baseStyle, {
    String? fontFamily,
    TextAlign textAlign = TextAlign.start,
    List<AttachmentModel> attachments = const [],
  }) {
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
    final resolvedFamily = _resolveFontFamily(fontFamily);
    final TextStyle finalStyle = (baseStyle ?? const TextStyle()).copyWith(fontFamily: resolvedFamily);
    final spans = parseInlineSpans(context, processedText, finalStyle, fontFamily: resolvedFamily, attachments: attachments);
    return RichText(
      text: TextSpan(children: spans, style: finalStyle),
      textAlign: align,
      textWidthBasis: TextWidthBasis.parent,
    );
  }

  static List<InlineSpan> parseInlineSpans(
    BuildContext context, 
    String text, 
    TextStyle baseStyle, {
    String? fontFamily,
    List<AttachmentModel> attachments = const [],
  }) {
    final List<InlineSpan> spans = [];
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;
    
    final RegExp inlineRegex = RegExp(
      r'(<https?://[^>]+>'
      r'|\*\*\*.*?\*\*\*|\*\*.*?\*\*|\*.*?\*|~~.*?~~|`.*?`|<u>.*?</u>|<mark[^>]*>.*?</mark>|<span[^>]*>.*?</span>|\[.*?\]\(.*?\)|https?://[^\s<>]+|\$\$[^$]+\$\$'
      r'|\$[^$\n]+\$)',
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

      if (token.startsWith('<http') && token.endsWith('>')) {
        final url = token.substring(1, token.length - 1);
        spans.add(TextSpan(
          text: url,
          style: baseStyle.copyWith(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening Link: $url'),
                  backgroundColor: Colors.blue,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
        ));
      } else if (token.startsWith('http://') || token.startsWith('https://')) {
        spans.add(TextSpan(
          text: token,
          style: baseStyle.copyWith(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening Link: $token'),
                  backgroundColor: Colors.blue,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
        ));
      } else if (token.startsWith('***') && token.endsWith('***')) {
        spans.addAll(parseInlineSpans(
          context,
          token.substring(3, token.length - 3),
          baseStyle.copyWith(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
          fontFamily: fontFamily,
          attachments: attachments,
        ));
      } else if (token.startsWith('**') && token.endsWith('**')) {
        spans.addAll(parseInlineSpans(
          context,
          token.substring(2, token.length - 2),
          baseStyle.copyWith(fontWeight: FontWeight.bold),
          fontFamily: fontFamily,
          attachments: attachments,
        ));
      } else if (token.startsWith('*') && token.endsWith('*')) {
        spans.addAll(parseInlineSpans(
          context,
          token.substring(1, token.length - 1),
          baseStyle.copyWith(fontStyle: FontStyle.italic),
          fontFamily: fontFamily,
          attachments: attachments,
        ));
      } else if (token.startsWith('~~') && token.endsWith('~~')) {
        spans.addAll(parseInlineSpans(
          context,
          token.substring(2, token.length - 2),
          baseStyle.copyWith(decoration: TextDecoration.lineThrough),
          fontFamily: fontFamily,
          attachments: attachments,
        ));
      } else if (token.startsWith('`') && token.endsWith('`')) {
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: baseStyle.copyWith(
            fontFamily: 'Courier',
            fontSize: (baseStyle.fontSize ?? 14) - 1,
            backgroundColor: isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            color: isDarkTheme ? const Color(0xFFF472B6) : const Color(0xFFE11D48),
            fontWeight: baseStyle.fontWeight ?? FontWeight.w500,
          ),
        ));
      } else if (token.startsWith('<u>') && token.endsWith('</u>')) {
        spans.addAll(parseInlineSpans(
          context,
          token.substring(3, token.length - 4),
          baseStyle.copyWith(decoration: TextDecoration.underline),
          fontFamily: fontFamily,
          attachments: attachments,
        ));
      } else if (token.startsWith('\$\$') && token.endsWith('\$\$') && token.length > 4) {
        final formula = token.substring(2, token.length - 2);
        spans.add(TextSpan(
          text: formula,
          style: baseStyle.copyWith(
            fontFamily: 'Georgia',
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
            color: isDarkTheme ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
          ),
        ));
      } else if (token.startsWith('\$') && token.endsWith('\$') && token.length >= 2) {
        final formula = token.substring(1, token.length - 1);
        spans.add(TextSpan(
          text: formula,
          style: baseStyle.copyWith(
            fontFamily: 'Georgia',
            fontStyle: FontStyle.italic,
            color: isDarkTheme ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
          ),
        ));
      } else if (token.startsWith('<mark')) {
        final bgMatch = RegExp(r'background[:\s]*([#\w]+)').firstMatch(token);
        final innerMatch = RegExp(r'<mark[^>]*>(.*?)</mark>', dotAll: true).firstMatch(token);
        final innerText = innerMatch?.group(1) ?? token;
        Color bgColor = const Color(0xFFFFFF00);
        if (bgMatch != null) {
          bgColor = _parseCssColor(bgMatch.group(1)!, bgColor);
        }
        spans.addAll(parseInlineSpans(
          context, 
          innerText, 
          baseStyle.copyWith(backgroundColor: bgColor),
          fontFamily: fontFamily,
          attachments: attachments,
        ));
      } else if (token.startsWith('<span')) {
        final colorMatch = RegExp(r'color[:\s]*([#\w]+)').firstMatch(token);
        final fontMatch = RegExp(r'font-family[:\s]*([^;"]+)').firstMatch(token);
        final sizeMatch = RegExp(r'font-size[:\s]*([^;"]+)').firstMatch(token);
        final innerMatch = RegExp(r'<span[^>]*>(.*?)</span>', dotAll: true).firstMatch(token);
        final innerText = innerMatch?.group(1) ?? token;
        Color textColor = baseStyle.color ?? (isDarkTheme ? Colors.white : Colors.black);
        if (colorMatch != null) {
          textColor = _parseCssColor(colorMatch.group(1)!, textColor);
        }
        String? spanFontFamily = fontFamily;
        if (fontMatch != null) {
          spanFontFamily = fontMatch.group(1)!.trim();
        }
        double? spanFontSize = baseStyle.fontSize;
        if (sizeMatch != null) {
          final sizeStr = sizeMatch.group(1)!.trim().replaceAll('px', '');
          final d = double.tryParse(sizeStr);
          if (d != null) {
            spanFontSize = d;
          } else {
            if (sizeStr == 'small') spanFontSize = 12.0;
            else if (sizeStr == 'large') spanFontSize = 20.0;
            else if (sizeStr == 'huge') spanFontSize = 28.0;
          }
        }
        final resolvedFamily = _resolveFontFamily(spanFontFamily);
        final childStyle = baseStyle.copyWith(
          color: textColor,
          fontFamily: resolvedFamily,
          fontSize: spanFontSize,
        );
        spans.addAll(parseInlineSpans(
          context, 
          innerText, 
          childStyle,
          fontFamily: resolvedFamily,
          attachments: attachments,
        ));
      } else if (token.startsWith('[') && token.contains('](')) {
        final closingBrace = token.indexOf(']');
        final label = token.substring(1, closingBrace);
        final url = token.substring(closingBrace + 2, token.length - 1);
        spans.add(MarkdownLinkHandler.buildAudioOrLinkSpan(
          context: context,
          label: label,
          url: url,
          baseStyle: baseStyle,
          attachments: attachments,
        ));
      } else {
        spans.add(TextSpan(
          text: token,
          style: baseStyle,
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

  static Color _parseCssColor(String colorStr, Color defaultColor) {
    try {
      final clean = colorStr.trim().toLowerCase();
      if (clean.startsWith('#')) {
        final hex = clean.replaceAll('#', '');
        if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 3) {
          final r = hex[0];
          final g = hex[1];
          final b = hex[2];
          return Color(int.parse('FF$r$r$g$g$b$b', radix: 16));
        } else if (hex.length == 8) {
          return Color(int.parse(hex, radix: 16));
        }
      }
      
      const colorMap = {
        'red': Colors.red,
        'blue': Colors.blue,
        'green': Colors.green,
        'yellow': Colors.yellow,
        'orange': Colors.orange,
        'purple': Colors.purple,
        'pink': Colors.pink,
        'teal': Colors.teal,
        'grey': Colors.grey,
        'gray': Colors.grey,
        'black': Colors.black,
        'white': Colors.white,
        'indigo': Colors.indigo,
        'cyan': Colors.cyan,
        'brown': Colors.brown,
        'amber': Colors.amber,
      };
      
      return colorMap[clean] ?? defaultColor;
    } catch (_) {
      return defaultColor;
    }
  }
}
