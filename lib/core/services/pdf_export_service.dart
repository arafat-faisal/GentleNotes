import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/models.dart';
import '../utils/quill_markdown_converter.dart';
import 'pdf/pdf_block_renderer.dart';
import 'pdf/pdf_delta_parser.dart';
import 'pdf/pdf_document_builder.dart';

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

    final resolvedImages = <String, pw.ImageProvider>{};
    final cleanTitle = PdfDeltaParser.cleanText(note.title.isEmpty ? 'Untitled Note' : note.title);
    final cleanFolder = folderName != null ? PdfDeltaParser.cleanText(folderName) : null;
    final cleanTags = note.tags.map((t) => PdfDeltaParser.cleanText(t)).toList();

    final markdown = QuillMarkdownConverter.deltaToMarkdown(note.content);
    final rawBlocks = PdfDeltaParser.parseNoteContent(markdown);
    final contentBlocks = rawBlocks.map((b) {
      if (b.type == PdfBlockType.image) return b;
      if (b.type == PdfBlockType.table) {
        final cleanedTable = b.tableData?.map((row) {
          return row.map((cell) => PdfDeltaParser.cleanText(cell)).toList();
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
        text: PdfDeltaParser.cleanText(b.text),
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
        header: (ctx) => PdfDocumentBuilder.buildHeader(fontSemiBold, fontRegular, cleanTitle),
        footer: (ctx) => PdfDocumentBuilder.buildFooter(ctx, fontSemiBold, fontRegular),
        build: (ctx) {
          return [
            pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(color: PdfDocumentColors.violet, width: 4)),
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
                      color: PdfDocumentColors.grey900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            if (includeMetadata) ...[
              pw.Row(
                children: [
                  if (cleanFolder != null) ...[
                    PdfDocumentBuilder.buildPill(cleanFolder, fontSemiBold, PdfDocumentColors.violet, PdfDocumentColors.violetLight),
                    pw.SizedBox(width: 8),
                  ],
                  PdfDocumentBuilder.buildPill(
                    PdfDocumentBuilder.formatDate(note.createdAt),
                    fontRegular, PdfDocumentColors.grey700, PdfDocumentColors.grey100,
                  ),
                  if (note.updatedAt != note.createdAt) ...[
                    pw.SizedBox(width: 8),
                    PdfDocumentBuilder.buildPill(
                       'Updated ${PdfDocumentBuilder.formatDate(note.updatedAt)}',
                      fontRegular, PdfDocumentColors.grey700, PdfDocumentColors.grey100,
                    ),
                  ],
                ],
              ),
              pw.SizedBox(height: 8),
            ],

            if (includeTags && cleanTags.isNotEmpty) ...[
              pw.Wrap(
                spacing: 6,
                runSpacing: 4,
                children: cleanTags
                    .map((t) => PdfDocumentBuilder.buildPill('#$t', fontSemiBold, PdfDocumentColors.violet, PdfDocumentColors.violetLight))
                    .toList(),
              ),
              pw.SizedBox(height: 10),
            ],

            pw.Divider(thickness: 1, color: PdfDocumentColors.violet),
            pw.SizedBox(height: 16),

            ...contentBlocks.map((block) => PdfBlockRenderer.renderBlock(
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
}
