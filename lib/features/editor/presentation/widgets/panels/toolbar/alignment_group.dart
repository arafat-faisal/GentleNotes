import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'toolbar_button.dart';

class AlignmentGroup extends StatelessWidget {
  final QuillController quillController;
  final Color accentColor;

  const AlignmentGroup({
    super.key,
    required this.quillController,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final style = quillController.getSelectionStyle();
    final alignVal = style.attributes[Attribute.align.key]?.value;
    final isAlignLeft = alignVal == null || alignVal == 'left';
    final isAlignCenter = alignVal == 'center';
    final isAlignRight = alignVal == 'right';
    final isAlignJustify = alignVal == 'justify';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ToolbarActionButton(
          icon: Icons.format_align_left_rounded,
          tooltip: 'Align Left',
          onTap: () => quillController.formatSelection(Attribute.leftAlignment),
          isActive: isAlignLeft,
          accentColor: accentColor,
        ),
        ToolbarActionButton(
          icon: Icons.format_align_center_rounded,
          tooltip: 'Align Center',
          onTap: () => quillController.formatSelection(Attribute.centerAlignment),
          isActive: isAlignCenter,
          accentColor: accentColor,
        ),
        ToolbarActionButton(
          icon: Icons.format_align_right_rounded,
          tooltip: 'Align Right',
          onTap: () => quillController.formatSelection(Attribute.rightAlignment),
          isActive: isAlignRight,
          accentColor: accentColor,
        ),
        ToolbarActionButton(
          icon: Icons.format_align_justify_rounded,
          tooltip: 'Justify',
          onTap: () => quillController.formatSelection(Attribute.justifyAlignment),
          isActive: isAlignJustify,
          accentColor: accentColor,
        ),
      ],
    );
  }
}
