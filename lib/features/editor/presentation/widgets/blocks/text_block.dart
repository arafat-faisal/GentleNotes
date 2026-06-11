import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/entities/block_entity.dart';

class TextBlock extends StatefulWidget {
  final BlockEntity block;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final VoidCallback? onDelete;
  final bool readOnly;

  const TextBlock({
    super.key,
    required this.block,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    this.onDelete,
    this.readOnly = false,
  });

  @override
  State<TextBlock> createState() => _TextBlockState();
}

class _TextBlockState extends State<TextBlock> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.block.content);
  }

  @override
  void didUpdateWidget(covariant TextBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.block.content != _textController.text) {
      final cursorPosition = _textController.selection;
      _textController.text = widget.block.content;
      try {
        _textController.selection = cursorPosition;
      } catch (_) {
        // Fallback if selection is out of bounds
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fontStyle = theme.textTheme.bodyLarge?.copyWith(
      fontFamily: theme.textTheme.bodyLarge?.fontFamily ?? 'Inter',
      height: 1.5,
    );

    return Focus(
      onKeyEvent: (node, event) {
        if (widget.readOnly) return KeyEventResult.ignored;
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.backspace &&
              _textController.text.isEmpty &&
              widget.onDelete != null) {
            widget.onDelete!();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter &&
              !HardwareKeyboard.instance.isShiftPressed) {
            widget.onSubmitted();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: _textController,
        focusNode: widget.focusNode,
        maxLines: null,
        onChanged: widget.onChanged,
        style: fontStyle,
        readOnly: widget.readOnly,
        decoration: InputDecoration(
          hintText: widget.readOnly ? null : 'Type something...',
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: theme.hintColor.withValues(alpha: 0.4),
            fontFamily: theme.textTheme.bodyLarge?.fontFamily ?? 'Inter',
          ),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        ),
      ),
    );
  }
}
