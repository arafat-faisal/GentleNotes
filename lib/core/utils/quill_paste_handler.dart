import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'quill_markdown_converter.dart';

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

  static String convertHtmlToMarkdown(String htmlText) {
    String result = htmlText;
    
    // Remove style tags
    result = result.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), '');
    // Remove script tags
    result = result.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), '');
    // Convert headings
    result = result.replaceAllMapped(RegExp(r'<h1[^>]*>([\s\S]*?)</h1>', caseSensitive: false), (m) => '# ${m[1]}\n\n');
    result = result.replaceAllMapped(RegExp(r'<h2[^>]*>([\s\S]*?)</h2>', caseSensitive: false), (m) => '## ${m[1]}\n\n');
    result = result.replaceAllMapped(RegExp(r'<h3[^>]*>([\s\S]*?)</h3>', caseSensitive: false), (m) => '### ${m[1]}\n\n');
    
    // Convert basic inline styles
    result = result.replaceAllMapped(RegExp(r'<strong[^>]*>([\s\S]*?)</strong>', caseSensitive: false), (m) => '**${m[1]}**');
    result = result.replaceAllMapped(RegExp(r'<b[^>]*>([\s\S]*?)</b>', caseSensitive: false), (m) => '**${m[1]}**');
    result = result.replaceAllMapped(RegExp(r'<em[^>]*>([\s\S]*?)</em>', caseSensitive: false), (m) => '*${m[1]}*');
    result = result.replaceAllMapped(RegExp(r'<i[^>]*>([\s\S]*?)</i>', caseSensitive: false), (m) => '*${m[1]}*');
    result = result.replaceAllMapped(RegExp(r'<u[^>]*>([\s\S]*?)</u>', caseSensitive: false), (m) => '<u>${m[1]}</u>');
    result = result.replaceAllMapped(RegExp(r'<del[^>]*>([\s\S]*?)</del>', caseSensitive: false), (m) => '~~${m[1]}~~');
    result = result.replaceAllMapped(RegExp(r'<s[^>]*>([\s\S]*?)</s>', caseSensitive: false), (m) => '~~${m[1]}~~');
    result = result.replaceAllMapped(RegExp(r'<code[^>]*>([\s\S]*?)</code>', caseSensitive: false), (m) => '`${m[1]}`');
    
    // Convert links
    result = result.replaceAllMapped(RegExp(r'<a[^>]+href="([^"]*)"[^>]*>([\s\S]*?)</a>', caseSensitive: false), (m) => '[${m[2]}](${m[1]})');
    
    // Convert list items
    result = result.replaceAllMapped(RegExp(r'<li[^>]*>([\s\S]*?)</li>', caseSensitive: false), (m) => '- ${m[1]}\n');
    
    // Remove list structural tags
    result = result.replaceAll(RegExp(r'</?(ul|ol)>', caseSensitive: false), '\n');
    
    // Convert paragraphs & linebreaks
    result = result.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    result = result.replaceAllMapped(RegExp(r'<p[^>]*>([\s\S]*?)</p>', caseSensitive: false), (m) => '${m[1]}\n\n');
    
    // Strip remaining tags except div, span, mark, u, details, summary
    result = result.replaceAll(RegExp(r'<(?!/?(div|span|mark|u|details|summary)\b)[^>]+>', caseSensitive: false), '');
    
    // Clean up entities
    result = result
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
        
    return result;
  }

  static Future<void> handlePasteText(QuillController quillController, String plainText, [String? htmlText]) async {
    String textToParse = plainText;
    
    if (htmlText != null && htmlText.isNotEmpty) {
      textToParse = convertHtmlToMarkdown(htmlText);
    }
    
    final isMarkdown = detectMarkdown(textToParse);
    
    if (isMarkdown) {
      final ops = QuillMarkdownConverter.markdownToDeltaOps(textToParse);
      
      if (ops.isNotEmpty && !textToParse.endsWith('\n')) {
        final lastOp = ops.last;
        if (lastOp['insert'] == '\n' && (lastOp['attributes'] == null || (lastOp['attributes'] as Map).isEmpty)) {
          ops.removeLast();
        }
      }
      
      final index = quillController.selection.baseOffset;
      final insertIndex = index >= 0 ? index : quillController.document.length - 1;
      final length = quillController.selection.extentOffset - index;
      
      final change = Delta();
      if (insertIndex > 0) {
        change.retain(insertIndex);
      }
      if (length > 0) {
        change.delete(length);
      }
      
      int pastedLength = 0;
      for (final op in ops) {
        final insertVal = op['insert'];
        final attrs = op['attributes'] as Map<String, dynamic>?;
        
        change.insert(insertVal, attrs);
        if (insertVal is String) {
          pastedLength += insertVal.length;
        } else {
          pastedLength += 1;
        }
      }
      
      quillController.document.compose(change, ChangeSource.local);
      
      // Update selection to place cursor at the end of the pasted text
      quillController.updateSelection(
        TextSelection.collapsed(offset: insertIndex + pastedLength),
        ChangeSource.local,
      );
    } else {
      // Fallback: standard plain text paste
      final index = quillController.selection.baseOffset;
      final insertIndex = index >= 0 ? index : quillController.document.length - 1;
      final length = quillController.selection.extentOffset - index;
      
      quillController.replaceText(insertIndex, length, plainText, null);
      quillController.updateSelection(
        TextSelection.collapsed(offset: insertIndex + plainText.length),
        ChangeSource.local,
      );
    }
  }
}
