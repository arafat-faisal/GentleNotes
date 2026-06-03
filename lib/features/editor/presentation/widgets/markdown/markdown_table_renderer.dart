import 'package:flutter/material.dart';

import '../../../../../../models/models.dart';
import 'markdown_renderer.dart';
import 'markdown_style_builder.dart';

class MarkdownTableRenderer extends StatelessWidget {
  final MarkdownCustomBlock block;
  final String? fontFamily;
  final List<AttachmentModel> attachments;

  const MarkdownTableRenderer({
    super.key,
    required this.block,
    this.fontFamily,
    required this.attachments,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (block.tableData == null || block.tableData!.isEmpty) return const SizedBox();
    final headers = block.tableData!.first;
    if (headers.isEmpty) return const SizedBox();
    final int columnCount = headers.length;
    final rows = block.tableData!.skip(1).toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHighest.withOpacity(0.3)),
          columns: headers.map((h) {
            return DataColumn(
              label: MarkdownStyleBuilder.renderInlineText(
                context, 
                h, 
                theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                fontFamily: fontFamily,
                attachments: attachments,
              ),
            );
          }).toList(),
          rows: rows.map((row) {
            final List<String> cells = List.from(row);
            if (cells.length < columnCount) {
              cells.addAll(List.filled(columnCount - cells.length, ''));
            } else if (cells.length > columnCount) {
              cells.removeRange(columnCount, cells.length);
            }
            return DataRow(
              cells: cells.map((cell) {
                return DataCell(
                  MarkdownStyleBuilder.renderInlineText(
                    context, 
                    cell, 
                    theme.textTheme.bodyMedium,
                    fontFamily: fontFamily,
                    attachments: attachments,
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}
