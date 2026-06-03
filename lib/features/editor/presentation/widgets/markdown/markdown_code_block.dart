import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'markdown_renderer.dart';

class MarkdownCodeBlock extends StatelessWidget {
  final MarkdownCustomBlock block;
  final String activeCodeTheme;

  const MarkdownCodeBlock({
    super.key,
    required this.block,
    required this.activeCodeTheme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = activeCodeTheme.contains('dark') || activeCodeTheme == 'monokai';
    final codeText = block.text;
    final language = block.altText ?? 'code';
    final highlighter = GentleSyntaxHighlighter(context, activeCodeTheme);
    final formattedSpan = highlighter.format(codeText, language);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDarkTheme ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: isDarkTheme ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: codeText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied to clipboard!'),
                        duration: Duration(seconds: 1),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.copy_rounded,
                        size: 12,
                        color: isDarkTheme ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'COPY',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isDarkTheme ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText.rich(
                formattedSpan,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GentleSyntaxHighlighter {
  final BuildContext context;
  final String theme;

  GentleSyntaxHighlighter(this.context, this.theme);

  TextSpan format(String code, [String? language]) {
    final List<TextSpan> spans = [];
    final lines = code.split('\n');
    final isDark = theme.contains('dark') || theme == 'monokai';

    final keywordStyle = TextStyle(color: isDark ? const Color(0xFFF97316) : const Color(0xFFC2410C), fontWeight: FontWeight.bold);
    final stringStyle = TextStyle(color: isDark ? const Color(0xFF10B981) : const Color(0xFF047857));
    final commentStyle = TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B), fontStyle: FontStyle.italic);
    final numberStyle = TextStyle(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1));
    final keyStyle = TextStyle(color: isDark ? const Color(0xFFF472B6) : const Color(0xFFDB2777), fontWeight: FontWeight.bold);
    final defaultStyle = TextStyle(color: isDark ? Colors.white : Colors.black87);

    final lang = language?.toLowerCase().trim().replaceAll('.', '') ?? 'code';

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (lang == 'env') {
        final eqIdx = line.indexOf('=');
        if (eqIdx != -1) {
          final key = line.substring(0, eqIdx);
          final value = line.substring(eqIdx);
          spans.add(TextSpan(text: key, style: keyStyle));
          spans.add(TextSpan(text: value, style: stringStyle));
        } else {
          spans.add(TextSpan(text: line, style: defaultStyle));
        }
      } else if (lang == 'yaml' || lang == 'yml') {
        final colIdx = line.indexOf(':');
        if (colIdx != -1 && !line.trim().startsWith('#')) {
          final key = line.substring(0, colIdx + 1);
          final value = line.substring(colIdx + 1);
          spans.add(TextSpan(text: key, style: keyStyle));
          spans.add(TextSpan(text: value, style: stringStyle));
        } else if (line.trim().startsWith('#')) {
          spans.add(TextSpan(text: line, style: commentStyle));
        } else {
          spans.add(TextSpan(text: line, style: defaultStyle));
        }
      } else {
        RegExp combinedRegex;
        
        if (lang == 'json') {
          combinedRegex = RegExp(
            r'("(?:\\.|[^"\\])*"\s*:)|'
            r'("(?:\\.|[^"\\])*")|'
            r'(\b\d+(?:\.\d+)?\b)|'
            r'(\b(?:true|false|null)\b)',
            multiLine: true,
          );
        } else if (lang == 'sql') {
          final sqlKeywords = [
            'select', 'insert', 'update', 'delete', 'from', 'where', 'join', 'inner', 'left', 'right',
            'outer', 'on', 'order', 'by', 'group', 'having', 'limit', 'offset', 'and', 'or', 'not',
            'in', 'is', 'null', 'into', 'values', 'create', 'table', 'drop', 'alter', 'index', 'key',
            'primary', 'foreign', 'references', 'desc', 'asc', 'as', 'set', 'union', 'all'
          ];
          
          combinedRegex = RegExp(
            r'(--.*)|'
            r"('(?:\\.|[^'\\])*'|&quot;(?:\\.|[^&])*&quot;|\u0022(?:\\.|[^\u0022\\])*\u0022)|"
            r'(\b\d+(?:\.\d+)?\b)|'
            r'(\b(?:' + sqlKeywords.join('|') + r')\b)',
            multiLine: true,
            caseSensitive: false,
          );
        } else {
          final keywords = {
            'class', 'struct', 'enum', 'void', 'int', 'double', 'float', 'bool', 'string', 'final', 'const',
            'var', 'let', 'function', 'def', 'import', 'from', 'as', 'return', 'if', 'else', 'elif', 'for', 'while',
            'switch', 'case', 'break', 'continue', 'true', 'false', 'null', 'package', 'public',
            'private', 'protected', 'extends', 'implements', 'override', 'async', 'await', 'yield', 'in',
            'try', 'except', 'catch', 'finally', 'throw', 'new', 'delete', 'namespace', 'using', 'std', 'cout', 'endl'
          };
          combinedRegex = RegExp(
            r'(//.*|#.*|/\*[\s\S]*?\*/)|'
            r"('(?:\\.|[^'\\])*'|&quot;(?:\\.|[^&])*&quot;|\u0022(?:\\.|[^\u0022\\])*\u0022)|"
            r'(\b\d+(?:\.\d+)?\b)|'
            r'(\b(?:' + keywords.join('|') + r')\b)',
            multiLine: true,
          );
        }

        int lastIndex = 0;
        for (final match in combinedRegex.allMatches(line)) {
          if (match.start > lastIndex) {
            spans.add(TextSpan(text: line.substring(lastIndex, match.start), style: defaultStyle));
          }

          final matchedText = match.group(0)!;
          if (match.group(1) != null) {
            if (lang == 'json') {
              spans.add(TextSpan(text: matchedText, style: keyStyle));
            } else {
              spans.add(TextSpan(text: matchedText, style: commentStyle));
            }
          } else if (match.group(2) != null) {
            spans.add(TextSpan(text: matchedText, style: stringStyle));
          } else if (match.group(3) != null) {
            spans.add(TextSpan(text: matchedText, style: numberStyle));
          } else if (match.group(4) != null) {
            spans.add(TextSpan(text: matchedText, style: keywordStyle));
          } else {
            spans.add(TextSpan(text: matchedText, style: defaultStyle));
          }
          lastIndex = match.end;
        }

        if (lastIndex < line.length) {
          spans.add(TextSpan(text: line.substring(lastIndex), style: defaultStyle));
        }
      }

      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return TextSpan(children: spans, style: const TextStyle(fontFamily: 'Courier', fontSize: 13));
  }
}
