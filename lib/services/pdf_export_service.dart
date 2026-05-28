import 'dart:convert';
import 'dart:io' as io;
import '../core/utils/quill_markdown_converter.dart';

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';

// ── Colour palette used throughout the PDF ────────────────────────────────────
const _violet = PdfColor.fromInt(0xFF7C3AED);
const _violetLight = PdfColor.fromInt(0xFFEDE9FE);
const _codeBackground = PdfColor.fromInt(0xFF1E1B2E);
const _codeText = PdfColor.fromInt(0xFFCDD6F4);
const _codeBadgeBg = PdfColor.fromInt(0xFF312E54);
const _tableHeader = PdfColor.fromInt(0xFFEDE9FE);
const _tableRowAlt = PdfColor.fromInt(0xFFF8F7FF);
const _blockquoteBg = PdfColor.fromInt(0xFFF5F3FF);
const _grey50 = PdfColor.fromInt(0xFFF9FAFB);
const _grey100 = PdfColor.fromInt(0xFFF3F4F6);
const _grey200 = PdfColor.fromInt(0xFFE5E7EB);
const _grey400 = PdfColor.fromInt(0xFF9CA3AF);
const _grey500 = PdfColor.fromInt(0xFF6B7280);
const _grey700 = PdfColor.fromInt(0xFF374151);
const _grey800 = PdfColor.fromInt(0xFF1F2937);
const _grey900 = PdfColor.fromInt(0xFF111827);
const _blue600 = PdfColor.fromInt(0xFF2563EB);

class PdfExportService {
  static final PdfExportService _instance = PdfExportService._internal();
  factory PdfExportService() => _instance;
  PdfExportService._internal();

