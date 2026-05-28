import 'dart:convert';

/// Bidirectional translator between Markdown syntax and Quill Delta JSON structure.
///
/// Implemented entirely using core Dart classes (jsonDecode/jsonEncode) to remain
/// highly performant and resilient to version changes of the flutter_quill package.
class QuillMarkdownConverter {
  
  /// Converts a standard Markdown string to a Quill Delta JSON string.
  static String markdownToDeltaJson(String markdown) {
    final ops = markdownToDeltaOps(markdown);
    return jsonEncode(ops);
  }

  /// Converts a standard Markdown string to a list of Quill Delta operations.
  static List<Map<String, dynamic>> markdownToDeltaOps(String markdown) {
    if (markdown.isEmpty) {
      return [
        {'insert': '\n'}
      ];
    }
    
    final ops = <Map<String, dynamic>>[];
    final lines = markdown.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    
    bool inCodeBlock = false;
    final codeBlockLines = <String>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // 1. Code Block Toggle
      if (line.trim().startsWith('```')) {
        if (inCodeBlock) {
          final codeText = codeBlockLines.join('\n');
          ops.add({'insert': codeText});
          ops.add({
            'insert': '\n',
            'attributes': {'code-block': true}
          });
          codeBlockLines.clear();
          inCodeBlock = false;
        } else {
          inCodeBlock = true;
        }
        continue;
      }
      
      if (inCodeBlock) {
        codeBlockLines.add(line);
        continue;
      }
      
      // 2. Process non-code line block types
      String processedLine = line;
      final blockAttrs = <String, dynamic>{};
      
      // Alignment Tag Check: <div align="center">...</div>
      final alignMatch = RegExp(r'^<div\s+align="([^"]*)">(.*)</div>$').firstMatch(processedLine.trim());
      if (alignMatch != null) {
        blockAttrs['align'] = alignMatch.group(1);
        processedLine = alignMatch.group(2)!;
      }
      
      // Check block-level formatting
      final headerMatch = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(processedLine);
      final checklistCheckedMatch = RegExp(r'^(-\s*\[[xX]\]\s*)(.*)$').firstMatch(processedLine);
      final checklistUncheckedMatch = RegExp(r'^(-\s*\[\s\]\s*)(.*)$').firstMatch(processedLine);
      final bulletMatch = RegExp(r'^([-\*+]\s+)(.*)$').firstMatch(processedLine);
      final orderedMatch = RegExp(r'^(\d+\.\s+)(.*)$').firstMatch(processedLine);
      final blockquoteMatch = RegExp(r'^(\>\s*)(.*)$').firstMatch(processedLine);
      
      if (headerMatch != null) {
        blockAttrs['header'] = headerMatch.group(1)!.length;
        processedLine = headerMatch.group(2)!;
      } else if (checklistCheckedMatch != null) {
        blockAttrs['list'] = 'checked';
        processedLine = checklistCheckedMatch.group(2)!;
      } else if (checklistUncheckedMatch != null) {
        blockAttrs['list'] = 'unchecked';
        processedLine = checklistUncheckedMatch.group(2)!;
      } else if (bulletMatch != null) {
        blockAttrs['list'] = 'bullet';
        processedLine = bulletMatch.group(2)!;
      } else if (orderedMatch != null) {
        blockAttrs['list'] = 'ordered';
        processedLine = orderedMatch.group(2)!;
      } else if (blockquoteMatch != null) {
        blockAttrs['blockquote'] = true;
        processedLine = blockquoteMatch.group(2)!;
      }
      
      // Check indent level (based on leading spaces)
      final leadingSpaces = line.length - line.trimLeft().length;
      if (leadingSpaces >= 4) {
        blockAttrs['indent'] = leadingSpaces ~/ 4;
      }

      // Parse inline markers in processedLine
      final inlineOps = _parseInlineMarkdown(processedLine);
      ops.addAll(inlineOps);
      
      // Append newline operation terminating this block
      if (blockAttrs.isNotEmpty) {
        ops.add({
          'insert': '\n',
          'attributes': blockAttrs,
        });
      } else {
        ops.add({'insert': '\n'});
      }
    }
    
    // Close open code block if necessary
    if (inCodeBlock && codeBlockLines.isNotEmpty) {
      ops.add({'insert': codeBlockLines.join('\n')});
      ops.add({
        'insert': '\n',
        'attributes': {'code-block': true}
      });
    }
    
    // Quill requires document to end with a single newline if not already present
    if (ops.isEmpty || ops.last['insert'] != '\n') {
      ops.add({'insert': '\n'});
    }
    
