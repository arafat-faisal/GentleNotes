import 'package:flutter/material.dart';

class MarkdownSyntaxController extends TextEditingController {
  bool wysiwygMode;
  String? activeCodeTheme;

  MarkdownSyntaxController({String? text, this.wysiwygMode = false, this.activeCodeTheme}) : super(text: text);

  @override
  set value(TextEditingValue newValue) {
    final oldText = value.text;
    final newText = newValue.text;

    if (newText.length == oldText.length + 1 && newText.length > oldText.length) {
      final cursor = newValue.selection.baseOffset;
      if (cursor > 0) {
        final insertedChar = newText[cursor - 1];

        // 1. Handle Enter (Auto-numbering & Outdenting)
        if (insertedChar == '\n') {
          final beforeEnter = newText.substring(0, cursor - 1);
          final lineStart = beforeEnter.lastIndexOf('\n') + 1;
          final lastLine = beforeEnter.substring(lineStart);

          final ulMatch = RegExp(r'^(\s*)([-*+])\s+(.*)$').firstMatch(lastLine);
          final olMatch = RegExp(r'^(\s*)(\d+)\.\s+(.*)$').firstMatch(lastLine);

          if (ulMatch != null) {
            if (ulMatch.group(3)!.trim().isEmpty) {
              // Empty unordered item
              final currentIndent = ulMatch.group(1)!;
              if (currentIndent.length >= 4) {
                // Outdent by 4 spaces
                final newIndent = currentIndent.substring(0, currentIndent.length - 4);
                final prefix = '$newIndent${ulMatch.group(2)} ';
                final modifiedText = newText.substring(0, lineStart) + prefix + newText.substring(cursor);
                super.value = newValue.copyWith(
                  text: modifiedText,
                  selection: TextSelection.collapsed(offset: lineStart + prefix.length),
                );
                return;
              } else {
                // Cancel to normal text
                final modifiedText = newText.substring(0, lineStart) + newText.substring(cursor);
                super.value = newValue.copyWith(
                  text: modifiedText,
                  selection: TextSelection.collapsed(offset: lineStart),
                );
                return;
              }
            } else {
              // Continue unordered list
              final prefix = '${ulMatch.group(1)}${ulMatch.group(2)} ';
              final modifiedText = newText.substring(0, cursor) + prefix + newText.substring(cursor);
              super.value = newValue.copyWith(
                text: modifiedText,
                selection: TextSelection.collapsed(offset: cursor + prefix.length),
              );
              return;
            }
          } else if (olMatch != null) {
            if (olMatch.group(3)!.trim().isEmpty) {
              // Empty ordered item
              final currentIndent = olMatch.group(1)!;
              if (currentIndent.length >= 4) {
                // Outdent by 4 spaces
                final newIndent = currentIndent.substring(0, currentIndent.length - 4);
                int nextNum = 1;
                final linesBefore = newText.substring(0, lineStart).split('\n');
                for (int i = linesBefore.length - 1; i >= 0; i--) {
                  final match = RegExp('^$newIndent(\\d+)\\.').firstMatch(linesBefore[i]);
                  if (match != null) {
                    nextNum = int.parse(match.group(1)!) + 1;
                    break;
                  }
                }
                final prefix = '$newIndent$nextNum. ';
                final modifiedText = newText.substring(0, lineStart) + prefix + newText.substring(cursor);
                super.value = newValue.copyWith(
                  text: modifiedText,
                  selection: TextSelection.collapsed(offset: lineStart + prefix.length),
                );
                return;
              } else {
                // Cancel to normal text
                final modifiedText = newText.substring(0, lineStart) + newText.substring(cursor);
                super.value = newValue.copyWith(
                  text: modifiedText,
                  selection: TextSelection.collapsed(offset: lineStart),
                );
                return;
              }
            } else {
              // Continue ordered list
              final nextNum = int.parse(olMatch.group(2)!) + 1;
              final prefix = '${olMatch.group(1)}$nextNum. ';
              final modifiedText = newText.substring(0, cursor) + prefix + newText.substring(cursor);
              super.value = newValue.copyWith(
                text: modifiedText,
                selection: TextSelection.collapsed(offset: cursor + prefix.length),
              );
              return;
            }
          }
        }

        // 2. Handle Tab or 4 spaces (Indenting a nested list)
        if (insertedChar == '\t' || insertedChar == ' ') {
          final beforeCursor = newText.substring(0, cursor);
          final lineStart = beforeCursor.lastIndexOf('\n') + 1;
          final currentLine = beforeCursor.substring(lineStart);

          bool shouldIndent = false;
          if (insertedChar == '\t') {
            final ulMatch = RegExp(r'^(\s*)([-*+])\s+\t$').firstMatch(currentLine);
            final olMatch = RegExp(r'^(\s*)(\d+)\.\s+\t$').firstMatch(currentLine);
            if (ulMatch != null || olMatch != null) shouldIndent = true;
          } else {
            final ulMatch = RegExp(r'^(\s*)([-*+])\s{4}$').firstMatch(currentLine);
            final olMatch = RegExp(r'^(\s*)(\d+)\.\s{4}$').firstMatch(currentLine);
            if (ulMatch != null || olMatch != null) shouldIndent = true;
          }

          if (shouldIndent) {
            final cleanLine = insertedChar == '\t'
                ? currentLine.substring(0, currentLine.length - 1)
                : currentLine.substring(0, currentLine.length - 3);
            final trimmedLine = cleanLine.trimRight();

            final ulMatch = RegExp(r'^(\s*)([-*+])').firstMatch(trimmedLine);
            final olMatch = RegExp(r'^(\s*)(\d+)\.').firstMatch(trimmedLine);

            String newIndent = '';
            String newBullet = '';
            if (ulMatch != null) {
              newIndent = ulMatch.group(1)! + '    ';
              newBullet = '${ulMatch.group(2)} ';
            } else if (olMatch != null) {
              newIndent = olMatch.group(1)! + '    ';
              newBullet = '1. ';
            }

            final prefix = newIndent + newBullet;
            final modifiedText = newText.substring(0, lineStart) + prefix + newText.substring(cursor);
            super.value = newValue.copyWith(
              text: modifiedText,
              selection: TextSelection.collapsed(offset: lineStart + prefix.length),
            );
            return;
          }
        }
      }
    }

    super.value = newValue;
  }

