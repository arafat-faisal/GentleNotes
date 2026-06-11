import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'pdf_delta_parser.dart';
import 'pdf_document_builder.dart';

class TextPdfRenderer {
  static pw.Widget renderTextBlock(
    PdfContentBlock block, {
    required pw.Font fontBold,
    required pw.Font fontSemiBold,
    required pw.Font fontRegular,
    required pw.Font fontMono,
    required pw.Widget Function(
      String rawText, {
      required pw.Font fontRegular,
      required pw.Font fontMono,
      double fontSize,
      PdfColor color,
      bool isItalic,
      bool strikethrough,
      pw.TextAlign? textAlign,
    }) parseInlineText,
  }) {
    switch (block.type) {
      case PdfBlockType.header1:
        return pw.Padding(
          padding: const pw.EdgeInsets.only(top: 20, bottom: 6),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                block.text,
                style: pw.TextStyle(font: fontBold, fontSize: 20, color: PdfDocumentColors.grey900, letterSpacing: -0.3),
              ),
              pw.SizedBox(height: 4),
              pw.Container(height: 2, color: PdfDocumentColors.violet, width: 40),
            ],
          ),
        );

      case PdfBlockType.header2:
        return pw.Padding(
          padding: const pw.EdgeInsets.only(top: 14, bottom: 4),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                block.text,
                style: pw.TextStyle(font: fontBold, fontSize: 15, color: PdfDocumentColors.grey800),
              ),
              pw.SizedBox(height: 3),
              pw.Divider(thickness: 0.5, color: PdfDocumentColors.grey200),
            ],
          ),
        );

      case PdfBlockType.header3:
        return pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10, bottom: 3),
          child: pw.Text(
            block.text,
            style: pw.TextStyle(font: fontSemiBold, fontSize: 13, color: PdfDocumentColors.grey800),
          ),
        );

      case PdfBlockType.header4:
        return pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8, bottom: 2),
          child: pw.Text(
            block.text,
            style: pw.TextStyle(font: fontSemiBold, fontSize: 11.5, color: PdfDocumentColors.grey700),
          ),
        );

      case PdfBlockType.header5:
      case PdfBlockType.header6:
        return pw.Padding(
          padding: const pw.EdgeInsets.only(top: 6, bottom: 2),
          child: pw.Text(
            block.text,
            style: pw.TextStyle(font: fontSemiBold, fontSize: 10.5, color: PdfDocumentColors.grey500),
          ),
        );

      case PdfBlockType.blockquote:
        final level = int.tryParse(block.altText ?? '1') ?? 1;
        return pw.Padding(
          padding: pw.EdgeInsets.only(left: 12.0 * (level - 1), top: 4, bottom: 4),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Container(
                width: 3,
                color: PdfDocumentColors.violet,
              ),
              pw.Expanded(
                child: pw.Container(
                  color: PdfDocumentColors.blockquoteBg,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: parseInlineText(
                    block.text,
                    fontRegular: fontRegular,
                    fontMono: fontMono,
                    fontSize: 10.5,
                    color: PdfDocumentColors.grey700,
                    isItalic: true,
                  ),
                ),
              ),
            ],
          ),
        );

      case PdfBlockType.bullet:
        final indent = (block.indentLevel ?? 0) * 12.0;
        final bullets = ['•', '◦', '▪'];
        final bulletChar = bullets[(block.indentLevel ?? 0).clamp(0, 2)];
        return pw.Padding(
          padding: pw.EdgeInsets.only(left: 8 + indent, bottom: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '$bulletChar  ',
                style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfDocumentColors.violet),
              ),
              pw.Expanded(
                child: parseInlineText(
                  block.text,
                  fontRegular: fontRegular,
                  fontMono: fontMono,
                  fontSize: 10.5,
                  color: PdfDocumentColors.grey800,
                ),
              ),
            ],
          ),
        );

      case PdfBlockType.ordered:
        final indent = (block.indentLevel ?? 0) * 12.0;
        return pw.Padding(
          padding: pw.EdgeInsets.only(left: 8 + indent, bottom: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${block.orderedIndex ?? 1}.  ',
                style: pw.TextStyle(font: fontSemiBold, fontSize: 10, color: PdfDocumentColors.violet),
              ),
              pw.Expanded(
                child: parseInlineText(
                  block.text,
                  fontRegular: fontRegular,
                  fontMono: fontMono,
                  fontSize: 10.5,
                  color: PdfDocumentColors.grey800,
                ),
              ),
            ],
          ),
        );

      case PdfBlockType.checklist:
        final checked = block.isChecked ?? false;
        return pw.Padding(
          padding: const pw.EdgeInsets.only(left: 8, bottom: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 10,
                height: 10,
                margin: const pw.EdgeInsets.only(top: 1.5, right: 8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: checked ? PdfDocumentColors.violet : PdfDocumentColors.grey400,
                    width: 1.2,
                  ),
                  color: checked ? PdfDocumentColors.violetLight : PdfColors.white,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                ),
                alignment: pw.Alignment.center,
                child: checked
                    ? pw.Text('✓', style: pw.TextStyle(font: fontBold, fontSize: 6.5, color: PdfDocumentColors.violet))
                    : null,
              ),
              pw.Expanded(
                child: parseInlineText(
                  block.text,
                  fontRegular: fontRegular,
                  fontMono: fontMono,
                  fontSize: 10.5,
                  color: checked ? PdfDocumentColors.grey400 : PdfDocumentColors.grey800,
                  strikethrough: checked,
                ),
              ),
            ],
          ),
        );

      default:
        if (block.text.trim().isEmpty) return pw.SizedBox(height: 6);
        pw.TextAlign tAlign = pw.TextAlign.left;
        if (block.altText == 'center') {
          tAlign = pw.TextAlign.center;
        } else if (block.altText == 'right') tAlign = pw.TextAlign.right;
        else if (block.altText == 'justify') tAlign = pw.TextAlign.justify;

        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 7),
          child: parseInlineText(
            block.text,
            fontRegular: fontRegular,
            fontMono: fontMono,
            fontSize: 10.5,
            color: PdfDocumentColors.grey800,
            textAlign: tAlign,
          ),
        );
    }
  }
}
