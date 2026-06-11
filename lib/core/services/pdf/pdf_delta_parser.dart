
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

class PdfDeltaParser {
  static List<PdfContentBlock> parseNoteContent(String contentMarkdown) {
    final processed = _preprocessMarkdown(contentMarkdown);
    final blocks = <PdfContentBlock>[];
    final lines = processed.split('\n');

    bool inCodeBlock = false;
    String codeLanguage = '';
    final codeLines = <String>[];
    List<List<String>> tableRows = [];
    bool inTable = false;
    int orderedCounter = 0;

      final imageRe = RegExp(r'!\[(.*?)\]\(([^)]*?(?:\([^)]*\)[^)]*?)*)\)');
      final hrRe = RegExp(r'^\s*(\*|-|_)\s*\1\s*\1\s*(\1|\s)*$');
      final orderedRe = RegExp(r'^\s*(\d+)\.\s+(.+)');
      final audioRe = RegExp(r'\[(.*?)\]\((audio://[^)]*?(?:\([^)]*\)[^)]*?)*)\)');

      for (final line in lines) {
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

        final isTableRow = line.trim().startsWith('|') && line.trim().endsWith('|');
        if (isTableRow) {
          if (!inTable) { inTable = true; tableRows = []; }
          if (!RegExp(r'^\s*\|(?:\s*:?-+:?\s*\|)+\s*$').hasMatch(line)) {
            final cells = line.split('|').skip(1).toList();
            if (cells.length > 1) {
              cells.removeLast();
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

        if (hrRe.hasMatch(line)) { blocks.add(PdfContentBlock(type: PdfBlockType.divider, text: '')); continue; }

        final imgM = imageRe.firstMatch(line);
        if (imgM != null) {
          blocks.add(PdfContentBlock(type: PdfBlockType.image, text: imgM.group(2) ?? '', altText: imgM.group(1)));
          continue;
        }

        final audioM = audioRe.firstMatch(line);
        if (audioM != null) {
          blocks.add(PdfContentBlock(type: PdfBlockType.image, text: audioM.group(2) ?? '', altText: audioM.group(1)));
          continue;
        }

      if (line.startsWith('# '))       { blocks.add(PdfContentBlock(type: PdfBlockType.header1, text: line.substring(2))); orderedCounter = 0; continue; }
      if (line.startsWith('## '))      { blocks.add(PdfContentBlock(type: PdfBlockType.header2, text: line.substring(3))); orderedCounter = 0; continue; }
      if (line.startsWith('### '))     { blocks.add(PdfContentBlock(type: PdfBlockType.header3, text: line.substring(4))); orderedCounter = 0; continue; }
      if (line.startsWith('#### '))    { blocks.add(PdfContentBlock(type: PdfBlockType.header4, text: line.substring(5))); orderedCounter = 0; continue; }
      if (line.startsWith('##### '))   { blocks.add(PdfContentBlock(type: PdfBlockType.header5, text: line.substring(6))); orderedCounter = 0; continue; }
      if (line.startsWith('###### '))  { blocks.add(PdfContentBlock(type: PdfBlockType.header6, text: line.substring(7))); orderedCounter = 0; continue; }

      if (line.trim().startsWith('>')) {
        var content = line.trim();
        int level = 0;
        while (content.startsWith('>')) { level++; content = content.substring(1).trim(); }
        blocks.add(PdfContentBlock(type: PdfBlockType.blockquote, text: content, altText: level.toString()));
        continue;
      }

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

      final ordM = orderedRe.firstMatch(line);
      if (ordM != null) {
        final indent = (line.length - line.trimLeft().length) ~/ 4;
        orderedCounter = int.tryParse(ordM.group(1) ?? '1') ?? (orderedCounter + 1);
        blocks.add(PdfContentBlock(type: PdfBlockType.ordered, text: ordM.group(2)!, orderedIndex: orderedCounter, indentLevel: indent));
        continue;
      } else {
        orderedCounter = 0;
      }

      if (tl.startsWith('- ') || tl.startsWith('* ') || tl.startsWith('+ ')) {
        final indent = (line.length - line.trimLeft().length) ~/ 4;
        final text = tl.substring(2);
        blocks.add(PdfContentBlock(type: PdfBlockType.bullet, text: text, indentLevel: indent));
        continue;
      }

      if (tl.isEmpty) { blocks.add(PdfContentBlock(type: PdfBlockType.paragraph, text: '')); continue; }

      final divAlignM = RegExp(r'^<div\s+align="(.*?)">(.*)</div>$').firstMatch(line);
      if (divAlignM != null) {
        blocks.add(PdfContentBlock(type: PdfBlockType.paragraph, text: divAlignM.group(2)!, altText: divAlignM.group(1)));
      } else {
        blocks.add(PdfContentBlock(type: PdfBlockType.paragraph, text: line));
      }
    }

    if (inTable && tableRows.isNotEmpty) {
      blocks.add(PdfContentBlock(type: PdfBlockType.table, text: '', tableData: List.from(tableRows)));
    }
    if (inCodeBlock && codeLines.isNotEmpty) {
      blocks.add(PdfContentBlock(type: PdfBlockType.code, text: codeLines.join('\n'), altText: codeLanguage));
    }

    return blocks;
  }

  static String cleanText(String text) {
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

  static String _preprocessMarkdown(String text) {
    return text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }
}
