import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/entities/block_entity.dart';

class CodeBlock extends StatefulWidget {
  final BlockEntity block;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final VoidCallback? onDelete;

  const CodeBlock({
    super.key,
    required this.block,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    this.onDelete,
  });

  @override
  State<CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<CodeBlock> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.block.content);
  }

  @override
  void didUpdateWidget(covariant CodeBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    final isDark = theme.brightness == Brightness.dark;

    final containerColor = isDark ? const Color(0xFF1E1A30) : const Color(0xFFF3F0FA);
    final borderColor = isDark ? const Color(0xFF2E2A45) : const Color(0xFFE3DCF5);

    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyEvent && event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.backspace &&
              _textController.text.isEmpty &&
              widget.onDelete != null) {
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151224) : const Color(0xFFE9E4F5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CODE SNIPPET',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _copyToClipboard,
                        tooltip: 'Copy Code',
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ],
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
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 13,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: '// Write your code here...',
                  hintStyle: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 13,
                    color: theme.hintColor.withOpacity(0.3),
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
