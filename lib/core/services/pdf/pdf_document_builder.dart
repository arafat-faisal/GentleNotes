import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfDocumentColors {
  static const violet = PdfColor.fromInt(0xFF7C3AED);
  static const violetLight = PdfColor.fromInt(0xFFEDE9FE);
  static const codeBackground = PdfColor.fromInt(0xFF1E1B2E);
  static const codeText = PdfColor.fromInt(0xFFCDD6F4);
  static const codeBadgeBg = PdfColor.fromInt(0xFF312E54);
  static const tableHeader = PdfColor.fromInt(0xFFEDE9FE);
  static const tableRowAlt = PdfColor.fromInt(0xFFF8F7FF);
  static const blockquoteBg = PdfColor.fromInt(0xFFF5F3FF);
  static const grey50 = PdfColor.fromInt(0xFFF9FAFB);
  static const grey100 = PdfColor.fromInt(0xFFF3F4F6);
  static const grey200 = PdfColor.fromInt(0xFFE5E7EB);
  static const grey400 = PdfColor.fromInt(0xFF9CA3AF);
  static const grey500 = PdfColor.fromInt(0xFF6B7280);
  static const grey700 = PdfColor.fromInt(0xFF374151);
  static const grey800 = PdfColor.fromInt(0xFF1F2937);
  static const grey900 = PdfColor.fromInt(0xFF111827);
  static const blue600 = PdfColor.fromInt(0xFF2563EB);
}

class PdfDocumentBuilder {
  static pw.Widget buildHeader(pw.Font fontSemiBold, pw.Font fontRegular, String cleanTitle) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Gentle Notes',
            style: pw.TextStyle(
              font: fontSemiBold,
              fontSize: 8,
              color: PdfDocumentColors.violet,
              letterSpacing: 0.5,
            ),
          ),
          pw.Text(
            cleanTitle,
            style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfDocumentColors.grey400),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildFooter(pw.Context ctx, pw.Font fontSemiBold, pw.Font fontRegular) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated ${formatDate(DateTime.now())}',
            style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfDocumentColors.grey400),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: pw.TextStyle(font: fontSemiBold, fontSize: 7.5, color: PdfDocumentColors.grey500),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildPill(String text, pw.Font font, PdfColor textClr, PdfColor bgClr) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(
        color: bgClr,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 8, color: textClr),
      ),
    );
  }

  static String formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
