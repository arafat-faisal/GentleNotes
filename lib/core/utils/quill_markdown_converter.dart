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
    final preProcessed = preProcessMarkdownCodeBlocks(markdown);
    if (preProcessed.isEmpty) {
      return [
        {'insert': '\n'}
      ];
    }
    
    final ops = <Map<String, dynamic>>[];
    final lines = preProcessed.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    
    bool inCodeBlock = false;
    String codeBlockLang = '';
    final codeBlockLines = <String>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // 1. Code Block Toggle
      if (line.trim().startsWith('```')) {
        if (inCodeBlock) {
          for (final blockLine in codeBlockLines) {
            ops.add({'insert': blockLine});
            ops.add({
              'insert': '\n',
              'attributes': {'code-block': codeBlockLang.isNotEmpty ? codeBlockLang : true}
            });
          }
          codeBlockLines.clear();
          inCodeBlock = false;
          codeBlockLang = '';
        } else {
          inCodeBlock = true;
          codeBlockLang = line.trim().substring(3).trim();
        }
        continue;
      }
      
      if (inCodeBlock) {
        codeBlockLines.add(line);
        continue;
      }
      
      // Check for horizontal rule: *** or --- or ___
      final isHr = RegExp(r'^\s*(\*|-|_)\s*\1\s*\1\s*(\1|\s)*$').hasMatch(line);
      if (isHr) {
        ops.add({
          'insert': {'horizontal-rule': ''}
        });
        ops.add({'insert': '\n'});
        continue;
      }
      
      // 2. Process non-code line block types
      String processedLine = line.trimLeft();
      final blockAttrs = <String, dynamic>{};
      
      // Alignment Tag Check: <div align="center">...</div>
      final alignMatch = RegExp(r'^<div\s+align="([^"]*)">(.*)</div>$').firstMatch(processedLine.trim());
      if (alignMatch != null) {
        blockAttrs['align'] = alignMatch.group(1);
        processedLine = alignMatch.group(2)!;
      }
      
      // Check block-level formatting
      final headerMatch = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(processedLine);
      final checklistCheckedMatch = RegExp(r'^([-\*+]\s*\[[xX]\]\s*)(.*)$').firstMatch(processedLine);
      final checklistUncheckedMatch = RegExp(r'^([-\*+]\s*\[\s*\]\s*)(.*)$').firstMatch(processedLine);
      final bulletMatch = RegExp(r'^([-\*+]\s+)(.*)$').firstMatch(processedLine);
      final orderedMatch = RegExp(r'^(\d+\.\s+)(.*)$').firstMatch(processedLine);
      final blockquoteMatch = RegExp(r'^(\>\s*)(.*)$').firstMatch(processedLine);
      
      if (headerMatch != null) {
        int level = headerMatch.group(1)!.length;
        if (level > 3) level = 3;
        blockAttrs['header'] = level;
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
      if (leadingSpaces > 0) {
        final indentLevel = (leadingSpaces / 2).floor();
        if (indentLevel > 0) {
          blockAttrs['indent'] = indentLevel;
        }
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
      for (final blockLine in codeBlockLines) {
        ops.add({'insert': blockLine});
        ops.add({
          'insert': '\n',
          'attributes': {'code-block': codeBlockLang.isNotEmpty ? codeBlockLang : true}
        });
      }
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
      r'(<https?://[^>]+>'
      r'|\*\*\*.*?\*\*\* '
      r'|\*\*.*?\*\*'
      r'|\*.*?\*'
      r'|~~.*?~~'
      r'|`.*?`'
      r'|<u>.*?</u>'
      r'|<mark style="background:([^"]*)">(.*?)</mark>'
      r'|<span style="([^"]*)">(.*?)</span>'
      r'|!\[(.*?)\]\((.*?)\)'
      r'|\[(.*?)\]\((.*?)\)'
      r'|https?://[^\s<>]+'
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
      
      if (token.startsWith('<http') && token.endsWith('>')) {
        final url = token.substring(1, token.length - 1);
        ops.add({
          'insert': url,
          'attributes': {'link': url},
        });
      } else if (token.startsWith('http://') || token.startsWith('https://')) {
        ops.add({
          'insert': token,
          'attributes': {'link': token},
        });
      } else if (token.startsWith('***') && token.endsWith('***') && token.length >= 6) {
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
        final styleStr = match.group(4) ?? '';
        final inner = match.group(5) ?? '';
        
        final colorMatch = RegExp(r'color[:\s]*([^;"]+)').firstMatch(styleStr);
        final fontMatch = RegExp(r'font-family[:\s]*([^;"]+)').firstMatch(styleStr);
        final sizeMatch = RegExp(r'font-size[:\s]*([^;"]+)').firstMatch(styleStr);
        
        final innerOps = _parseInlineMarkdown(inner);
        for (final op in innerOps) {
          final attrs = Map<String, dynamic>.from(op['attributes'] ?? {});
          if (colorMatch != null) {
            attrs['color'] = colorMatch.group(1)!.trim();
          }
          if (fontMatch != null) {
            attrs['font'] = fontMatch.group(1)!.trim();
          }
          if (sizeMatch != null) {
            final sizeVal = sizeMatch.group(1)!.trim().replaceAll('px', '');
            final d = double.tryParse(sizeVal);
            attrs['size'] = d ?? sizeVal;
          }
          op['attributes'] = attrs;
        }
        ops.addAll(innerOps);
      } else if (token.startsWith('!') && token.contains('](')) {
        final url = match.group(7) ?? '';
        if (url.startsWith('sticker://')) {
          final stickerName = url.replaceFirst('sticker://', '');
          ops.add({
            'insert': {'sticker': stickerName},
          });
        } else {
          ops.add({
            'insert': {'image': url},
          });
        }
      } else if (token.startsWith('[') && token.contains('](')) {
        final label = match.group(8) ?? '';
        final url = match.group(9) ?? '';
        if (url.startsWith('audio://')) {
          final attachmentId = url.replaceFirst('audio://', '');
          String width = 'full';
          if (label.startsWith('audio:')) {
            width = label.substring('audio:'.length);
          }
          final dataMap = {
            'id': attachmentId,
            'width': width,
          };
          ops.add({
            'insert': {'audio': jsonEncode(dataMap)},
          });
        } else {
          ops.add({
            'insert': label,
            'attributes': {'link': url},
          });
        }
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
      
      bool inCodeBlock = false;
      String currentCodeBlockLang = '';
      final codeBlockLines = <String>[];
      
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
              
              final blockAttrs = attributes;
              final codeBlockAttr = blockAttrs?['code-block'];
              
              if (codeBlockAttr != null) {
                if (!inCodeBlock) {
                  inCodeBlock = true;
                  currentCodeBlockLang = codeBlockAttr is String ? codeBlockAttr : '';
                }
                final lineText = _processCodeLine(currentLineOps);
                codeBlockLines.add(lineText);
              } else {
                if (inCodeBlock) {
                  buffer.write('```$currentCodeBlockLang\n');
                  buffer.write(codeBlockLines.join('\n'));
                  buffer.write('\n```\n');
                  codeBlockLines.clear();
                  inCodeBlock = false;
                  currentCodeBlockLang = '';
                }
                
                buffer.write(_processLine(currentLineOps, blockAttrs));
              }
              
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
      
      if (inCodeBlock) {
        buffer.write('```$currentCodeBlockLang\n');
        buffer.write(codeBlockLines.join('\n'));
        buffer.write('\n```\n');
      } else if (currentLineOps.isNotEmpty) {
        buffer.write(_processLine(currentLineOps, null));
      }
      
      return buffer.toString().trimRight() + '\n';
    } catch (e) {
      return deltaJsonStr;
    }
  }

  static String _processCodeLine(List<Map<String, dynamic>> lineOps) {
    final buf = StringBuffer();
    for (final op in lineOps) {
      final insert = op['insert'];
      if (insert is String) {
        buf.write(insert);
      }
    }
    return buf.toString();
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
          if (attrs['color'] is String || attrs['font'] is String || attrs['size'] != null) {
            final spanStyles = <String>[];
            if (attrs['color'] is String) {
              spanStyles.add('color:${attrs['color']}');
            }
            if (attrs['font'] is String) {
              spanStyles.add('font-family:${attrs['font']}');
            }
            if (attrs['size'] != null) {
              final sizeVal = attrs['size'];
              final sizeStr = sizeVal is double ? '${sizeVal.toInt()}px' : (sizeVal is int ? '${sizeVal}px' : '$sizeVal');
              spanStyles.add('font-size:$sizeStr');
            }
            text = '<span style="${spanStyles.join(';')}">$text</span>';
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
        } else if (insert.containsKey('sticker')) {
          final stickerName = insert['sticker'];
          lineBuffer.write('![sticker:$stickerName](sticker://$stickerName)');
        } else if (insert.containsKey('audio')) {
          final audioData = insert['audio'];
          String attachmentId = '';
          String width = 'full';
          try {
            final parsed = jsonDecode(audioData) as Map<String, dynamic>;
            attachmentId = parsed['id'] as String? ?? '';
            width = parsed['width'] as String? ?? 'full';
          } catch (_) {
            attachmentId = audioData;
          }
          lineBuffer.write('[audio:$width](audio://$attachmentId)');
        } else if (insert.containsKey('horizontal-rule') || insert.containsKey('divider')) {
          lineBuffer.write('***');
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

      if (codeBlock == true || codeBlock is String) {
        final lang = codeBlock is String ? codeBlock : '';
        return '$indentPrefix```$lang\n$lineText\n```\n';
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

  /// Pre-processes a text to wrap code block language headings (e.g. "🐍 Python") and their code lines in Markdown code block backticks.
  static String preProcessMarkdownCodeBlocks(String text) {
    final lines = text.split('\n');
    final newLines = <String>[];
    bool inDetectedCodeBlock = false;
    bool inStandardCodeBlock = false;

    bool isLanguageHeader(String line, List<String> outLang) {
      if (inStandardCodeBlock) return false;
      final trimmed = line.trim().toLowerCase();
      if (trimmed.isEmpty) return false;
      
      // Strip typical prefix emojis/symbols and trailing symbols
      final cleanWord = trimmed
          .replaceAll(RegExp(r'^[^a-z0-9+#-]+'), '')
          .replaceAll(RegExp(r'[^a-z0-9+#-]+$'), '')
          .trim();
      
      const languages = {
        'python': 'python',
        'javascript': 'javascript',
        'typescript': 'typescript',
        'c++': 'cpp',
        'cpp': 'cpp',
        'sql': 'sql',
        'json': 'json',
        'yaml': 'yaml',
        'html': 'html',
        'css': 'css',
        'dart': 'dart',
        'java': 'java',
        'go': 'go',
        'rust': 'rust',
        'shell': 'shell',
        'bash': 'shell',
      };
      
      if (languages.containsKey(cleanWord)) {
        outLang.add(languages[cleanWord]!);
        return true;
      }
      return false;
    }

    bool isBlockDelimiter(String line) {
      if (inStandardCodeBlock) return false;
      final trimmed = line.trim();
      
      // If we encounter a standard code block opening while in a detected one, close the detected one
      if (trimmed.startsWith('```')) {
        return true;
      }
      
      if (trimmed.startsWith('#') ||
          trimmed.startsWith('***') ||
          trimmed.startsWith('---') ||
          trimmed.startsWith('___') ||
          trimmed.startsWith('- [ ') ||
          trimmed.startsWith('- [x') ||
          trimmed.startsWith('* ') ||
          trimmed.startsWith('- ') ||
          RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
        return true;
      }
      return false;
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();
      
      if (trimmed.startsWith('```')) {
        if (inDetectedCodeBlock) {
          while (newLines.isNotEmpty && newLines.last.trim().isEmpty) {
            newLines.removeLast();
          }
          newLines.add('```');
          inDetectedCodeBlock = false;
        }
        inStandardCodeBlock = !inStandardCodeBlock;
        newLines.add(line);
        continue;
      }

      final outLang = <String>[];
      if (isLanguageHeader(line, outLang)) {
        if (inDetectedCodeBlock) {
          while (newLines.isNotEmpty && newLines.last.trim().isEmpty) {
            newLines.removeLast();
          }
          newLines.add('```');
          inDetectedCodeBlock = false;
        }
        newLines.add('```${outLang.first}');
        inDetectedCodeBlock = true;
        // Skip subsequent empty lines
        while (i + 1 < lines.length && lines[i + 1].trim().isEmpty) {
          i++;
        }
      } else {
        if (inDetectedCodeBlock && isBlockDelimiter(line)) {
          while (newLines.isNotEmpty && newLines.last.trim().isEmpty) {
            newLines.removeLast();
          }
          newLines.add('```');
          inDetectedCodeBlock = false;
        }
        newLines.add(line);
      }
    }

    if (inDetectedCodeBlock) {
      while (newLines.isNotEmpty && newLines.last.trim().isEmpty) {
        newLines.removeLast();
      }
      newLines.add('```');
    }

    return newLines.join('\n');
  }
}
