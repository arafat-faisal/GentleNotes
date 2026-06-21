import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/pdf_annotation_model.dart';
import '../../data/models/pdf_bookmark_model.dart';

class PdfAnnotationExporter {
  static Future<void> exportToMarkdown({
    required BuildContext context,
    required String pdfName,
    required List<PdfAnnotationModel> annotations,
    required List<PdfBookmarkModel> bookmarks,
  }) async {
    try {
      final sb = StringBuffer();
      sb.writeln('# GentleNotes Study Summary: $pdfName');
      sb.writeln('Generated on: ${DateTime.now().toLocal().toString().split('.')[0]}');
      sb.writeln();

      if (bookmarks.isNotEmpty) {
        sb.writeln('## 📌 Bookmarked Pages');
        for (var b in bookmarks) {
          sb.writeln('- **Page ${b.pageNumber}**: ${b.label}');
        }
        sb.writeln();
      }

      if (annotations.isNotEmpty) {
        sb.writeln('## 📝 Annotations & Highlights');

        // Group by category/type
        final highlights = annotations.where((a) => a.type == 'highlight').toList();
        final markups = annotations.where((a) => ['underline', 'strikethrough', 'squiggly'].contains(a.type)).toList();
        final notes = annotations.where((a) => a.type == 'note').toList();
        final flashcards = annotations.where((a) => a.type == 'flashcard').toList();
        final snapshots = annotations.where((a) => a.type == 'snapshot').toList();

        if (highlights.isNotEmpty) {
          sb.writeln('### 💡 Highlights');
          for (var h in highlights) {
            sb.writeln('- **Page ${h.pageNumber}** (Category: ${h.colorHex == "#FFF176" ? "Concept" : h.colorHex == "#FF8A80" ? "Exam" : h.colorHex == "#A5D6A7" ? "Definition" : h.colorHex == "#90CAF9" ? "Doubt" : h.colorHex == "#FFCC80" ? "Formula" : "Example"}):');
            sb.writeln('  > ${h.selectedText?.trim() ?? ""}');
            if (h.noteText != null && h.noteText!.isNotEmpty) {
              sb.writeln('  - *Personal Note:* ${h.noteText}');
            }
            sb.writeln();
          }
        }

        if (markups.isNotEmpty) {
          sb.writeln('### ✏️ Text Markups');
          for (var m in markups) {
            sb.writeln('- **Page ${m.pageNumber}** [${m.type.toUpperCase()}]:');
            sb.writeln('  > ${m.selectedText?.trim() ?? ""}');
            sb.writeln();
          }
        }

        if (notes.isNotEmpty) {
          sb.writeln('### 💬 Margin Notes / Comments');
          for (var n in notes) {
            sb.writeln('- **Page ${n.pageNumber}**:');
            if (n.selectedText != null && n.selectedText!.isNotEmpty) {
              sb.writeln('  *Context text:* > ${n.selectedText}');
            }
            sb.writeln('  *Comment:* ${n.noteText}');
            sb.writeln();
          }
        }

        if (snapshots.isNotEmpty) {
          sb.writeln('### 📷 Visual Snapshots');
          for (var s in snapshots) {
            sb.writeln('- **Page ${s.pageNumber}**:');
            if (s.snapshotPath != null) {
              sb.writeln('  ![Visual Snapshot](file://${s.snapshotPath})');
            }
            sb.writeln();
          }
        }

        if (flashcards.isNotEmpty) {
          sb.writeln('### 🗂️ Study Flashcards');
          for (var f in flashcards) {
            sb.writeln('- **Page ${f.pageNumber}**:');
            sb.writeln('  * **Question**: ${f.flashcardQuestion}');
            sb.writeln('  * **Answer**: ${f.flashcardAnswer}');
            sb.writeln();
          }
        }
      } else {
        sb.writeln('No study notes or annotations added yet.');
      }

      final tempDir = await getTemporaryDirectory();
      final sanitizedPdfName = pdfName.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final file = File('${tempDir.path}/StudyNotes_$sanitizedPdfName.md');
      await file.writeAsString(sb.toString());

      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: 'Study Notes for $pdfName');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Study summary exported successfully!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export annotations: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
