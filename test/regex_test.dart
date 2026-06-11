import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:gentle_notes/core/utils/quill_markdown_converter.dart';
import 'package:gentle_notes/core/services/pdf/pdf_delta_parser.dart';

void main() {
  test('Delta to Markdown to PDF Blocks test', () {
    final deltaOps = [
      {'insert': 'Here is a pdf\n'},
      {'insert': {'pdf': '{"path": "file:///fake.pdf"}'}},
      {'insert': '\nHere is imafgs\n'},
      {'insert': {'image': 'file:///data/user/0/fake_image.jpg'}},
      {'insert': '\n'}
    ];
    final deltaStr = jsonEncode(deltaOps);
    
    final markdown = QuillMarkdownConverter.deltaToMarkdown(deltaStr);
    print('MARKDOWN:\n$markdown\n---');
    
    final blocks = PdfDeltaParser.parseNoteContent(markdown);
    for (var b in blocks) {
      print('Block[${b.type}]: ${b.text}');
    }
  });
}
