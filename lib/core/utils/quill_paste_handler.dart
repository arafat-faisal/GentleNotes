import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'quill_markdown_converter.dart';
import 'logger.dart';

class QuillPasteHandler {
  static bool detectMarkdown(String text) {
    if (text.isEmpty) return false;
    
    final headingRegex = RegExp(r'^#{1,6}\s+', multiLine: true);
    final bulletRegex = RegExp(r'^(\s*)[-*+]\s+', multiLine: true);
    final orderedRegex = RegExp(r'^(\s*)\d+\.\s+', multiLine: true);
    final checklistRegex = RegExp(r'^(\s*)[-*+]\s+\[[\s_xX]?\]\s+', multiLine: true);
    final codeBlockRegex = RegExp(r'```');
    final blockquoteRegex = RegExp(r'^(\s*)>\s+', multiLine: true);
    final tableRegex = RegExp(r'^\s*\|.*\|', multiLine: true);
    final inlineFormatRegex = RegExp(r'\*\*.*?\*\*|\*.*?\*|~~.*?~~|`.*?`|<u>.*?</u>');
    final linkRegex = RegExp(r'\[.*?\]\(.*?\)');
    final hrRegex = RegExp(r'^\s*(\*|-|_)\s*\1\s*\1\s*(\1|\s)*$', multiLine: true);
    final mathRegex = RegExp(r'\$\$|\\int_');
    
    return headingRegex.hasMatch(text) ||
        bulletRegex.hasMatch(text) ||
        orderedRegex.hasMatch(text) ||
        checklistRegex.hasMatch(text) ||
        codeBlockRegex.hasMatch(text) ||
        blockquoteRegex.hasMatch(text) ||
        tableRegex.hasMatch(text) ||
        inlineFormatRegex.hasMatch(text) ||
        linkRegex.hasMatch(text) ||
        hrRegex.hasMatch(text) ||
        mathRegex.hasMatch(text);
  }

  static String _extractLanguage(String html) {
    final classDouble = RegExp(r'class="[^"]*(?:language-|lang-)([a-zA-Z0-9_\-\+\#]+)', caseSensitive: false).firstMatch(html);
    if (classDouble != null) return classDouble.group(1)!;

    final classSingle = RegExp(r"class='[^']*(?:language-|lang-)([a-zA-Z0-9_\-\+\#]+)", caseSensitive: false).firstMatch(html);
    if (classSingle != null) return classSingle.group(1)!;

    final dataLangDouble = RegExp(r'data-language="([a-zA-Z0-9_\-\+\#]+)"', caseSensitive: false).firstMatch(html);
    if (dataLangDouble != null) return dataLangDouble.group(1)!;

    final dataLangSingle = RegExp(r"data-language='([a-zA-Z0-9_\-\+\#]+)'", caseSensitive: false).firstMatch(html);
    if (dataLangSingle != null) return dataLangSingle.group(1)!;

    return '';
  }

  static String _cleanCodeContent(String content) {
    return content
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
  }

