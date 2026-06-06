import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../settings/presentation/controllers/settings_controller.dart';
import '../../../../../core/utils/logger.dart';
import '../../../domain/entities/block_entity.dart';
import '../markdown/markdown_code_block.dart';

/// Supported languages in the block editor dropdown picker
const List<String> _supportedLanguages = [
  'python',
  'javascript',
  'typescript',
  'cpp',
  'sql',
  'json',
  'yaml',
  'html',
  'css',
  'dart',
  'java',
  'go',
  'rust',
  'shell',
];

/// A custom TextEditingController that leverages [GentleSyntaxHighlighter] to highlight
/// keywords, strings, comments, and numbers in real-time as the user types.
class HighlightingTextController extends TextEditingController {
  final BuildContext context;
  String _activeCodeTheme;
  String _language;

  HighlightingTextController({
    super.text,
    required this.context,
    required String activeCodeTheme,
    required String language,
  })  : _activeCodeTheme = activeCodeTheme,
        _language = language;

  String get activeCodeTheme => _activeCodeTheme;
  set activeCodeTheme(String value) {
    if (_activeCodeTheme != value) {
      _activeCodeTheme = value;
      notifyListeners();
    }
  }

  String get language => _language;
  set language(String value) {
    if (_language != value) {
      _language = value;
      notifyListeners();
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final highlighter = GentleSyntaxHighlighter(context, _activeCodeTheme);
    return highlighter.format(text, _language);
  }
}

class CodeBlock extends ConsumerStatefulWidget {
  final BlockEntity block;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<Map<String, dynamic>> onAttributesChanged;
  final VoidCallback onSubmitted;
  final VoidCallback? onDelete;
  final bool readOnly;

  const CodeBlock({
    super.key,
    required this.block,
    required this.focusNode,
    required this.onChanged,
    required this.onAttributesChanged,
    required this.onSubmitted,
    this.onDelete,
    this.readOnly = false,
  });

  @override
  ConsumerState<CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends ConsumerState<CodeBlock> {
  late HighlightingTextController _textController;
  late String currentLanguage;

  @override
  void initState() {
    super.initState();
    
    // Resolve initial language
    final langAttr = widget.block.attributes['language'] ?? widget.block.attributes['code-block'];
    currentLanguage = langAttr is String && langAttr.isNotEmpty && langAttr != 'true'
        ? langAttr
        : 'python';

    _textController = HighlightingTextController(
      text: widget.block.content,
      context: context,
      activeCodeTheme: ref.read(settingsProvider).activeCodeTheme,
      language: currentLanguage,
    );

    AppLogger.info('CodeBlock: Initialized with language "$currentLanguage" for block ${widget.block.id}');
  }

  @override
  void didUpdateWidget(covariant CodeBlock oldWidget) {
    super.didUpdateWidget(oldWidget);

    final langAttr = widget.block.attributes['language'] ?? widget.block.attributes['code-block'];
    final newLang = langAttr is String && langAttr.isNotEmpty && langAttr != 'true'
        ? langAttr
        : 'python';

    if (newLang != currentLanguage) {
      AppLogger.info('CodeBlock: Language updated from "$currentLanguage" to "$newLang" for block ${widget.block.id}');
      setState(() {
        currentLanguage = newLang;
        _textController.language = newLang;
      });
    }

    if (widget.block.content != _textController.text) {
      final cursorPosition = _textController.selection;
      _textController.text = widget.block.content;
      try {
        _textController.selection = cursorPosition;
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _textController.text));
    AppLogger.info('CodeBlock: Content copied to clipboard for block ${widget.block.id}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final activeCodeTheme = settings.activeCodeTheme;
    final isDarkCodeTheme = activeCodeTheme.contains('dark') || activeCodeTheme == 'monokai';

    // Reactively update the theme on the text controller
    _textController.activeCodeTheme = activeCodeTheme;

    final containerColor = isDarkCodeTheme ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = theme.colorScheme.outlineVariant.withOpacity(0.5);
    final textColor = isDarkCodeTheme ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
    final headerBgColor = isDarkCodeTheme ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final headerTextColor = isDarkCodeTheme ? Colors.grey.shade400 : Colors.grey.shade700;

    return Focus(
      onKeyEvent: (node, event) {
        if (widget.readOnly) return KeyEventResult.ignored;
        if (event is KeyEvent && event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.backspace &&
              _textController.text.isEmpty &&
              widget.onDelete != null) {
            AppLogger.info('CodeBlock: Deleting block ${widget.block.id}');
            widget.onDelete!();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter &&
              HardwareKeyboard.instance.isControlPressed) {
            widget.onSubmitted();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: headerBgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Language Selection dropdown picker
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CODE SNIPPET:',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: headerTextColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: currentLanguage,
                        dropdownColor: headerBgColor,
                        underline: const SizedBox(),
                        icon: widget.readOnly ? const SizedBox.shrink() : Icon(Icons.arrow_drop_down_rounded, size: 16, color: headerTextColor),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: headerTextColor,
                        ),
                        items: _supportedLanguages.map((lang) {
                          return DropdownMenuItem(
                            value: lang,
                            child: Text(lang.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: widget.readOnly ? null : (newLang) {
                          if (newLang != null) {
                            setState(() {
                              currentLanguage = newLang;
                              _textController.language = newLang;
                            });
                            widget.onAttributesChanged({
                              ...widget.block.attributes,
                              'language': newLang,
                              'code-block': newLang,
                            });
                            AppLogger.info('CodeBlock: Selected language picker to "$newLang" for block ${widget.block.id}');
                          }
                        },
                      ),
                    ],
                  ),
                  // Enhanced Copy Button
                  GestureDetector(
                    onTap: _copyToClipboard,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.copy_rounded,
                          size: 13,
                          color: headerTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'COPY',
                          style: TextStyle(
                            fontSize: 9,
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            color: headerTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Code Field
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _textController,
                focusNode: widget.focusNode,
                maxLines: null,
                onChanged: widget.onChanged,
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 13,
                  height: 1.4,
                  color: textColor,
                ),
                readOnly: widget.readOnly,
                decoration: InputDecoration(
                  hintText: widget.readOnly ? null : '// Write your code here...',
                  hintStyle: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 13,
                    color: textColor.withOpacity(0.3),
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
