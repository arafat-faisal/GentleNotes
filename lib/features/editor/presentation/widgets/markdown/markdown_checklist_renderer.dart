import 'package:flutter/material.dart';

import '../../../../../../models/models.dart';
import 'markdown_renderer.dart';
import 'markdown_style_builder.dart';

class MarkdownChecklistRenderer extends StatelessWidget {
  final MarkdownCustomBlock block;
  final String? fontFamily;
  final List<AttachmentModel> attachments;

  const MarkdownChecklistRenderer({
    super.key,
    required this.block,
    this.fontFamily,
    required this.attachments,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            block.isChecked! ? Icons.check_box : Icons.check_box_outline_blank,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: MarkdownStyleBuilder.renderInlineText(
              context,
              block.text,
              theme.textTheme.bodyMedium?.copyWith(
                decoration: block.isChecked! ? TextDecoration.lineThrough : null,
                color: block.isChecked! ? theme.colorScheme.onSurface.withOpacity(0.5) : null,
              ),
              fontFamily: fontFamily,
              attachments: attachments,
            ),
          ),
        ],
      ),
    );
  }
}