  static String _convertTableToMarkdown(String tableHtml) {
    final rows = <List<String>>[];
    final trRegex = RegExp(r'<tr[^>]*>([\s\S]*?)</tr>', caseSensitive: false);
    final cellRegex = RegExp(r'<t[hd][^>]*>([\s\S]*?)</t[hd]>', caseSensitive: false);

    for (final trMatch in trRegex.allMatches(tableHtml)) {
      final trContent = trMatch.group(1) ?? '';
      final rowCells = <String>[];
      for (final cellMatch in cellRegex.allMatches(trContent)) {
        final cellContent = cellMatch.group(1) ?? '';
        final clean = cellContent
            .replaceAll(RegExp(r'<[^>]+>'), '')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&amp;', '&')
            .replaceAll('&quot;', '"')
            .replaceAll('&#39;', "'")
            .replaceAll('&nbsp;', ' ')
            .replaceAll('\n', ' ')
            .replaceAll('\r', ' ')
            .trim();
        rowCells.add(clean);
      }
      if (rowCells.isNotEmpty) {
        rows.add(rowCells);
      }
    }

    if (rows.isEmpty) return '';

    final buf = StringBuffer('\n');
    final headerRow = rows.first;
    buf.write('| ${headerRow.join(' | ')} |\n');

    final separators = List.filled(headerRow.length, '---');
    buf.write('| ${separators.join(' | ')} |\n');

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < headerRow.length) {
        row.addAll(List.filled(headerRow.length - row.length, ''));
      }
      final trimmedRow = row.sublist(0, headerRow.length);
      buf.write('| ${trimmedRow.join(' | ')} |\n');
    }
    buf.write('\n');
    return buf.toString();
  }

  static String _convertListToMarkdown(String listHtml, bool isOrdered) {
    final liRegex = RegExp(r'<li[^>]*>([\s\S]*?)</li>', caseSensitive: false);
    final inputRegex = RegExp(r'<input[^>]+type=[\x22\x27]?checkbox[\x22\x27]?[^>]*>', caseSensitive: false);
    
    int index = 1;
    final buf = StringBuffer();
    
    for (final liMatch in liRegex.allMatches(listHtml)) {
      String content = liMatch.group(1) ?? '';
      
      final lines = content.split('\n');
      final processedLines = <String>[];
      for (final line in lines) {
        final trimmed = line.trimLeft();
        if (trimmed.startsWith('-') || RegExp(r'^\d+\.').hasMatch(trimmed)) {
          processedLines.add('  $line');
        } else {
          processedLines.add(line);
        }
      }
      content = processedLines.join('\n');

      final inputMatch = inputRegex.firstMatch(content);
      if (inputMatch != null) {
        final inputTag = inputMatch.group(0)!;
        final isChecked = RegExp(r'\bchecked\b', caseSensitive: false).hasMatch(inputTag);
        final cleanContent = content.replaceFirst(inputRegex, '').trim();
        buf.write(isChecked ? '- [x] $cleanContent\n' : '- [ ] $cleanContent\n');
      } else {
        if (isOrdered) {
          buf.write('$index. ${content.trim()}\n');
          index++;
        } else {
          buf.write('- ${content.trim()}\n');
        }
      }
    }
    return buf.toString().trim();
  }

  static String _cleanHtmlWhitespace(String html) {
    final preBlocks = <String>[];
    final placeholder = '___PRE_BLOCK_PLACEHOLDER_';
    
    final preRegex = RegExp(r'<pre[^>]*>[\s\S]*?</pre>', caseSensitive: false);
    String cleanHtml = html.replaceAllMapped(preRegex, (m) {
      preBlocks.add(m.group(0)!);
      return '$placeholder${preBlocks.length - 1}___';
    });
    
    final lines = cleanHtml.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    final trimmedLines = lines.map((line) => line.trim()).where((line) => line.isNotEmpty);
    cleanHtml = trimmedLines.join('\n');
    
    for (int i = 0; i < preBlocks.length; i++) {
      cleanHtml = cleanHtml.replaceFirst('$placeholder${i}___', preBlocks[i]);
    }
    
    return cleanHtml;
  }

  static String convertHtmlToMarkdown(String htmlText) {
    String result = _cleanHtmlWhitespace(htmlText);

    // Remove style and script tag blocks entirely
    result = result.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), '');
    result = result.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), '');

    // Convert headings
    result = result.replaceAllMapped(RegExp(r'<h1[^>]*>([\s\S]*?)</h1>', caseSensitive: false), (m) => '# ${m[1]}\n\n');
    result = result.replaceAllMapped(RegExp(r'<h2[^>]*>([\s\S]*?)</h2>', caseSensitive: false), (m) => '## ${m[1]}\n\n');
    result = result.replaceAllMapped(RegExp(r'<h3[^>]*>([\s\S]*?)</h3>', caseSensitive: false), (m) => '### ${m[1]}\n\n');
    result = result.replaceAllMapped(RegExp(r'<h[4-6][^>]*>([\s\S]*?)</h[4-6]>', caseSensitive: false), (m) => '### ${m[1]}\n\n');

    // Code blocks: match pre block and extract language + clean code content robustly
    result = result.replaceAllMapped(
      RegExp(r'<pre[^>]*>([\s\S]*?)</pre>', caseSensitive: false),
      (m) {
        final innerHtml = m[1] ?? '';
        final lang = _extractLanguage(m.group(0) ?? '');
        final cleanCode = _cleanCodeContent(innerHtml);
        return '\n```$lang\n$cleanCode\n```\n';
      },
    );

    // Convert inline formatting BEFORE stripping tags
    result = result.replaceAllMapped(RegExp(r'<strong[^>]*>([\s\S]*?)</strong>', caseSensitive: false), (m) => '**${m[1]}**');
    result = result.replaceAllMapped(RegExp(r'<b[^>]*>([\s\S]*?)</b>', caseSensitive: false), (m) => '**${m[1]}**');
    result = result.replaceAllMapped(RegExp(r'<em[^>]*>([\s\S]*?)</em>', caseSensitive: false), (m) => '*${m[1]}*');
    result = result.replaceAllMapped(RegExp(r'<i[^>]*>([\s\S]*?)</i>', caseSensitive: false), (m) => '*${m[1]}*');
    result = result.replaceAllMapped(RegExp(r'<u[^>]*>([\s\S]*?)</u>', caseSensitive: false), (m) => '<u>${m[1]}</u>');
    result = result.replaceAllMapped(RegExp(r'<del[^>]*>([\s\S]*?)</del>', caseSensitive: false), (m) => '~~${m[1]}~~');
    result = result.replaceAllMapped(RegExp(r'<s[^>]*>([\s\S]*?)</s>', caseSensitive: false), (m) => '~~${m[1]}~~');
    result = result.replaceAllMapped(RegExp(r'<code[^>]*>([\s\S]*?)</code>', caseSensitive: false), (m) => '`${m[1]}`');
    result = result.replaceAllMapped(RegExp(r'<mark[^>]*style="[^"]*background[:\s]*([^;"]+)[^"]*"[^>]*>([\s\S]*?)</mark>', caseSensitive: false), (m) => '<mark style="background:${m[1]}">${m[2]}</mark>');

    // Convert links
    result = result.replaceAllMapped(RegExp(r'<a[^>]+href="([^"]*)"[^>]*>([\s\S]*?)</a>', caseSensitive: false), (m) => '[${m[2]}](${m[1]})');

    // Convert details/summary
    result = result.replaceAllMapped(
      RegExp(r'<details[^>]*>\s*<summary[^>]*>([\s\S]*?)</summary>([\s\S]*?)</details>', caseSensitive: false),
      (m) => '\n**${(m[1] ?? "").trim()}**\n\n${(m[2] ?? "").trim()}\n\n',
    );

    // Convert tables
    result = result.replaceAllMapped(
      RegExp(r'<table[^>]*>([\s\S]*?)</table>', caseSensitive: false),
      (m) => _convertTableToMarkdown(m.group(0) ?? ''),
    );

    // Convert blockquotes (handle nesting recursively)
    int safety = 0;
    while (result.contains(RegExp(r'<blockquote', caseSensitive: false)) && safety < 5) {
      result = result.replaceAllMapped(
        RegExp(r'<blockquote[^>]*>((?:(?!</?blockquote\b)[\s\S])*?)</blockquote>', caseSensitive: false),
        (m) {
          final content = m[1] ?? '';
          final lines = content.split('\n');
          final formattedLines = lines.map((l) {
            final trimmed = l.trim();
            if (trimmed.isEmpty) return '>';
            if (trimmed.startsWith('>')) return '>$trimmed';
            return '> $trimmed';
          }).join('\n');
          return '\n$formattedLines\n';
        },
      );
      safety++;
    }

    // Convert lists (handle nesting recursively)
    int listSafety = 0;
    final listRegex = RegExp(r'<(ul|ol)[^>]*>((?:(?!</?(?:ul|ol)\b)[\s\S])*?)</\1>', caseSensitive: false);
    while (result.contains(RegExp(r'<(ul|ol)', caseSensitive: false)) && listSafety < 10) {
      result = result.replaceAllMapped(listRegex, (m) {
        final tag = m[1]!.toLowerCase();
        final content = m[2] ?? '';
        final isOrdered = tag == 'ol';
        return _convertListToMarkdown(content, isOrdered);
      });
      listSafety++;
    }

    // Convert horizontal rules
    result = result.replaceAll(RegExp(r'<hr[^>]*/?>', caseSensitive: false), '\n***\n\n');

    // Convert block-level elements to line breaks BEFORE stripping them
    result = result.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    result = result.replaceAllMapped(RegExp(r'<p[^>]*>([\s\S]*?)</p>', caseSensitive: false), (m) => '${m[1]}\n\n');
    result = result.replaceAll(RegExp(r'<div[^>]*>', caseSensitive: false), '\n');
    result = result.replaceAll(RegExp(r'</div>', caseSensitive: false), '');

    // Strip ALL remaining HTML tags — keep only text content and our markdown markers
    result = result.replaceAll(RegExp(r'<(?!/?(u|mark)\b)[^>]+>', caseSensitive: false), '');

    // Clean up HTML entities
    result = result
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');

    // Collapse excessive blank lines
    result = result.split('\n').map((line) => line.trim().isEmpty ? '' : line).join('\n');
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();

    return result;
  }


  /// Primary entry point called from the [Actions] paste handler in the editor.
  ///
  /// Reads both HTML and plain text from the system clipboard concurrently.
  /// HTML (available when copying from browsers) is preferred because it
  /// carries formatting that plain text drops (bold, headings, links, etc.).
  /// Both are forwarded to [handlePasteText] which converts to Quill delta.
  static void pasteFromClipboard(QuillController quillController) {
    Future.wait([
      Clipboard.getData('text/html').catchError((_) => null),
      Clipboard.getData(Clipboard.kTextPlain).catchError((_) => null),
    ]).then((results) {
      final htmlData  = results[0];
      final plainData = results[1];
      final plainText = plainData?.text ?? '';
      final htmlText  = htmlData?.text;
      if (plainText.isNotEmpty || (htmlText != null && htmlText.isNotEmpty)) {
        handlePasteText(quillController, plainText, htmlText);
      }
    });
  }

  static Future<void> handlePasteText(
    QuillController quillController,
    String plainText, [
    String? htmlText,
  ]) async {
    AppLogger.info('QuillPasteHandler: handlePasteText invoked. Plain text length: ${plainText.length}. HTML text present: ${htmlText != null}');
    // Prefer HTML when available (preserves bold, headings, links from browsers)
    String textToParse = plainText;
    if (htmlText != null && htmlText.isNotEmpty) {
      textToParse = convertHtmlToMarkdown(htmlText);
      AppLogger.info('QuillPasteHandler: Converted HTML to Markdown. Length: ${textToParse.length}');
    }
    if (textToParse.isEmpty) return;

    // Calculate insertion point — guard against reversed/collapsed selections.
    final base   = quillController.selection.baseOffset;
    final extent = quillController.selection.extentOffset;
    final insertIndex    = base >= 0 ? base : quillController.document.length - 1;
    final selectionLength = (extent - base).abs();

    // Always run through the markdown→delta converter.
    // For plain text with no markdown, markdownToDeltaOps produces simple
    // insert ops with no attributes — the user never sees raw symbols.
    final ops = QuillMarkdownConverter.markdownToDeltaOps(textToParse);
    AppLogger.info('QuillPasteHandler: Converted text to ${ops.length} Delta operations.');

    // Strip trailing bare newline the converter appends when the source
    // text didn't end with one — avoids an unwanted blank line after paste.
    if (ops.isNotEmpty && !textToParse.endsWith('\n')) {
      final lastOp = ops.last;
      if (lastOp['insert'] == '\n' &&
          (lastOp['attributes'] == null ||
              (lastOp['attributes'] as Map).isEmpty)) {
        ops.removeLast();
      }
    }

    final change = Delta();
    if (insertIndex > 0) change.retain(insertIndex);
    if (selectionLength > 0) change.delete(selectionLength);

    int pastedLength = 0;
    for (final op in ops) {
      final insertVal = op['insert'];
      final attrs = op['attributes'] as Map<String, dynamic>?;
      change.insert(insertVal, attrs);
      pastedLength += insertVal is String ? insertVal.length : 1;
    }

    quillController.document.compose(change, ChangeSource.local);
    quillController.updateSelection(
      TextSelection.collapsed(offset: insertIndex + pastedLength),
      ChangeSource.local,
    );
  }
}