    return ops;
  }

  /// Parses a snippet of inline markdown into Delta operations.
  static List<Map<String, dynamic>> _parseInlineMarkdown(String text) {
    if (text.isEmpty) return [];
    
    final ops = <Map<String, dynamic>>[];
    final regex = RegExp(
      r'(\*\*\*.*?\*\*\*'
      r'|\*\*.*?\*\*'
      r'|\*.*?\*'
      r'|~~.*?~~'
      r'|`.*?`'
      r'|<u>.*?</u>'
      r'|<mark style="background:([^"]*)">(.*?)</mark>'
      r'|<span style="color:([^"]*)">(.*?)</span>'
      r'|!\[(.*?)\]\((.*?)\)'
      r'|\[(.*?)\]\((.*?)\)'
      r')',
      dotAll: true,
    );

    int lastIndex = 0;
    
    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        ops.add({
          'insert': text.substring(lastIndex, match.start),
        });
      }
      
      final token = match.group(0)!;
      
      if (token.startsWith('***') && token.endsWith('***') && token.length >= 6) {
        final inner = token.substring(3, token.length - 3);
        final innerOps = _parseInlineMarkdown(inner);
        for (final op in innerOps) {
          final attrs = Map<String, dynamic>.from(op['attributes'] ?? {});
          attrs['bold'] = true;
          attrs['italic'] = true;
          op['attributes'] = attrs;
        }
        ops.addAll(innerOps);
      } else if (token.startsWith('**') && token.endsWith('**') && token.length >= 4) {
        final inner = token.substring(2, token.length - 2);
        final innerOps = _parseInlineMarkdown(inner);
        for (final op in innerOps) {
          final attrs = Map<String, dynamic>.from(op['attributes'] ?? {});
          attrs['bold'] = true;
          op['attributes'] = attrs;
        }
        ops.addAll(innerOps);
      } else if (token.startsWith('*') && token.endsWith('*') && token.length >= 2) {
        final inner = token.substring(1, token.length - 1);
        final innerOps = _parseInlineMarkdown(inner);
        for (final op in innerOps) {
          final attrs = Map<String, dynamic>.from(op['attributes'] ?? {});
          attrs['italic'] = true;
          op['attributes'] = attrs;
        }
        ops.addAll(innerOps);
      } else if (token.startsWith('~~') && token.endsWith('~~') && token.length >= 4) {
        final inner = token.substring(2, token.length - 2);
        final innerOps = _parseInlineMarkdown(inner);
        for (final op in innerOps) {
          final attrs = Map<String, dynamic>.from(op['attributes'] ?? {});
          attrs['strike'] = true;
          op['attributes'] = attrs;
        }
        ops.addAll(innerOps);
      } else if (token.startsWith('`') && token.endsWith('`') && token.length >= 2) {
        final inner = token.substring(1, token.length - 1);
        ops.add({
          'insert': inner,
          'attributes': {'code': true},
        });
      } else if (token.startsWith('<u>') && token.endsWith('</u>') && token.length >= 7) {
        final inner = token.substring(3, token.length - 4);
        final innerOps = _parseInlineMarkdown(inner);
        for (final op in innerOps) {
          final attrs = Map<String, dynamic>.from(op['attributes'] ?? {});
          attrs['underline'] = true;
          op['attributes'] = attrs;
        }
        ops.addAll(innerOps);
      } else if (token.startsWith('<mark') && token.endsWith('</mark>')) {
        final bg = match.group(2) ?? '';
        final inner = match.group(3) ?? '';
        final innerOps = _parseInlineMarkdown(inner);
        for (final op in innerOps) {
          final attrs = Map<String, dynamic>.from(op['attributes'] ?? {});
          attrs['background'] = bg;
          op['attributes'] = attrs;
        }
        ops.addAll(innerOps);
      } else if (token.startsWith('<span') && token.endsWith('</span>')) {
        final color = match.group(4) ?? '';
        final inner = match.group(5) ?? '';
        final innerOps = _parseInlineMarkdown(inner);
        for (final op in innerOps) {
          final attrs = Map<String, dynamic>.from(op['attributes'] ?? {});
          attrs['color'] = color;
          op['attributes'] = attrs;
        }
        ops.addAll(innerOps);
      } else if (token.startsWith('!') && token.contains('](')) {
        final url = match.group(7) ?? '';
        ops.add({
          'insert': {'image': url},
        });
      } else if (token.startsWith('[') && token.contains('](')) {
        final label = match.group(8) ?? '';
        final url = match.group(9) ?? '';
        ops.add({
          'insert': label,
          'attributes': {'link': url},
        });
      } else {
        ops.add({'insert': token});
      }
      
      lastIndex = match.end;
    }
    
    if (lastIndex < text.length) {
      ops.add({
        'insert': text.substring(lastIndex),
      });
    }
    
    return ops;
  }

  /// Converts a Quill Delta JSON string back to Markdown formatting.
  static String deltaToMarkdown(String deltaJsonStr) {
    if (deltaJsonStr.isEmpty) return '';
    if (!deltaJsonStr.startsWith('[') || !deltaJsonStr.endsWith(']')) {
      // It's likely raw text / Markdown already
      return deltaJsonStr;
    }
    try {
      final List ops = jsonDecode(deltaJsonStr);
      final buffer = StringBuffer();
      
      List<Map<String, dynamic>> currentLineOps = [];
      
      for (final op in ops) {
        if (op is! Map) continue;
        final insert = op['insert'];
        final attributes = op['attributes'] as Map<String, dynamic>?;
        
        if (insert is String) {
          int start = 0;
          while (start < insert.length) {
            final newlineIndex = insert.indexOf('\n', start);
            if (newlineIndex == -1) {
              currentLineOps.add({
                'insert': insert.substring(start),
                'attributes': attributes,
              });
              break;
            } else {
              if (newlineIndex > start) {
                currentLineOps.add({
                  'insert': insert.substring(start, newlineIndex),
                  'attributes': attributes,
                });
              }
              
              buffer.write(_processLine(currentLineOps, attributes));
              currentLineOps = [];
              start = newlineIndex + 1;
            }
          }
        } else if (insert is Map) {
          currentLineOps.add({
            'insert': insert,
            'attributes': attributes,
          });
        }
      }
      
      if (currentLineOps.isNotEmpty) {
        buffer.write(_processLine(currentLineOps, null));
      }
      
      return buffer.toString().trimRight() + '\n';
    } catch (e) {
      return deltaJsonStr;
    }
  }

  static String _processLine(List<Map<String, dynamic>> lineOps, Map<String, dynamic>? blockAttrs) {
    final lineBuffer = StringBuffer();
    
    for (final op in lineOps) {
      final insert = op['insert'];
      final attrs = op['attributes'] as Map<String, dynamic>?;
      
      if (insert is String) {
        String text = insert;
        if (attrs != null) {
          if (attrs['bold'] == true && attrs['italic'] == true) {
            text = '***$text***';
          } else if (attrs['bold'] == true) {
            text = '**$text**';
          } else if (attrs['italic'] == true) {
            text = '*$text*';
          }
          if (attrs['underline'] == true) {
            text = '<u>$text</u>';
          }
          if (attrs['strike'] == true) {
            text = '~~$text~~';
          }
          if (attrs['code'] == true) {
            text = '`$text`';
          }
          if (attrs['link'] is String) {
            text = '[$text](${attrs['link']})';
          }
          if (attrs['color'] is String) {
            text = '<span style="color:${attrs['color']}">$text</span>';
          }
          if (attrs['background'] is String) {
            text = '<mark style="background:${attrs['background']}">$text</mark>';
          }
        }
        lineBuffer.write(text);
      } else if (insert is Map) {
        if (insert.containsKey('image')) {
          final imageUrl = insert['image'];
          lineBuffer.write('![$imageUrl]($imageUrl)');
        }
      }
    }
    
    String lineText = lineBuffer.toString();
    
    if (blockAttrs != null) {
      final header = blockAttrs['header'];
      final list = blockAttrs['list'];
      final blockquote = blockAttrs['blockquote'];
      final codeBlock = blockAttrs['code-block'];
      final align = blockAttrs['align'];
      final indent = blockAttrs['indent'];
      
      String indentPrefix = '';
      if (indent is int && indent > 0) {
        indentPrefix = '    ' * indent;
      }

      if (codeBlock == true) {
        return '$indentPrefix```\n$lineText\n```\n';
      }
      
      if (blockquote == true) {
        lineText = '$indentPrefix> $lineText';
      } else if (header is int) {
        lineText = '$indentPrefix${"#" * header} $lineText';
      } else if (list == 'bullet') {
        lineText = '$indentPrefix- $lineText';
      } else if (list == 'ordered') {
        lineText = '${indentPrefix}1. $lineText';
      } else if (list == 'checked') {
        lineText = '$indentPrefix- [x] $lineText';
      } else if (list == 'unchecked') {
        lineText = '$indentPrefix- [ ] $lineText';
      } else if (indentPrefix.isNotEmpty) {
        lineText = indentPrefix + lineText;
      }
      
      if (align is String) {
        lineText = '<div align="$align">$lineText</div>';
      }
    }
    
    return '$lineText\n';
  }
}