  /// Opens paper-size selection then generates + shows the PDF.
  Future<void> printOrExportNote(
    NoteModel note, {
    String? folderName,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    bool includeMetadata = true,
    bool includeTags = true,
  }) async {
    final doc = pw.Document();

    // ── Fonts (use roboto which is bundled with the printing package) ─────────
    pw.Font fontBold;
    pw.Font fontSemiBold;
    pw.Font fontRegular;
    pw.Font fontMono;
    pw.Font fontMonoBold;

    try {
      fontBold     = await PdfGoogleFonts.robotoBold();
      fontSemiBold = await PdfGoogleFonts.robotoMedium();
      fontRegular  = await PdfGoogleFonts.robotoRegular();
      fontMono     = await PdfGoogleFonts.robotoMonoRegular();
      fontMonoBold = await PdfGoogleFonts.robotoMonoMedium();
    } catch (e) {
      debugPrint('PDF: Google Font fetch failed, using default: $e');
      fontBold     = pw.Font.helveticaBold();
      fontSemiBold = pw.Font.helveticaBold();
      fontRegular  = pw.Font.helvetica();
      fontMono     = pw.Font.courier();
      fontMonoBold = pw.Font.courierBold();
    }

    final fallbacks = <pw.Font>[];
    try {
      // Load fallback fonts for foreign languages and symbols
      fallbacks.add(await PdfGoogleFonts.notoSansSCRegular());
      fallbacks.add(await PdfGoogleFonts.notoSansJPRegular());
      fallbacks.add(await PdfGoogleFonts.notoSansKRRegular());
      fallbacks.add(await PdfGoogleFonts.notoSansArabicRegular());
      fallbacks.add(await PdfGoogleFonts.notoSansDevanagariRegular());
      fallbacks.add(await PdfGoogleFonts.notoSansHebrewRegular());
      fallbacks.add(await PdfGoogleFonts.notoSansThaiRegular());
      fallbacks.add(await PdfGoogleFonts.notoColorEmoji());
    } catch (e) {
      debugPrint('PDF: Fallback Google Fonts fetch failed: $e');
    }

    // ── Pre-resolve images ────────────────────────────────────────────────────
    final resolvedImages = <String, pw.ImageProvider>{};
    final cleanTitle = _cleanText(note.title.isEmpty ? 'Untitled Note' : note.title);
    final cleanFolder = folderName != null ? _cleanText(folderName) : null;
    final cleanTags = note.tags.map((t) => _cleanText(t)).toList();

    final markdown = QuillMarkdownConverter.deltaToMarkdown(note.content);
    final rawBlocks = _parseNoteContent(markdown);
    final contentBlocks = rawBlocks.map((b) {
      if (b.type == PdfBlockType.image) return b;
      if (b.type == PdfBlockType.table) {
        final cleanedTable = b.tableData?.map((row) {
          return row.map((cell) => _cleanText(cell)).toList();
        }).toList();
        return PdfContentBlock(
          type: b.type,
          text: b.text,
          altText: b.altText,
          tableData: cleanedTable,
          isChecked: b.isChecked,
          indentLevel: b.indentLevel,
          orderedIndex: b.orderedIndex,
        );
      }
      return PdfContentBlock(
        type: b.type,
        text: _cleanText(b.text),
        altText: b.altText,
        tableData: b.tableData,
        isChecked: b.isChecked,
        indentLevel: b.indentLevel,
        orderedIndex: b.orderedIndex,
      );
    }).toList();

    for (var block in contentBlocks) {
      if (block.type == PdfBlockType.image) {
        var path = block.text;
        if (path.startsWith('attachment://')) {
          final id = path.replaceFirst('attachment://', '');
          final att = note.attachments.cast<AttachmentModel?>()
              .firstWhere((a) => a?.id == id, orElse: () => null);
          if (att != null) path = att.pathOrUrl;
        }
        if (resolvedImages.containsKey(block.text)) continue;
        try {
          if (path.startsWith('data:image')) {
            final bytes = base64Decode(path.split(',').last);
            resolvedImages[block.text] = pw.MemoryImage(bytes);
          } else if (path.startsWith('http')) {
            resolvedImages[block.text] = await networkImage(path);
          } else if (!kIsWeb) {
            final cleanPath = path.startsWith('file://') ? path.replaceFirst('file://', '') : path;
            final file = io.File(cleanPath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              resolvedImages[block.text] = pw.MemoryImage(bytes);
            }
          }
        } catch (e) {
          debugPrint('PDF: image load failed: $e');
        }
      }
    }

    // ── Page ──────────────────────────────────────────────────────────────────
    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          italic: fontRegular,
          boldItalic: fontBold,
          fontFallback: fallbacks,
        ),
        margin: pw.EdgeInsets.fromLTRB(
          pageFormat == PdfPageFormat.a4 ? 56 : 60,
          48,
          pageFormat == PdfPageFormat.a4 ? 56 : 60,
          48,
        ),
        // ── Header ─────────────────────────────────────────────────────────
        header: (ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Gentle Notes',
                style: pw.TextStyle(
                  font: fontSemiBold,
                  fontSize: 8,
                  color: _violet,
                  letterSpacing: 0.5,
                ),
              ),
              pw.Text(
                cleanTitle,
                style: pw.TextStyle(font: fontRegular, fontSize: 8, color: _grey400),
              ),
            ],
          ),
        ),
        // ── Footer ─────────────────────────────────────────────────────────
        footer: (ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated ${_formatDate(DateTime.now())}',
                style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: _grey400),
              ),
              pw.Text(
                'Page ${ctx.pageNumber} / ${ctx.pagesCount}',
                style: pw.TextStyle(font: fontSemiBold, fontSize: 7.5, color: _grey500),
              ),
            ],
          ),
        ),
        build: (ctx) {
          return [
            // ── Cover / Title Block ─────────────────────────────────────────
            pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(color: _violet, width: 4)),
              ),
              padding: const pw.EdgeInsets.only(left: 14, top: 4, bottom: 4),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    cleanTitle,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 26,
                      color: _grey900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // ── Metadata ────────────────────────────────────────────────────
            if (includeMetadata) ...[
              pw.Row(
                children: [
                  if (cleanFolder != null) ...[
                    _pill(cleanFolder, fontSemiBold, _violet, _violetLight),
                    pw.SizedBox(width: 8),
                  ],
                  _pill(
                    _formatDate(note.createdAt),
                    fontRegular, _grey700, _grey100,
                  ),
                  if (note.updatedAt != note.createdAt) ...[
                    pw.SizedBox(width: 8),
                    _pill(
                      'Updated ${_formatDate(note.updatedAt)}',
                      fontRegular, _grey700, _grey100,
                    ),
                  ],
                ],
              ),
              pw.SizedBox(height: 8),
            ],

            // ── Tags ────────────────────────────────────────────────────────
            if (includeTags && cleanTags.isNotEmpty) ...[
              pw.Wrap(
                spacing: 6,
                runSpacing: 4,
                children: cleanTags
                    .map((t) => _pill('#$t', fontSemiBold, _violet, _violetLight))
                    .toList(),
              ),
              pw.SizedBox(height: 10),
            ],

            // ── Divider ─────────────────────────────────────────────────────
            pw.Divider(thickness: 1, color: _violet),
            pw.SizedBox(height: 16),

            // ── Content blocks ──────────────────────────────────────────────
            ...contentBlocks.map((block) => _renderBlock(
              block,
              fontBold: fontBold,
              fontSemiBold: fontSemiBold,
              fontRegular: fontRegular,
              fontMono: fontMono,
              fontMonoBold: fontMonoBold,
              resolvedImages: resolvedImages,
            )),
          ];
        },
      ),
    );

    final Uint8List pdfBytes;
    try {
      pdfBytes = await doc.save();
    } catch (e, st) {
      debugPrint('PDF layout generation failed: $e\n$st');
      rethrow;
    }

    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat fmt) async => pdfBytes,
        name: '${note.title.isEmpty ? "Note" : note.title}.pdf',
      );
    } catch (e, st) {
      debugPrint('Printing layout failed: $e\n$st');
      rethrow;
    }
  }

  // ── Block renderer ──────────────────────────────────────────────────────────
  pw.Widget _renderBlock(
    PdfContentBlock block, {
    required pw.Font fontBold,
    required pw.Font fontSemiBold,
    required pw.Font fontRegular,
    required pw.Font fontMono,
    required pw.Font fontMonoBold,
    required Map<String, pw.ImageProvider> resolvedImages,
  }) {
    try {
      switch (block.type) {
      // ── Headings ────────────────────────────────────────────────────────────
      case PdfBlockType.header1:
        return pw.Padding(
          padding: const pw.EdgeInsets.only(top: 20, bottom: 6),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                block.text,
                style: pw.TextStyle(font: fontBold, fontSize: 20, color: _grey900, letterSpacing: -0.3),
              ),
              pw.SizedBox(height: 4),
              pw.Container(height: 2, color: _violet, width: 40),
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
                style: pw.TextStyle(font: fontBold, fontSize: 15, color: _grey800),
              ),
              pw.SizedBox(height: 3),
              pw.Divider(thickness: 0.5, color: _grey200),
            ],
          ),
        );

      case PdfBlockType.header3:
        return pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10, bottom: 3),
          child: pw.Text(
            block.text,
            style: pw.TextStyle(font: fontSemiBold, fontSize: 13, color: _grey800),
          ),
        );

      case PdfBlockType.header4:
        return pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8, bottom: 2),
          child: pw.Text(
            block.text,
            style: pw.TextStyle(font: fontSemiBold, fontSize: 11.5, color: _grey700),
          ),
        );

      case PdfBlockType.header5:
      case PdfBlockType.header6:
        return pw.Padding(
          padding: const pw.EdgeInsets.only(top: 6, bottom: 2),
          child: pw.Text(
            block.text,
            style: pw.TextStyle(font: fontSemiBold, fontSize: 10.5, color: _grey500),
          ),
        );

      // ── Divider ─────────────────────────────────────────────────────────────
      case PdfBlockType.divider:
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 14),
          child: pw.Divider(thickness: 0.8, color: _grey200),
        );

      // ── Blockquote ──────────────────────────────────────────────────────────
      case PdfBlockType.blockquote:
        final level = int.tryParse(block.altText ?? '1') ?? 1;
        return pw.Padding(
          padding: pw.EdgeInsets.only(left: 12.0 * (level - 1), top: 4, bottom: 4),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Left accent bar (separate container, no borderRadius, uniform border not needed)
              pw.Container(
                width: 3,
                color: _violet,
              ),
              pw.Expanded(
                child: pw.Container(
                  color: _blockquoteBg,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: _parseInlineText(
                    block.text,
                    fontRegular: fontRegular,
                    fontMono: fontMono,
                    fontSize: 10.5,
                    color: _grey700,
                    isItalic: true,
                  ),
                ),
              ),
            ],
          ),
        );

      // ── Code Block ──────────────────────────────────────────────────────────
      case PdfBlockType.code:
        final lang = (block.altText ?? '').trim();
        final isMath = lang.toLowerCase() == 'math';
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 10),
          child: pw.Container(
            width: double.infinity,
            decoration: pw.BoxDecoration(
              color: isMath ? _grey50 : _codeBackground,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Language badge bar
                if (lang.isNotEmpty)
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      color: isMath ? _grey200 : _codeBadgeBg,
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
                            color: _violet,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.SizedBox(width: 6),
                        pw.Text(
                          isMath ? 'FORMULA' : lang.toUpperCase(),
                          style: pw.TextStyle(
                            font: fontMonoBold,
                            fontSize: 7.5,
                            color: isMath ? _grey500 : _violet,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Code content
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
                              color: _grey900,
                              lineSpacing: 4,
                            ),
                          ),
                        )
                      : pw.Text(
                          block.text,
                          style: pw.TextStyle(
                            font: fontMono,
                            fontSize: 8.5,
                            color: _codeText,
                            lineSpacing: 3.5,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );

      // ── Table ────────────────────────────────────────────────────────────────
      case PdfBlockType.table:
        if (block.tableData == null || block.tableData!.isEmpty) {
          return pw.SizedBox(height: 0);
        }
        final headers = block.tableData!.first;
        final rows = block.tableData!.skip(1).toList();
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 10),
          child: pw.Table(
            border: pw.TableBorder.all(color: _grey200, width: 0.5),
            columnWidths: {
              for (int i = 0; i < headers.length; i++)
                i: const pw.FlexColumnWidth(),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _tableHeader),
                children: headers.map((cell) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: pw.Text(
                    cell,
                    style: pw.TextStyle(font: fontSemiBold, fontSize: 9, color: _violet),
                  ),
                )).toList(),
              ),
              // Data rows
              ...rows.asMap().entries.map((entry) {
                final isEven = entry.key.isEven;
                final rowCells = entry.value;
                // Normalize cell count to match headers length
                final normalizedCells = List<String>.generate(headers.length, (i) {
                  if (i < rowCells.length) {
                    return rowCells[i];
                  }
                  return '';
                });
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : _tableRowAlt),
                  children: normalizedCells.map((cell) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    child: _parseInlineText(
                      cell,
                      fontRegular: fontRegular,
                      fontMono: fontMono,
                      fontSize: 8.5,
                      color: _grey700,
                    ),
                  )).toList(),
                );
              }),
            ],
          ),
        );

      // ── Bullet list ──────────────────────────────────────────────────────────
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
                style: pw.TextStyle(font: fontBold, fontSize: 10, color: _violet),
              ),
              pw.Expanded(
                child: _parseInlineText(
                  block.text,
                  fontRegular: fontRegular,
                  fontMono: fontMono,
                  fontSize: 10.5,
                  color: _grey800,
                ),
              ),
            ],
          ),
        );

      // ── Ordered list ─────────────────────────────────────────────────────────
      case PdfBlockType.ordered:
        final indent = (block.indentLevel ?? 0) * 12.0;
        return pw.Padding(
          padding: pw.EdgeInsets.only(left: 8 + indent, bottom: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${block.orderedIndex ?? 1}.  ',
                style: pw.TextStyle(font: fontSemiBold, fontSize: 10, color: _violet),
              ),
              pw.Expanded(
                child: _parseInlineText(
                  block.text,
                  fontRegular: fontRegular,
                  fontMono: fontMono,
                  fontSize: 10.5,
                  color: _grey800,
                ),
              ),
            ],
          ),
        );

      // ── Checklist ────────────────────────────────────────────────────────────
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
                    color: checked ? _violet : _grey400,
                    width: 1.2,
                  ),
                  color: checked ? _violetLight : PdfColors.white,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                ),
                alignment: pw.Alignment.center,
                child: checked
                    ? pw.Text('✓', style: pw.TextStyle(font: fontBold, fontSize: 6.5, color: _violet))
                    : null,
              ),
              pw.Expanded(
                child: _parseInlineText(
                  block.text,
                  fontRegular: fontRegular,
                  fontMono: fontMono,
                  fontSize: 10.5,
                  color: checked ? _grey400 : _grey800,
                  strikethrough: checked,
                ),
              ),
            ],
          ),
        );

      // ── Image ────────────────────────────────────────────────────────────────
      case PdfBlockType.image:
        final imageProvider = resolvedImages[block.text];
        if (imageProvider == null) {
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            child: pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: const pw.BoxDecoration(
                color: _grey100,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(
                '[Image: ${block.altText ?? block.text}]',
                style: pw.TextStyle(font: fontMono, fontSize: 9, color: _grey500),
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
        final double maxW = size == 'small' ? 200 : size == 'large' ? 460 : 340;
        final double maxH = size == 'small' ? 150 : size == 'large' ? 320 : 240;

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
                if (cleanAlt.isNotEmpty && cleanAlt.toLowerCase() != 'image') ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    cleanAlt,
                    style: pw.TextStyle(font: fontRegular, fontSize: 8, color: _grey500),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );

      // ── Paragraph ────────────────────────────────────────────────────────────
      default:
        if (block.text.trim().isEmpty) return pw.SizedBox(height: 6);
        pw.TextAlign tAlign = pw.TextAlign.left;
        if (block.altText == 'center') tAlign = pw.TextAlign.center;
        else if (block.altText == 'right') tAlign = pw.TextAlign.right;
        else if (block.altText == 'justify') tAlign = pw.TextAlign.justify;
        
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 7),
          child: _parseInlineText(
            block.text,
            fontRegular: fontRegular,
            fontMono: fontMono,
            fontSize: 10.5,
            color: _grey800,
            textAlign: tAlign,
          ),
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

  // ── Inline text parser ───────────────────────────────────────────────────────
  pw.Widget _parseInlineText(
    String rawText, {
    required pw.Font fontRegular,
    required pw.Font fontMono,
    double fontSize = 10.5,
    PdfColor color = _grey800,
    bool isItalic = false,
    bool strikethrough = false,
    pw.TextAlign? textAlign,
  }) {
    final text = _cleanText(rawText);
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
      text: pw.TextSpan(children: spans),
      softWrap: true,
    );
  }

  List<pw.InlineSpan> _parseInlineSpans(
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
            color: _violet,
            background: const pw.BoxDecoration(color: _violetLight),
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
        // The user explicitly requested to skip background color for PDF, so we do not style the background.
        spans.addAll(_parseInlineSpans(
          innerText,
          baseStyle: baseStyle,
          fontRegular: fontRegular, fontMono: fontMono, fontSize: fontSize,
        ));
      } else if (tok.startsWith('<span')) {
        final colorMatch = RegExp(r'color[:\s]*([#\w]+)').firstMatch(tok);
        final innerMatch = RegExp(r'<span[^>]*>(.*?)</span>', dotAll: true).firstMatch(tok);
        final innerText = innerMatch?.group(1) ?? tok;
        
        PdfColor textColor = baseStyle.color ?? _grey800;
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
          style: baseStyle.copyWith(color: _blue600, decoration: pw.TextDecoration.underline),
        ));
      } else {
        // Raw URL
        spans.add(pw.TextSpan(
          text: tok,
          style: baseStyle.copyWith(color: _blue600, decoration: pw.TextDecoration.underline),
        ));
      }
      lastIndex = m.end;
    }

    if (lastIndex < text.length) {
      spans.add(pw.TextSpan(text: text.substring(lastIndex), style: baseStyle));
    }
    
    return spans;
  }

  // ── Pill widget ──────────────────────────────────────────────────────────────
  pw.Widget _pill(String text, pw.Font font, PdfColor textClr, PdfColor bgClr) {
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

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  // ── Markdown → PdfContentBlock parser ───────────────────────────────────────
  List<PdfContentBlock> _parseNoteContent(String rawContent) {
    final processed = _preprocessMarkdown(rawContent);
    final blocks = <PdfContentBlock>[];
    final lines = processed.split('\n');

    bool inCodeBlock = false;
    String codeLanguage = '';
    final codeLines = <String>[];
    List<List<String>> tableRows = [];
    bool inTable = false;
    int orderedCounter = 0;

    final imageRe = RegExp(r'!\[(.*?)\]\((.*?)\)');
    final hrRe = RegExp(r'^\s*(\*|-|_)\s*\1\s*\1\s*(\1|\s)*$');
    final orderedRe = RegExp(r'^\s*(\d+)\.\s+(.+)');

    for (final rawLine in lines) {
      final line = rawLine;
      // ── Code block toggle ────────────────────────────────────────────────
      if (line.trim().startsWith('```')) {
        if (inCodeBlock) {
          blocks.add(PdfContentBlock(type: PdfBlockType.code, text: codeLines.join('\n'), altText: codeLanguage));
          codeLines.clear();
          inCodeBlock = false;
        } else {
          inCodeBlock = true;
          codeLanguage = line.trim().substring(3).trim();
          if (codeLanguage.isEmpty) codeLanguage = 'code';
        }
        continue;
      }
      if (inCodeBlock) { codeLines.add(line); continue; }

      // ── Table ─────────────────────────────────────────────────────────────
      final isTableRow = line.trim().startsWith('|') && line.trim().endsWith('|');
      if (isTableRow) {
        if (!inTable) { inTable = true; tableRows = []; }
        if (!RegExp(r'^\s*\|(?:\s*:?-+:?\s*\|)+\s*$').hasMatch(line)) {
          final cells = line.split('|').skip(1).toList();
          if (cells.length > 1) {
            cells.removeLast(); // remove trailing empty
            tableRows.add(cells.map((c) => c.trim()).toList());
          }
        }
        continue;
      } else if (inTable) {
        if (tableRows.isNotEmpty) {
          blocks.add(PdfContentBlock(type: PdfBlockType.table, text: '', tableData: List.from(tableRows)));
        }
        tableRows.clear();
        inTable = false;
      }

      // ── Horizontal rule ──────────────────────────────────────────────────
      if (hrRe.hasMatch(line)) { blocks.add(PdfContentBlock(type: PdfBlockType.divider, text: '')); continue; }

      // ── Image ─────────────────────────────────────────────────────────────
      final imgM = imageRe.firstMatch(line);
      if (imgM != null) {
        blocks.add(PdfContentBlock(type: PdfBlockType.image, text: imgM.group(2) ?? '', altText: imgM.group(1)));
        continue;
      }

      // ── Headings ──────────────────────────────────────────────────────────
      if (line.startsWith('# '))       { blocks.add(PdfContentBlock(type: PdfBlockType.header1, text: line.substring(2))); orderedCounter = 0; continue; }
      if (line.startsWith('## '))      { blocks.add(PdfContentBlock(type: PdfBlockType.header2, text: line.substring(3))); orderedCounter = 0; continue; }
      if (line.startsWith('### '))     { blocks.add(PdfContentBlock(type: PdfBlockType.header3, text: line.substring(4))); orderedCounter = 0; continue; }
      if (line.startsWith('#### '))    { blocks.add(PdfContentBlock(type: PdfBlockType.header4, text: line.substring(5))); orderedCounter = 0; continue; }
      if (line.startsWith('##### '))   { blocks.add(PdfContentBlock(type: PdfBlockType.header5, text: line.substring(6))); orderedCounter = 0; continue; }
      if (line.startsWith('###### '))  { blocks.add(PdfContentBlock(type: PdfBlockType.header6, text: line.substring(7))); orderedCounter = 0; continue; }

      // ── Blockquote ────────────────────────────────────────────────────────
      if (line.trim().startsWith('>')) {
        var content = line.trim();
        int level = 0;
        while (content.startsWith('>')) { level++; content = content.substring(1).trim(); }
        blocks.add(PdfContentBlock(type: PdfBlockType.blockquote, text: content, altText: level.toString()));
        continue;
      }

      // ── Checklist ─────────────────────────────────────────────────────────
      final tl = line.trim();
      if (tl.startsWith('- [x]') || tl.startsWith('- [X]') || tl.startsWith('[x]') || tl.startsWith('[X]')) {
        final t = tl.replaceFirst(RegExp(r'^-?\s*\[[xX]\]\s*'), '');
        blocks.add(PdfContentBlock(type: PdfBlockType.checklist, text: t, isChecked: true));
        continue;
      }
      if (tl.startsWith('- [ ]') || tl.startsWith('[ ]')) {
        final t = tl.replaceFirst(RegExp(r'^-?\s*\[\s\]\s*'), '');
        blocks.add(PdfContentBlock(type: PdfBlockType.checklist, text: t, isChecked: false));
        continue;
      }

      // ── Ordered list ──────────────────────────────────────────────────────
      final ordM = orderedRe.firstMatch(line);
      if (ordM != null) {
        final indent = (line.length - line.trimLeft().length) ~/ 4;
        orderedCounter = int.tryParse(ordM.group(1) ?? '1') ?? (orderedCounter + 1);
        blocks.add(PdfContentBlock(type: PdfBlockType.ordered, text: ordM.group(2)!, orderedIndex: orderedCounter, indentLevel: indent));
        continue;
      } else {
        orderedCounter = 0;
      }

      // ── Bullet list ───────────────────────────────────────────────────────
      if (tl.startsWith('- ') || tl.startsWith('* ') || tl.startsWith('+ ')) {
        final indent = (line.length - line.trimLeft().length) ~/ 4;
        final text = tl.substring(2);
        blocks.add(PdfContentBlock(type: PdfBlockType.bullet, text: text, indentLevel: indent));
        continue;
      }

      // ── Empty ─────────────────────────────────────────────────────────────
      if (tl.isEmpty) { blocks.add(PdfContentBlock(type: PdfBlockType.paragraph, text: '')); continue; }

      // ── Paragraph ─────────────────────────────────────────────────────────
      final divAlignM = RegExp(r'^<div\s+align="(.*?)">(.*)</div>$').firstMatch(line);
      if (divAlignM != null) {
        blocks.add(PdfContentBlock(type: PdfBlockType.paragraph, text: divAlignM.group(2)!, altText: divAlignM.group(1)));
      } else {
        blocks.add(PdfContentBlock(type: PdfBlockType.paragraph, text: line));
      }
    }

    // flush open states
    if (inTable && tableRows.isNotEmpty) {
      blocks.add(PdfContentBlock(type: PdfBlockType.table, text: '', tableData: List.from(tableRows)));
    }
    if (inCodeBlock && codeLines.isNotEmpty) {
      blocks.add(PdfContentBlock(type: PdfBlockType.code, text: codeLines.join('\n'), altText: codeLanguage));
    }

    return blocks;
  }

  String _cleanText(String text) {
    if (text.isEmpty) return text;
    final emojiRegex = RegExp(
      r'[\u{1f300}-\u{1f5ff}\u{1f900}-\u{1f9ff}\u{1f600}-\u{1f64f}\u{1f680}-\u{1f6ff}\u{2600}-\u{27bf}\u{1f1e6}-\u{1f1ff}\u{1f191}-\u{1f251}\u{1f004}\u{1f0cf}\u{1f170}-\u{1f171}\u{1f17e}-\u{1f17f}\u{1f18e}\u{3030}\u{2b50}\u{2b55}\u{2934}-\u{2935}\u{2b05}-\u{2b07}\u{2d82}\u{2300}-\u{23ff}\u{2000}-\u{32ff}]',
      unicode: true,
    );
    var cleaned = text.replaceAll(emojiRegex, '');
    final sb = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      final code = cleaned.codeUnitAt(i);
      if (code >= 0xD800 && code <= 0xDFFF) {
        continue;
      }
      sb.writeCharCode(code);
    }
    return sb.toString();
  }

  String _preprocessMarkdown(String text) {
    // normalise line endings
    return text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }
}

// ── Data models ──────────────────────────────────────────────────────────────

enum PdfBlockType {
  header1, header2, header3, header4, header5, header6,
  paragraph, bullet, ordered, checklist,
  blockquote, code, table, image, divider,
}

class PdfContentBlock {
  final PdfBlockType type;
  final String text;
  final String? altText;
  final List<List<String>>? tableData;
  final bool? isChecked;
  final int? indentLevel;
  final int? orderedIndex;

  const PdfContentBlock({
    required this.type,
    required this.text,
    this.altText,
    this.tableData,
    this.isChecked,
    this.indentLevel,
    this.orderedIndex,
  });
}
