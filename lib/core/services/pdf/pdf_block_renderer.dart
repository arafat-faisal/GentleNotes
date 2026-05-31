import 'package:flutter/foundation.dart' show debugPrint;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pdf_delta_parser.dart';
import 'pdf_document_builder.dart';
import 'text_pdf_renderer.dart';
import 'media_pdf_renderer.dart';

class PdfBlockRenderer {
  static pw.Widget renderBlock(
    PdfContentBlock block, {
    required pw.Font fontBold,
    required pw.Font fontSemiBold,
    required pw.Font fontRegular,
    required pw.Font fontMono,
    required pw.Font fontMonoBold,
    required Map<String, pw.ImageProvider> resolvedImages,
  }) {
    try {
      final isMedia = block.type == PdfBlockType.divider ||
          block.type == PdfBlockType.code ||
          block.type == PdfBlockType.table ||
          block.type == PdfBlockType.image;

      if (isMedia) {
        return MediaPdfRenderer.renderMediaBlock(
          block,
          fontBold: fontBold,
          fontSemiBold: fontSemiBold,
          fontRegular: fontRegular,
          fontMono: fontMono,
          fontMonoBold: fontMonoBold,
          resolvedImages: resolvedImages,
          parseInlineText: _parseInlineText,
        );
      } else {
        return TextPdfRenderer.renderTextBlock(
          block,
          fontBold: fontBold,
          fontSemiBold: fontSemiBold,
          fontRegular: fontRegular,
          fontMono: fontMono,
          parseInlineText: _parseInlineText,
        );
      }
    } catch (e, st) {
      debugPrint('PDF: Error rendering block of type ${block.type.name}: $e\n$st');
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Text(
          '[Error rendering block of type ${block.type.name}]',
          style: pw.TextStyle(color: PdfColors.red, fontStyle: pw.FontStyle.italic, fontSize: 9),
        ),
      );
    }
  }

  static pw.Widget _parseInlineText(
    String rawText, {
    required pw.Font fontRegular,
    required pw.Font fontMono,
    double fontSize = 10.5,
    PdfColor color = PdfDocumentColors.grey800,
    bool isItalic = false,
    bool strikethrough = false,
    pw.TextAlign? textAlign,
  }) {
    final text = PdfDeltaParser.cleanText(rawText);
    if (text.trim().isEmpty) {
      return pw.Text('');
    }

    pw.TextStyle base({
      pw.Font? font,
      bool bold = false,
      bool italic = false,
      PdfColor? clr,
      pw.TextDecoration? decoration,
    }) {
      return pw.TextStyle(
        font: font ?? fontRegular,
        fontWeight: bold ? pw.FontWeight.bold : null,
        fontStyle: (isItalic || italic) ? pw.FontStyle.italic : null,
        fontSize: fontSize,
        color: clr ?? color,
        decoration: decoration ?? (strikethrough ? pw.TextDecoration.lineThrough : null),
        lineSpacing: 2,
      );
    }

    final spans = _parseInlineSpans(
      text,
      baseStyle: base(),
      fontRegular: fontRegular,
      fontMono: fontMono,
      fontSize: fontSize,
    );

    return pw.RichText(
      textAlign: textAlign ?? pw.TextAlign.left,
      softWrap: true,
      text: pw.TextSpan(children: spans),
    );
  }

  static List<pw.InlineSpan> _parseInlineSpans(
    String text, {
    required pw.TextStyle baseStyle,
    required pw.Font fontRegular,
    required pw.Font fontMono,
    required double fontSize,
  }) {
    final spans = <pw.InlineSpan>[];
    final regex = RegExp(
      r'(\*\*\*.*?\*\*\*|\*\*.*?\*\*|_.*?_|\*.*?\*|~~.*?~~|`.*?`|<u>.*?</u>|<mark[^>]*>.*?</mark>|<span[^>]*>.*?</span>|\[.*?\]\(.*?\)|https?://\S+)',
      dotAll: false,
    );

    int lastIndex = 0;

    for (final m in regex.allMatches(text)) {
      if (m.start > lastIndex) {
        spans.add(pw.TextSpan(text: text.substring(lastIndex, m.start), style: baseStyle));
      }
      final tok = m.group(1)!;
      if (tok.startsWith('***') && tok.endsWith('***')) {
        spans.addAll(_parseInlineSpans(
          tok.substring(3, tok.length - 3),
          baseStyle: baseStyle.copyWith(fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic),
          fontRegular: fontRegular, fontMono: fontMono, fontSize: fontSize,
        ));
      } else if (tok.startsWith('**') && tok.endsWith('**')) {
        spans.addAll(_parseInlineSpans(
          tok.substring(2, tok.length - 2),
          baseStyle: baseStyle.copyWith(fontWeight: pw.FontWeight.bold),
          fontRegular: fontRegular, fontMono: fontMono, fontSize: fontSize,
        ));
      } else if ((tok.startsWith('*') && tok.endsWith('*')) ||
                 (tok.startsWith('_') && tok.endsWith('_'))) {
        spans.addAll(_parseInlineSpans(
          tok.substring(1, tok.length - 1),
          baseStyle: baseStyle.copyWith(fontStyle: pw.FontStyle.italic),
          fontRegular: fontRegular, fontMono: fontMono, fontSize: fontSize,
        ));
      } else if (tok.startsWith('~~') && tok.endsWith('~~')) {
        spans.addAll(_parseInlineSpans(
          tok.substring(2, tok.length - 2),
          baseStyle: baseStyle.copyWith(decoration: pw.TextDecoration.lineThrough),
          fontRegular: fontRegular, fontMono: fontMono, fontSize: fontSize,
        ));
      } else if (tok.startsWith('`') && tok.endsWith('`')) {
        spans.add(pw.TextSpan(
          text: tok.substring(1, tok.length - 1),
          style: pw.TextStyle(
            font: fontMono,
            fontSize: fontSize - 1,
            color: PdfDocumentColors.violet,
            background: const pw.BoxDecoration(color: PdfDocumentColors.violetLight),
          ),
        ));
      } else if (tok.startsWith('<u>') && tok.endsWith('</u>')) {
        spans.addAll(_parseInlineSpans(
          tok.substring(3, tok.length - 4),
          baseStyle: baseStyle.copyWith(decoration: pw.TextDecoration.underline),
          fontRegular: fontRegular, fontMono: fontMono, fontSize: fontSize,
        ));
      } else if (tok.startsWith('<mark')) {
        final innerMatch = RegExp(r'<mark[^>]*>(.*?)</mark>', dotAll: true).firstMatch(tok);
        final innerText = innerMatch?.group(1) ?? tok;
        spans.addAll(_parseInlineSpans(
          innerText,
          baseStyle: baseStyle,
          fontRegular: fontRegular, fontMono: fontMono, fontSize: fontSize,
        ));
      } else if (tok.startsWith('<span')) {
        final colorMatch = RegExp(r'color[:\s]*([#\w]+)').firstMatch(tok);
        final innerMatch = RegExp(r'<span[^>]*>(.*?)</span>', dotAll: true).firstMatch(tok);
        final innerText = innerMatch?.group(1) ?? tok;
        
        PdfColor textColor = baseStyle.color ?? PdfDocumentColors.grey800;
        if (colorMatch != null) {
          final hexStr = colorMatch.group(1)!.replaceAll('#', '');
          if (hexStr.length == 6) {
             final intColor = int.parse('FF$hexStr', radix: 16);
             textColor = PdfColor.fromInt(intColor);
          }
        }
        spans.addAll(_parseInlineSpans(
          innerText,
          baseStyle: baseStyle.copyWith(color: textColor),
          fontRegular: fontRegular, fontMono: fontMono, fontSize: fontSize,
        ));
      } else if (tok.startsWith('[') && tok.contains('](')) {
        final label = tok.substring(1, tok.indexOf(']'));
        spans.add(pw.TextSpan(
          text: label,
          style: baseStyle.copyWith(color: PdfDocumentColors.blue600, decoration: pw.TextDecoration.underline),
        ));
      } else {
        spans.add(pw.TextSpan(
          text: tok,
          style: baseStyle.copyWith(color: PdfDocumentColors.blue600, decoration: pw.TextDecoration.underline),
        ));
      }
      lastIndex = m.end;
    }

    if (lastIndex < text.length) {
      spans.add(pw.TextSpan(text: text.substring(lastIndex), style: baseStyle));
    }
    
    return spans;
  }
}
