import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/services.dart' show rootBundle;
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
    final pdfBytes = await generatePdfBytes(
      note,
      folderName: folderName,
      pageFormat: pageFormat,
      includeMetadata: includeMetadata,
      includeTags: includeTags,
    );

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

  static pw.Font? _fontBold;
  static pw.Font? _fontSemiBold;
  static pw.Font? _fontRegular;
  static pw.Font? _fontMono;
  static pw.Font? _fontMonoBold;
  static List<pw.Font>? _fallbacks;

  Future<Uint8List> generatePdfBytes(
    NoteModel note, {
    String? folderName,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    bool includeMetadata = true,
    bool includeTags = true,
    bool includeImages = true,
    bool includePdfs = true,
    bool includeAudio = true,
  }) async {
    final doc = pw.Document();

    final isTest = !kIsWeb && io.Platform.environment.containsKey('FLUTTER_TEST');
    try {
      if (_fontBold == null && !isTest) {
        _fontBold     = await PdfGoogleFonts.robotoBold();
        _fontSemiBold = await PdfGoogleFonts.robotoMedium();
        _fontRegular  = await PdfGoogleFonts.robotoRegular();
        _fontMono     = await PdfGoogleFonts.robotoMonoRegular();
        _fontMonoBold = await PdfGoogleFonts.robotoMonoMedium();
      }
    } catch (e) {
      debugPrint('PDF: Google Font fetch failed, using default: $e');
      _fontBold     ??= pw.Font.helveticaBold();
      _fontSemiBold ??= pw.Font.helveticaBold();
      _fontRegular  ??= pw.Font.helvetica();
      _fontMono     ??= pw.Font.courier();
      _fontMonoBold ??= pw.Font.courierBold();
    }

    if (isTest) {
      _fontBold     ??= pw.Font.helveticaBold();
      _fontSemiBold ??= pw.Font.helveticaBold();
      _fontRegular  ??= pw.Font.helvetica();
      _fontMono     ??= pw.Font.courier();
      _fontMonoBold ??= pw.Font.courierBold();
    }

    var fallbacksList = _fallbacks;
    if (fallbacksList == null) {
      fallbacksList = [];
      _fallbacks = fallbacksList;
      if (!isTest) {
        try {
          final fonts = await Future.wait([
            PdfGoogleFonts.notoSansSCRegular(),
            PdfGoogleFonts.notoSansJPRegular(),
            PdfGoogleFonts.notoSansKRRegular(),
            PdfGoogleFonts.notoSansArabicRegular(),
            PdfGoogleFonts.notoSansDevanagariRegular(),
            PdfGoogleFonts.notoSansHebrewRegular(),
            PdfGoogleFonts.notoSansThaiRegular(),
            PdfGoogleFonts.notoColorEmoji(),
          ]);
          fallbacksList.addAll(fonts);
        } catch (e) {
          debugPrint('PDF: Fallback Google Fonts fetch failed: $e');
        }
      }
    }

    final pw.Font fontBold = _fontBold ?? pw.Font.helveticaBold();
    final pw.Font fontSemiBold = _fontSemiBold ?? pw.Font.helveticaBold();
    final pw.Font fontRegular = _fontRegular ?? pw.Font.helvetica();
    final pw.Font fontMono = _fontMono ?? pw.Font.courier();
    final pw.Font fontMonoBold = _fontMonoBold ?? pw.Font.courierBold();
    final fallbacks = _fallbacks ?? [];

    final resolvedImages = <String, pw.ImageProvider>{};
    final cleanTitle = PdfDeltaParser.cleanText(note.title.isEmpty ? 'Untitled Note' : note.title);
    final cleanFolder = folderName != null ? PdfDeltaParser.cleanText(folderName) : null;
    final cleanTags = note.tags.map((t) => PdfDeltaParser.cleanText(t)).toList();

    final markdown = QuillMarkdownConverter.deltaToMarkdown(note.content);
    debugPrint('MARKDOWN DUMP:\n$markdown\n-----');
    
    final rawBlocks = PdfDeltaParser.parseNoteContent(markdown);
    debugPrint('PARSED BLOCKS: ${rawBlocks.length}');
    for (var b in rawBlocks) {
      debugPrint('Block: ${b.type} -> ${b.text}');
    }
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

        // Skip parsing if user disabled media
        if (!includeImages && (path.startsWith('photo_frame://') || (!path.startsWith('pdf://') && !path.startsWith('audio://')))) {
          continue;
        }
        if (!includePdfs && path.startsWith('pdf://')) {
          continue;
        }
        if (!includeAudio && path.startsWith('audio://')) {
          continue;
        }

        if (path.startsWith('attachment://')) {
          final id = path.replaceFirst('attachment://', '');
          final att = note.attachments.cast<AttachmentModel?>()
              .firstWhere((a) => a?.id == id, orElse: () => null);
          if (att != null) path = att.pathOrUrl;
        }
        if (resolvedImages.containsKey(block.text)) continue;
        try {
          if (path.startsWith('audio://')) {
            // we can render a placeholder for audio in pdf rendering later
            continue;
          } else if (path.startsWith('pdf://')) {
            // we can render a placeholder for pdf in pdf rendering later
            continue;
          } else if (path.startsWith('photo_frame://')) {
            // skip for now, could render a placeholder
            continue;
          } else if (path.startsWith('sticker://')) {
            final stickerName = path.replaceFirst('sticker://', '');
            final byteData = await rootBundle.load('assets/images/stickers/$stickerName.png');
            final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
            resolvedImages[block.text] = pw.MemoryImage(bytes);
          } else if (path.startsWith('data:image')) {
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

    for (var sticker in note.stickers) {
      final key = 'floating_sticker_${sticker.id}';
      if (resolvedImages.containsKey(key)) continue;
      try {
        if (sticker.name.startsWith('/') ||
            sticker.name.contains(':\\') ||
            sticker.name.contains(':/') ||
            sticker.name.startsWith('content:')) {
          final file = io.File(sticker.name);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            resolvedImages[key] = pw.MemoryImage(bytes);
          }
        } else {
          final byteData = await rootBundle.load('assets/images/stickers/${sticker.name}.png');
          final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
          resolvedImages[key] = pw.MemoryImage(bytes);
        }
      } catch (e) {
        debugPrint('PDF: floating sticker load failed: $e');
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.fromLTRB(
            pageFormat == PdfPageFormat.a4 ? 56 : 60,
            48,
            pageFormat == PdfPageFormat.a4 ? 56 : 60,
            48,
          ),
          buildForeground: (pw.Context context) {
            final pageNum = context.pageNumber;
            final pageIndex = pageNum - 1;
            final pageStickers = note.stickers.where((s) {
              final targetPage = (s.y / 700).floor();
              return targetPage == pageIndex;
            }).toList();

            if (pageStickers.isEmpty) {
              return pw.SizedBox.shrink();
            }

            return pw.Stack(
              children: pageStickers.map((sticker) {
                final img = resolvedImages['floating_sticker_${sticker.id}'];
                if (img == null) return pw.SizedBox.shrink();

                final scale = pageFormat == PdfPageFormat.a4 ? 0.70 : 0.75;
                final left = sticker.x * scale;
                final top = (sticker.y % 700) * scale;
                final width = sticker.width * scale;
                final height = sticker.height * scale;

                return pw.Positioned(
                  left: left,
                  top: top,
                  child: pw.Opacity(
                    opacity: sticker.opacity,
                    child: pw.Container(
                      width: width,
                      height: height,
                      decoration: sticker.hasBackground
                          ? pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                              border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                            )
                          : null,
                      padding: sticker.hasBackground ? const pw.EdgeInsets.all(6) : pw.EdgeInsets.zero,
                      child: pw.Stack(
                        children: [
                          pw.Image(img, fit: pw.BoxFit.contain),
                          if (sticker.textBehavior == 'over' && sticker.textOver.isNotEmpty)
                            pw.Center(
                              child: pw.Padding(
                                padding: const pw.EdgeInsets.all(2),
                                child: pw.Text(
                                  sticker.textOver,
                                  style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 8,
                                    color: PdfColors.grey900,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          theme: pw.ThemeData.withFont(
            base: fontRegular,
            bold: fontBold,
            italic: fontRegular,
            boldItalic: fontBold,
            fontFallback: fallbacks,
          ),
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

            ...contentBlocks.map((block) {
              if (block.type == PdfBlockType.image) {
                var path = block.text;
                if (!includeImages && (path.startsWith('photo_frame://') || (!path.startsWith('pdf://') && !path.startsWith('audio://')))) {
                   return pw.Container(
                     margin: const pw.EdgeInsets.symmetric(vertical: 8),
                     padding: const pw.EdgeInsets.all(12),
                     color: PdfColors.grey200,
                     child: pw.Center(child: pw.Text('[Image removed by export setting]', style: pw.TextStyle(color: PdfColors.grey700, fontStyle: pw.FontStyle.italic))),
                   );
                }
                if (!includePdfs && path.startsWith('pdf://')) {
                   return pw.Container(
                     margin: const pw.EdgeInsets.symmetric(vertical: 8),
                     padding: const pw.EdgeInsets.all(12),
                     color: PdfColors.grey200,
                     child: pw.Center(child: pw.Text('[PDF removed by export setting]', style: pw.TextStyle(color: PdfColors.grey700, fontStyle: pw.FontStyle.italic))),
                   );
                }
                if (!includeAudio && path.startsWith('audio://')) {
                   return pw.Container(
                     margin: const pw.EdgeInsets.symmetric(vertical: 8),
                     padding: const pw.EdgeInsets.all(12),
                     color: PdfColors.grey200,
                     child: pw.Center(child: pw.Text('[Voice Note removed by export setting]', style: pw.TextStyle(color: PdfColors.grey700, fontStyle: pw.FontStyle.italic))),
                   );
                }

                if (path.startsWith('pdf://')) {
                   final name = block.altText ?? 'Document';
                   return pw.Container(
                     margin: const pw.EdgeInsets.symmetric(vertical: 8),
                     padding: const pw.EdgeInsets.all(12),
                     decoration: pw.BoxDecoration(color: PdfColors.blue50, border: pw.Border.all(color: PdfColors.blue200)),
                     child: pw.Center(child: pw.Text('Attached PDF: $name', style: pw.TextStyle(color: PdfColors.blue800))),
                   );
                }
                if (path.startsWith('audio://')) {
                   return pw.Container(
                     margin: const pw.EdgeInsets.symmetric(vertical: 8),
                     padding: const pw.EdgeInsets.all(12),
                     decoration: pw.BoxDecoration(color: PdfColors.green50, border: pw.Border.all(color: PdfColors.green200)),
                     child: pw.Center(child: pw.Text('Attached Voice Note', style: pw.TextStyle(color: PdfColors.green800))),
                   );
                }
                if (path.startsWith('photo_frame://')) {
                   return pw.Container(
                     margin: const pw.EdgeInsets.symmetric(vertical: 8),
                     padding: const pw.EdgeInsets.all(12),
                     decoration: pw.BoxDecoration(color: PdfColors.amber50, border: pw.Border.all(color: PdfColors.amber200)),
                     child: pw.Center(child: pw.Text('Attached Photo Collection', style: pw.TextStyle(color: PdfColors.amber800))),
                   );
                }
              }

              return PdfBlockRenderer.renderBlock(
                block,
                fontBold: fontBold,
                fontSemiBold: fontSemiBold,
                fontRegular: fontRegular,
                fontMono: fontMono,
                fontMonoBold: fontMonoBold,
                resolvedImages: resolvedImages,
              );
            }),
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

    return pdfBytes;
  }
}
