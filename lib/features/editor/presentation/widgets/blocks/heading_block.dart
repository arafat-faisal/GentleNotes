import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/entities/block_entity.dart';

class HeadingBlock extends StatefulWidget {
  final BlockEntity block;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final VoidCallback? onDelete;
  final bool readOnly;

  const HeadingBlock({
    super.key,
    required this.block,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    this.onDelete,
    this.readOnly = false,
  });

  @override
  State<HeadingBlock> createState() => _HeadingBlockState();
}

class _HeadingBlockState extends State<HeadingBlock> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.block.content);
  }

  @override
  void didUpdateWidget(covariant HeadingBlock oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerLevel = widget.block.attributes['header'] ?? 1;

    TextStyle? textStyle;
    String hintText = 'Heading $headerLevel';

    switch (headerLevel) {
      case 2:
        textStyle = theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          fontFamily: 'Outfit',
          color: theme.colorScheme.onSurface,
        );
        break;
      case 3:
        textStyle = theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontFamily: 'Outfit',
          color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
        );
        break;
      case 1:
      default:
        textStyle = theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          fontFamily: 'Outfit',
          color: theme.colorScheme.onSurface,
        );
        break;
    }

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
        style: textStyle,
        readOnly: widget.readOnly,
        decoration: InputDecoration(
          hintText: widget.readOnly ? null : hintText,
          hintStyle: textStyle?.copyWith(
            color: theme.hintColor.withValues(alpha: 0.3),
          ),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        ),
      ),
    );
  }
}
