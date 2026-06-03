import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'toolbar_button.dart';

class TextFormatGroup extends StatelessWidget {
  final QuillController quillController;
  final Color accentColor;

  const TextFormatGroup({
    super.key,
    required this.quillController,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final style = quillController.getSelectionStyle();
    final isBold = style.containsKey(Attribute.bold.key);
    final isItalic = style.containsKey(Attribute.italic.key);
    final isUnderline = style.containsKey(Attribute.underline.key);
    final isStrike = style.containsKey(Attribute.strikeThrough.key);
    final isCode = style.containsKey(Attribute.inlineCode.key);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ToolbarActionButton(
          icon: Icons.format_bold, 
          tooltip: 'Bold', 
          onTap: () {
            quillController.formatSelection(isBold ? Attribute.clone(Attribute.bold, null) : Attribute.bold);
          }, 
          isActive: isBold,
          accentColor: accentColor,
        ),
        ToolbarActionButton(
          icon: Icons.format_italic, 
          tooltip: 'Italic', 
          onTap: () {
            quillController.formatSelection(isItalic ? Attribute.clone(Attribute.italic, null) : Attribute.italic);
          }, 
          isActive: isItalic,
          accentColor: accentColor,
        ),
        ToolbarActionButton(
          icon: Icons.format_underlined, 
          tooltip: 'Underline', 
          onTap: () {
            quillController.formatSelection(isUnderline ? Attribute.clone(Attribute.underline, null) : Attribute.underline);
          }, 
          isActive: isUnderline,
          accentColor: accentColor,
        ),
        ToolbarActionButton(
          icon: Icons.format_strikethrough, 
          tooltip: 'Strikethrough', 
          onTap: () {
            quillController.formatSelection(isStrike ? Attribute.clone(Attribute.strikeThrough, null) : Attribute.strikeThrough);
          }, 
          isActive: isStrike,
          accentColor: accentColor,
        ),
        ToolbarActionButton(
          icon: Icons.code_rounded, 
          tooltip: 'Inline Code', 
          onTap: () {
            quillController.formatSelection(isCode ? Attribute.clone(Attribute.inlineCode, null) : Attribute.inlineCode);
          }, 
          isActive: isCode,
          accentColor: accentColor,
        ),
      ],
    );
  }
}
