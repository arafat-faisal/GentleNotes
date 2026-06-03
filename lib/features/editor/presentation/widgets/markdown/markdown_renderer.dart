enum MarkdownBlockType {
  paragraph,
  heading1,
  heading2,
  heading3,
  heading4,
  heading5,
  heading6,
  code,
  bullet,
  ordered,
  checklist,
  image,
  divider,
  blockquote,
  table,
  details,
  math,
  sticker;
}

class MarkdownCustomBlock {
  final MarkdownBlockType type;
  final String text;
  final String? altText;
  final bool? isChecked;
  final int level;
  final List<List<String>>? tableData;

  MarkdownCustomBlock({
    required this.type,
    required this.text,
    this.altText,
    this.isChecked,
    this.level = 0,
    this.tableData,
  });
}
