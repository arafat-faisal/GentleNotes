import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pdf_delta_parser.dart';
import 'pdf_document_builder.dart';

class MediaPdfRenderer {
  static pw.Widget renderMediaBlock(
    PdfContentBlock block, {
    required pw.Font fontBold,
    required pw.Font fontSemiBold,
    required pw.Font fontRegular,
    required pw.Font fontMono,
    required pw.Font fontMonoBold,
    required Map<String, pw.ImageProvider> resolvedImages,
    required pw.Widget Function(
      String rawText, {
      required pw.Font fontRegular,
      required pw.Font fontMono,
      double fontSize,
      PdfColor color,
    }) parseInlineText,
  }) {
    switch (block.type) {
      case PdfBlockType.divider:
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 14),
          child: pw.Divider(thickness: 0.8, color: PdfDocumentColors.grey200),
        );

      case PdfBlockType.code:
        final lang = (block.altText ?? '').trim();
        final isMath = lang.toLowerCase() == 'math';
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 10),
          child: pw.Container(
            width: double.infinity,
            decoration: pw.BoxDecoration(
              color: isMath ? PdfDocumentColors.grey50 : PdfDocumentColors.codeBackground,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (lang.isNotEmpty)
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      color: isMath ? PdfDocumentColors.grey200 : PdfDocumentColors.codeBadgeBg,
                      borderRadius: const pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(8),
                        topRight: pw.Radius.circular(8),
                      ),
                    ),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 6, height: 6,
                          decoration: const pw.BoxDecoration(
                            color: PdfDocumentColors.violet,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.SizedBox(width: 6),
                        pw.Text(
                          isMath ? 'FORMULA' : lang.toUpperCase(),
                          style: pw.TextStyle(
                            font: fontMonoBold,
                            fontSize: 7.5,
                            color: isMath ? PdfDocumentColors.grey500 : PdfDocumentColors.violet,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(12),
                  child: isMath
                      ? pw.Center(
                          child: pw.Text(
                            block.text,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              font: fontRegular,
                              fontSize: 12,
                              fontStyle: pw.FontStyle.italic,
                              color: PdfDocumentColors.grey900,
                              lineSpacing: 4,
                            ),
                          ),
                        )
                      : pw.Text(
                          block.text,
                          style: pw.TextStyle(
                            font: fontMono,
                            fontSize: 8.5,
                            color: PdfDocumentColors.codeText,
                            lineSpacing: 3.5,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );

      case PdfBlockType.table:
        if (block.tableData == null || block.tableData!.isEmpty) {
          return pw.SizedBox(height: 0);
        }
        final headers = block.tableData!.first;
        final rows = block.tableData!.skip(1).toList();
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 10),
          child: pw.Table(
            border: pw.TableBorder.all(color: PdfDocumentColors.grey200, width: 0.5),
            columnWidths: {
              for (int i = 0; i < headers.length; i++)
                i: const pw.FlexColumnWidth(),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfDocumentColors.tableHeader),
                children: headers.map((cell) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: pw.Text(
                    cell,
                    style: pw.TextStyle(font: fontSemiBold, fontSize: 9, color: PdfDocumentColors.violet),
                  ),
                )).toList(),
              ),
              ...rows.asMap().entries.map((entry) {
                final isEven = entry.key.isEven;
                final rowCells = entry.value;
                final normalizedCells = List<String>.generate(headers.length, (i) {
                  if (i < rowCells.length) {
                    return rowCells[i];
                  }
                  return '';
                });
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : PdfDocumentColors.tableRowAlt),
                  children: normalizedCells.map((cell) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    child: parseInlineText(
                      cell,
                      fontRegular: fontRegular,
                      fontMono: fontMono,
                      fontSize: 8.5,
                      color: PdfDocumentColors.grey700,
                    ),
                  )).toList(),
                );
              }),
            ],
          ),
        );

      case PdfBlockType.image:
        final imageProvider = resolvedImages[block.text];
        if (imageProvider == null) {
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            child: pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: const pw.BoxDecoration(
                color: PdfDocumentColors.grey100,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(
                '[Image: ${block.altText ?? block.text}]',
                style: pw.TextStyle(font: fontMono, fontSize: 9, color: PdfDocumentColors.grey500),
              ),
            ),
          );
        }
        String altTextRaw = block.altText ?? '';
        String cleanAlt = altTextRaw;
        String size = 'medium';
        String align = 'center';
        if (altTextRaw.contains('|')) {
          final parts = altTextRaw.split('|');
          cleanAlt = parts[0].trim();
          for (var part in parts.skip(1)) {
            final t = part.trim();
            if (t.startsWith('size=')) size = t.substring(5);
            else if (t.startsWith('align=')) align = t.substring(6);
          }
        }
        final pw.Alignment alignment = align == 'left'
            ? pw.Alignment.centerLeft
            : align == 'right'
                ? pw.Alignment.centerRight
                : pw.Alignment.center;
        final isSticker = block.text.startsWith('sticker://');
        final double maxW = isSticker ? 100 : (size == 'small' ? 200 : size == 'large' ? 460 : 340);
        final double maxH = isSticker ? 100 : (size == 'small' ? 150 : size == 'large' ? 320 : 240);

        return pw.Align(
          alignment: alignment,
          child: pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 10),
            child: pw.Column(
              crossAxisAlignment: align == 'left'
                  ? pw.CrossAxisAlignment.start
                  : align == 'right'
                      ? pw.CrossAxisAlignment.end
                      : pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  constraints: pw.BoxConstraints(maxWidth: maxW, maxHeight: maxH),
                  child: pw.ClipRRect(
                    horizontalRadius: 6,
                    verticalRadius: 6,
                    child: pw.Image(imageProvider, fit: pw.BoxFit.contain),
                  ),
                ),
                if (cleanAlt.isNotEmpty && cleanAlt.toLowerCase() != 'image' && !cleanAlt.startsWith('sticker:')) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    cleanAlt,
                    style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfDocumentColors.grey500),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );

      default:
        return pw.SizedBox(height: 0);
    }
  }
}