  // ── Ghost style: makes syntax characters invisible and zero-width ──────────
  TextStyle _ghost(TextStyle? base) => (base ?? const TextStyle()).copyWith(
        color: Colors.transparent,
        fontSize: 0.001,
        height: 0.001,
      );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (!wysiwygMode) {
      return TextSpan(style: style, text: text);
    }
    final spans = _buildAllSpans(text, style, context);
    return TextSpan(style: style, children: spans);
  }

  // ── Top-level: split by newline, process each line ─────────────────────────
  List<InlineSpan> _buildAllSpans(String source, TextStyle? base, BuildContext context) {
    final spans = <InlineSpan>[];
    final lines = source.split('\n');

    bool inCodeBlock = false;
    bool inMathBlock = false;
    
    // We use the custom active code theme or guess theme based on brightness
    final theme = activeCodeTheme ?? (Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light');
    final highlighter = GentleSyntaxHighlighter(context, theme);

    for (int i = 0; i < lines.length; i++) {
      if (i > 0) spans.add(TextSpan(text: '\n', style: base));
      
      final line = lines[i];
      final trimmed = line.trim();

      // Math block
      if (trimmed == '\$\$' || (trimmed.startsWith('\$\$') && trimmed.endsWith('\$\$') && trimmed.length > 2)) {
        if (!inMathBlock && trimmed.startsWith('\$\$') && trimmed.endsWith('\$\$') && trimmed.length > 4) {
          // single line math block
          spans.add(TextSpan(
            text: line,
            style: (base ?? const TextStyle()).copyWith(
              fontFamily: 'Courier', backgroundColor: const Color(0xFFFEF3C7), color: const Color(0xFFD97706),
            ),
          ));
          continue;
        }
        inMathBlock = !inMathBlock;
        spans.add(TextSpan(
          text: line,
          style: (base ?? const TextStyle()).copyWith(
            fontFamily: 'Courier', backgroundColor: const Color(0xFFFEF3C7), color: const Color(0xFFD97706),
          ),
        ));
        continue;
      }
      if (inMathBlock) {
        spans.add(TextSpan(
          text: line,
          style: (base ?? const TextStyle()).copyWith(
            fontFamily: 'Courier', backgroundColor: const Color(0xFFFEF3C7), color: const Color(0xFFB45309),
          ),
        ));
        continue;
      }

      // Code block
      if (trimmed.startsWith('```')) {
        inCodeBlock = !inCodeBlock;
        spans.add(TextSpan(
          text: line,
          style: (base ?? const TextStyle()).copyWith(
            fontFamily: 'Courier', backgroundColor: const Color(0xFFF3F4F6), color: const Color(0xFF7C3AED),
          ),
        ));
        continue;
      }
      if (inCodeBlock) {
        // Use GentleSyntaxHighlighter to format each line of the code block
        final codeSpans = highlighter.format(line).children;
        spans.add(TextSpan(
          style: (base ?? const TextStyle()).copyWith(
            backgroundColor: const Color(0xFFF3F4F6),
          ),
          children: codeSpans ?? [TextSpan(text: line)],
        ));
        continue;
      }

      spans.addAll(_processLine(line, base));
    }
    return spans;
  }

  // ── Block-level line processing ────────────────────────────────────────────
  List<InlineSpan> _processLine(String line, TextStyle? base) {
    // Divider --- → ghost the text (shows as empty visual line)
    if (RegExp(r'^-{3,}$|^\*{3,}$|^_{3,}$').hasMatch(line.trim())) {
      return [TextSpan(text: line, style: _ghost(base))];
    }

    // Headings  # H1 … ###### H6
    final headingMatch = RegExp(r'^(#{1,6}) (.+)$').firstMatch(line);
    if (headingMatch != null) {
      final level = headingMatch.group(1)!.length;
      final content = headingMatch.group(2)!;
      const fontSizes = [28.0, 22.0, 18.0, 16.0, 14.5, 13.0];
      final fs = fontSizes[level - 1];
      final prefix = '#' * level + ' ';
      final headStyle = (base ?? const TextStyle()).copyWith(
        fontSize: fs, fontWeight: FontWeight.bold, height: 1.5,
      );
      return [
        TextSpan(text: prefix, style: _ghost(base)),
        ..._processInline(content, headStyle),
      ];
    }

    // Blockquote  > text
    final bqMatch = RegExp(r'^((?:>\s*)+)(.*)$').firstMatch(line);
    if (bqMatch != null) {
      final prefix = bqMatch.group(1)!;
      final content = bqMatch.group(2)!;
      final qStyle = (base ?? const TextStyle()).copyWith(
        fontStyle: FontStyle.italic,
        color: (base?.color ?? const Color(0xFF555555)).withOpacity(0.65),
      );
      return [
        TextSpan(text: prefix, style: _ghost(base)),
        ..._processInline(content, qStyle),
      ];
    }

    // Checklist  - [ ] text  or  - [x] text
    final checkMatch = RegExp(r'^(\s*- \[)([ xX])\] (.*)$').firstMatch(line);
    if (checkMatch != null) {
      final syntaxPrefix = checkMatch.group(1)! + checkMatch.group(2)! + '] ';
      final checked = checkMatch.group(2)!.trim().isNotEmpty;
      final content = checkMatch.group(3)!;
      final checkStyle = (base ?? const TextStyle()).copyWith(
        decoration: checked ? TextDecoration.lineThrough : null,
        color: checked
            ? (base?.color ?? Colors.black).withOpacity(0.38)
            : base?.color,
      );
      return [
        TextSpan(text: syntaxPrefix, style: _ghost(base)),
        TextSpan(
          text: checked ? '☑ ' : '☐ ',
          style: (base ?? const TextStyle()).copyWith(
            color: checked ? const Color(0xFF7C3AED) : const Color(0xFF9CA3AF),
          ),
        ),
        ..._processInline(content, checkStyle),
      ];
    }

    // Bullet list  - item  * item  + item (with optional indent)
    final bulletMatch = RegExp(r'^(\s*)([-*+]) (.+)$').firstMatch(line);
    if (bulletMatch != null) {
      final rawIndent = bulletMatch.group(1)!;
      final content = bulletMatch.group(3)!;
      final level = rawIndent.length ~/ 4;
      const bullets = ['•', '◦', '▪'];
      final bulletChar = bullets[level.clamp(0, 2)];
      return [
        TextSpan(text: rawIndent + bulletMatch.group(2)! + ' ', style: _ghost(base)),
        TextSpan(
          text: rawIndent + '$bulletChar ',
          style: (base ?? const TextStyle()).copyWith(
            color: const Color(0xFF7C3AED), fontWeight: FontWeight.bold,
          ),
        ),
        ..._processInline(content, base),
      ];
    }

    // Ordered list  1. item (with optional indent)
    final olMatch = RegExp(r'^(\s*)(\d+)\. (.+)$').firstMatch(line);
    if (olMatch != null) {
      final rawIndent = olMatch.group(1)!;
      final num = olMatch.group(2)!;
      final content = olMatch.group(3)!;
      return [
        TextSpan(text: rawIndent + num + '. ', style: _ghost(base)),
        TextSpan(
          text: rawIndent + '$num. ',
          style: (base ?? const TextStyle()).copyWith(
            color: const Color(0xFF7C3AED), fontWeight: FontWeight.w600,
          ),
        ),
        ..._processInline(content, base),
      ];
    }

    // Default → process inline formatting on the whole line
    return _processInline(line, base);
  }

  // ── Inline formatting parser (recursive) ───────────────────────────────────
  List<InlineSpan> _processInline(String text, TextStyle? base) {
    if (text.isEmpty) return [TextSpan(text: '', style: base)];

    final spans = <InlineSpan>[];
    final regex = RegExp(
      r'(\*\*\*.*?\*\*\*'
      r'|\*\*.*?\*\*'
      r'|\*.*?\*'
      r'|~~.*?~~'
      r'|`.*?`'
      r'|<u>.*?</u>'
      r'|<mark[^>]*>.*?</mark>'
      r'|<span[^>]*>.*?</span>'
      r'|<div[^>]*>.*?</div>'
      r'|\[.*?\]\(.*?\)'
      r')',
      dotAll: false,
    );

    int lastIndex = 0;
    for (final m in regex.allMatches(text)) {
      if (m.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, m.start), style: base));
      }
      spans.addAll(_processToken(m.group(0)!, base));
      lastIndex = m.end;
    }
    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex), style: base));
    }
    return spans;
  }

  // ── Token-level inline rendering ──────────────────────────────────────────
  List<InlineSpan> _processToken(String tok, TextStyle? base) {
    final ghost = _ghost(base);

    // Bold + Italic  ***text***
    if (tok.startsWith('***') && tok.endsWith('***') && tok.length > 6) {
      final inner = tok.substring(3, tok.length - 3);
      return [
        TextSpan(text: '***', style: ghost),
        ..._processInline(inner, (base ?? const TextStyle()).copyWith(
            fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
        TextSpan(text: '***', style: ghost),
      ];
    }

    // Bold  **text**
    if (tok.startsWith('**') && tok.endsWith('**') && tok.length > 4) {
      final inner = tok.substring(2, tok.length - 2);
      return [
        TextSpan(text: '**', style: ghost),
        ..._processInline(
            inner, (base ?? const TextStyle()).copyWith(fontWeight: FontWeight.bold)),
        TextSpan(text: '**', style: ghost),
      ];
    }

    // Italic  *text*
    if (tok.startsWith('*') && tok.endsWith('*') && tok.length > 2) {
      final inner = tok.substring(1, tok.length - 1);
      return [
        TextSpan(text: '*', style: ghost),
        ..._processInline(
            inner, (base ?? const TextStyle()).copyWith(fontStyle: FontStyle.italic)),
        TextSpan(text: '*', style: ghost),
      ];
    }

    // Strikethrough  ~~text~~
    if (tok.startsWith('~~') && tok.endsWith('~~') && tok.length > 4) {
      final inner = tok.substring(2, tok.length - 2);
      return [
        TextSpan(text: '~~', style: ghost),
        ..._processInline(inner, (base ?? const TextStyle()).copyWith(
            decoration: TextDecoration.lineThrough)),
        TextSpan(text: '~~', style: ghost),
      ];
    }

    // Inline code  `code`
    if (tok.startsWith('`') && tok.endsWith('`') && tok.length > 2) {
      final inner = tok.substring(1, tok.length - 1);
      return [
        TextSpan(text: '`', style: ghost),
        TextSpan(
          text: inner,
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: (base?.fontSize ?? 16) * 0.9,
            backgroundColor: const Color(0xFFEDE9FE),
            color: const Color(0xFF7C3AED),
          ),
        ),
        TextSpan(text: '`', style: ghost),
      ];
    }

    // Underline  <u>text</u>
    if (tok.startsWith('<u>') && tok.endsWith('</u>')) {
      final inner = tok.substring(3, tok.length - 4);
      return [
        TextSpan(text: '<u>', style: ghost),
        ..._processInline(inner, (base ?? const TextStyle()).copyWith(
            decoration: TextDecoration.underline)),
        TextSpan(text: '</u>', style: ghost),
      ];
    }

    // Highlight  <mark style="background:#HEX">text</mark>
    if (tok.startsWith('<mark')) {
      final bgMatch = RegExp(r'background[:\s]*([#\w]+)').firstMatch(tok);
      final innerMatch =
          RegExp(r'<mark[^>]*>(.*?)</mark>', dotAll: true).firstMatch(tok);
      final openTag = tok.substring(0, tok.indexOf('>') + 1);
      final inner = innerMatch?.group(1) ?? '';
      Color bgColor = const Color(0xFFFFFF00);
      if (bgMatch != null) {
        final hex = bgMatch.group(1)!.replaceAll('#', '');
        if (hex.length == 6) bgColor = Color(int.parse('FF$hex', radix: 16));
      }
      return [
        TextSpan(text: openTag, style: ghost),
        ..._processInline(
            inner, (base ?? const TextStyle()).copyWith(backgroundColor: bgColor)),
        TextSpan(text: '</mark>', style: ghost),
      ];
    }

    // Text color  <span style="color:#HEX">text</span>
    if (tok.startsWith('<span')) {
      final colorMatch = RegExp(r'color[:\s]*([#\w]+)').firstMatch(tok);
      final innerMatch =
          RegExp(r'<span[^>]*>(.*?)</span>', dotAll: true).firstMatch(tok);
      final openTag = tok.substring(0, tok.indexOf('>') + 1);
      final inner = innerMatch?.group(1) ?? '';
      Color textColor = base?.color ?? const Color(0xFF1A1A2E);
      if (colorMatch != null) {
        final hex = colorMatch.group(1)!.replaceAll('#', '');
        if (hex.length == 6) textColor = Color(int.parse('FF$hex', radix: 16));
      }
      return [
        TextSpan(text: openTag, style: ghost),
        ..._processInline(
            inner, (base ?? const TextStyle()).copyWith(color: textColor)),
        TextSpan(text: '</span>', style: ghost),
      ];
    }

    // Alignment  <div align="center">text</div>
    if (tok.startsWith('<div')) {
      final innerMatch =
          RegExp(r'<div[^>]*>(.*?)</div>', dotAll: true).firstMatch(tok);
      final openTag = tok.substring(0, tok.indexOf('>') + 1);
      final inner = innerMatch?.group(1) ?? tok;
      return [
        TextSpan(text: openTag, style: ghost),
        ..._processInline(inner, base),
        TextSpan(text: '</div>', style: ghost),
      ];
    }

    // Link  [label](url)
    if (tok.startsWith('[') && tok.contains('](')) {
      final label = tok.substring(1, tok.indexOf(']'));
      final urlPart = tok.substring(tok.indexOf('](') + 2, tok.length - 1);
      return [
        TextSpan(text: '[', style: ghost),
        TextSpan(
          text: label,
          style: (base ?? const TextStyle()).copyWith(
            color: const Color(0xFF2563EB),
            decoration: TextDecoration.underline,
          ),
        ),
        TextSpan(text: ']($urlPart)', style: ghost),
      ];
    }

    // Fallback
    return [TextSpan(text: tok, style: base)];
  }
}

