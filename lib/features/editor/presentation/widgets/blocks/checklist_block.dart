import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/entities/block_entity.dart';

class ChecklistBlock extends StatefulWidget {
  final BlockEntity block;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<Map<String, dynamic>> onAttributesChanged;
  final VoidCallback onSubmitted;
  final VoidCallback? onDelete;

  const ChecklistBlock({
    super.key,
    required this.block,
    required this.focusNode,
    required this.onChanged,
    required this.onAttributesChanged,
    required this.onSubmitted,
    this.onDelete,
  });

  @override
  State<ChecklistBlock> createState() => _ChecklistBlockState();
}

class _ChecklistBlockState extends State<ChecklistBlock> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.block.content);
  }

  @override
  void didUpdateWidget(covariant ChecklistBlock oldWidget) {
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
    final isChecked = widget.block.attributes['list'] == 'checked';

    final textStyle = theme.textTheme.bodyLarge?.copyWith(
      fontFamily: 'Inter',
      decoration: isChecked ? TextDecoration.lineThrough : null,
      color: isChecked
          ? theme.colorScheme.onSurface.withOpacity(0.4)
          : theme.colorScheme.onSurface,
      height: 1.5,
    );

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
              !HardwareKeyboard.instance.isShiftPressed) {
            widget.onSubmitted();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                color: isChecked ? theme.colorScheme.primary : theme.unselectedWidgetColor,
                size: 22,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () {
                final newAttrs = Map<String, dynamic>.from(widget.block.attributes);
                newAttrs['list'] = isChecked ? 'unchecked' : 'checked';
                widget.onAttributesChanged(newAttrs);
              },
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: widget.focusNode,
                maxLines: null,
                onChanged: widget.onChanged,
                style: textStyle,
                decoration: InputDecoration(
                  hintText: 'To-do item...',
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.hintColor.withOpacity(0.3),
                    fontFamily: 'Inter',
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