class GentleSyntaxHighlighter {
  final BuildContext context;
  final String theme;

  GentleSyntaxHighlighter(this.context, this.theme);

  TextSpan format(String code) {
    final List<TextSpan> spans = [];
    final lines = code.split('\n');
    final isDark = theme.contains('dark') || theme == 'monokai';

    final keywordStyle = TextStyle(color: isDark ? const Color(0xFFF97316) : const Color(0xFFC2410C), fontWeight: FontWeight.bold);
    final stringStyle = TextStyle(color: isDark ? const Color(0xFF10B981) : const Color(0xFF047857));
    final commentStyle = TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B), fontStyle: FontStyle.italic);
    final numberStyle = TextStyle(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1));
    final defaultStyle = TextStyle(color: isDark ? Colors.white : Colors.black87);

    final keywords = {
      'class', 'struct', 'enum', 'void', 'int', 'double', 'float', 'bool', 'string', 'final', 'const',
      'var', 'let', 'function', 'def', 'import', 'from', 'as', 'return', 'if', 'else', 'for', 'while',
      'switch', 'case', 'break', 'continue', 'true', 'false', 'null', 'import', 'package', 'public',
      'private', 'protected', 'extends', 'implements', 'override', 'async', 'await', 'yield'
    };

    final keywordRegex = RegExp('\\b(${keywords.join('|')})\\b');
    final stringRegex = RegExp(r"'(.*?)'|&quot;(.*?)&quot;|\u0022(.*?)\u0022");
    final numberRegex = RegExp(r'\b\d+(\.\d+)?\b');
    final commentRegex = RegExp(r'//.*|#.*|/\*[\s\S]*?\*/');

    final combinedRegex = RegExp(
      '(${commentRegex.pattern})|(${stringRegex.pattern})|(${keywordRegex.pattern})|(${numberRegex.pattern})',
      multiLine: true,
    );

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      int lastIndex = 0;

      for (final match in combinedRegex.allMatches(line)) {
        if (match.start > lastIndex) {
          spans.add(TextSpan(text: line.substring(lastIndex, match.start), style: defaultStyle));
        }

        final matchedText = match.group(0)!;
        if (match.group(1) != null) {
          spans.add(TextSpan(text: matchedText, style: commentStyle));
        } else if (match.group(2) != null) {
          spans.add(TextSpan(text: matchedText, style: stringStyle));
        } else if (match.group(5) != null) {
          spans.add(TextSpan(text: matchedText, style: keywordStyle));
        } else {
          if (keywords.contains(matchedText)) {
            spans.add(TextSpan(text: matchedText, style: keywordStyle));
          } else if (double.tryParse(matchedText) != null) {
            spans.add(TextSpan(text: matchedText, style: numberStyle));
          } else {
            spans.add(TextSpan(text: matchedText, style: defaultStyle));
          }
        }
        lastIndex = match.end;
      }

      if (lastIndex < line.length) {
        spans.add(TextSpan(text: line.substring(lastIndex), style: defaultStyle));
      }

      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return TextSpan(children: spans, style: const TextStyle(fontFamily: 'Courier', fontSize: 13));
  }
}
