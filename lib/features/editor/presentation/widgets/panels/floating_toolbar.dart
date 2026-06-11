import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../models/models.dart';
import '../../../../settings/presentation/controllers/settings_controller.dart';
import '../../../domain/entities/block_type.dart';
import '../../../../../core/theme/font_helper.dart';
import 'toolbar/alignment_group.dart';
import 'toolbar/block_insert_group.dart';
import 'toolbar/color_picker_group.dart';
import 'toolbar/history_action_group.dart';
import 'toolbar/media_insert_group.dart';
import 'toolbar/text_format_group.dart';
import 'toolbar/toolbar_button.dart';
import 'toolbar/toolbar_overflow_menu.dart';

class FloatingToolbar extends ConsumerStatefulWidget {
  final String noteId;
  final Function(BlockType type, {String content, Map<String, dynamic> attributes}) onInsertBlock;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool canUndo;
  final bool canRedo;
  final bool isSpeechListening;
  final VoidCallback onSpeechToggle;
  final QuillController? quillController;

  const FloatingToolbar({
    super.key,
    required this.noteId,
    required this.onInsertBlock,
    required this.onUndo,
    required this.onRedo,
    required this.canUndo,
    required this.canRedo,
    required this.isSpeechListening,
    required this.onSpeechToggle,
    this.quillController,
  });

  @override
  ConsumerState<FloatingToolbar> createState() => _FloatingToolbarState();
}

class _FloatingToolbarState extends ConsumerState<FloatingToolbar> {
  String? _activeToolbarGroup;

  @override
  void initState() {
    super.initState();
    widget.quillController?.addListener(_onQuillUpdate);
  }

  @override
  void didUpdateWidget(FloatingToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quillController != widget.quillController) {
      oldWidget.quillController?.removeListener(_onQuillUpdate);
      widget.quillController?.addListener(_onQuillUpdate);
    }
  }

  @override
  void dispose() {
    widget.quillController?.removeListener(_onQuillUpdate);
    super.dispose();
  }

  void _onQuillUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final allowedTools = settings.allowedTools;

    final barBg = isDark
        ? const Color(0xFF13111C).withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.85);
    final borderCol = isDark
        ? const Color(0xFF2E2845).withValues(alpha: 0.5)
        : const Color(0xFFE3DCF5).withValues(alpha: 0.5);

    return LayoutBuilder(
      builder: (context, constraints) {
        final toolbarWidth = constraints.maxWidth.clamp(0.0, 500.0);

        if (settings.editorMode == EditorMode.blockEditor || widget.quillController == null) {
          final showHeading = allowedTools.contains('heading');
          final showChecklist = allowedTools.contains('lists');
          final showCode = allowedTools.contains('format');
          final showImage = allowedTools.contains('insert');
          final showDrawing = settings.userMode == AppUserMode.student || settings.userMode == AppUserMode.normal || (settings.userMode == AppUserMode.custom && allowedTools.contains('color'));
          final showVoice = settings.userMode == AppUserMode.student || settings.userMode == AppUserMode.normal || (settings.userMode == AppUserMode.custom && allowedTools.contains('color'));
          final showDivider = allowedTools.contains('insert');
          final showDictation = settings.userMode != AppUserMode.coder;

          // Fallback for Block Editor mode
          return Material(
            color: Colors.transparent,
            elevation: 6,
            borderRadius: BorderRadius.circular(20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: toolbarWidth,
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: barBg,
                    border: Border.all(color: borderCol, width: 1.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HistoryActionGroup(
                          onUndo: widget.onUndo,
                          onRedo: widget.onRedo,
                          canUndo: widget.canUndo,
                          canRedo: widget.canRedo,
                        ),
                        const VerticalDivider(width: 16, indent: 12, endIndent: 12),
                        BlockInsertGroup(
                          onInsertBlock: widget.onInsertBlock,
                          showHeading: showHeading,
                          showChecklist: showChecklist,
                          showCode: showCode,
                        ),
                        if (showImage || showDrawing || showVoice || showDivider || showCode)
                          MediaInsertGroup(
                            noteId: widget.noteId,
                            onInsertBlock: widget.onInsertBlock,
                            showImage: showImage,
                            showDrawing: showDrawing,
                            showVoice: showVoice,
                            showDivider: showDivider,
                            showCode: showCode,
                            borderCol: borderCol,
                            isSpeechListening: widget.isSpeechListening,
                            onSpeechToggle: widget.onSpeechToggle,
                          ),
                        if (showDictation) ...[
                          const VerticalDivider(width: 16, indent: 12, endIndent: 12),
                          IconButton(
                            icon: Icon(
                              widget.isSpeechListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                              size: 20,
                              color: widget.isSpeechListening ? Colors.red : null,
                            ),
                            onPressed: widget.onSpeechToggle,
                            tooltip: 'Dictation (Voice typing)',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        // Quill formatting toolbar style
        final filteredGroups = const [
          ('format', Icons.format_bold, 'Format'),
          ('font',   Icons.font_download_outlined, 'Font'),
          ('color',   Icons.palette_outlined, 'Color'),
          ('heading', Icons.title_rounded, 'Heading'),
          ('align',   Icons.format_align_left_rounded, 'Align'),
          ('lists',   Icons.format_list_bulleted, 'Lists'),
          ('insert',  Icons.add_box_outlined, 'Insert'),
          ('indent',  Icons.format_indent_increase_rounded, 'Indent'),
        ].where((g) => g.$1 == 'font' || allowedTools.contains(g.$1)).toList();

        final accentColor = theme.colorScheme.primary;

        final style = widget.quillController!.getSelectionStyle();
        final isH1 = style.attributes[Attribute.header.key]?.value == 1;
        final isH2 = style.attributes[Attribute.header.key]?.value == 2;
        final isH3 = style.attributes[Attribute.header.key]?.value == 3;
        final isH4 = style.attributes[Attribute.header.key]?.value == 4;
        final isH5 = style.attributes[Attribute.header.key]?.value == 5;
        final isH6 = style.attributes[Attribute.header.key]?.value == 6;
        final isParagraph = style.attributes[Attribute.header.key]?.value == null;

        final listVal = style.attributes[Attribute.list.key]?.value;
        final isBullet = listVal == 'bullet';
        final isOrdered = listVal == 'ordered';
        final isChecklist = listVal == 'checked' || listVal == 'unchecked';
        final isBlockquote = style.containsKey(Attribute.blockQuote.key);
        final isCodeBlock = style.containsKey(Attribute.codeBlock.key);

        Widget subRow() {
          switch (_activeToolbarGroup) {
            case 'font':
              final selStyle = widget.quillController!.getSelectionStyle();
              final activeFont = selStyle.attributes[Attribute.font.key]?.value as String? ?? 'System';
              final selectedHeight = settings.editorLineHeight;

              // Read active font size from selection (stored as a String in Quill)
              final activeSizeAttr = selStyle.attributes[Attribute.size.key]?.value;
              double activeSize = settings.editorFontSize;
              if (activeSizeAttr is String) {
                final d = double.tryParse(activeSizeAttr);
                if (d != null) {
                  activeSize = d;
                } else {
                  if (activeSizeAttr == 'small') {
                    activeSize = 12.0;
                  } else if (activeSizeAttr == 'large') activeSize = 20.0;
                  else if (activeSizeAttr == 'huge') activeSize = 28.0;
                }
              } else if (activeSizeAttr is int) {
                activeSize = activeSizeAttr.toDouble();
              } else if (activeSizeAttr is double) {
                activeSize = activeSizeAttr;
              }

              // Helper: apply font without losing the text selection.
              // Tapping a chip can steal focus from the QuillEditor, which
              // collapses the selection before formatSelection() runs.
              // We snapshot the selection right here (during build, before any
              // tap) and reapply it immediately after formatting.
              final savedSelection = widget.quillController!.selection;

              void applyFont(String fontName) {
                final targetFont = fontName == 'System' ? null : fontName;
                final isCurrentlySelected = activeFont == fontName;
                widget.quillController!.updateSelection(savedSelection, ChangeSource.local);
                widget.quillController!.formatSelection(
                  Attribute.clone(Attribute.font, isCurrentlySelected ? null : targetFont),
                );
              }

              void applySize(double newSize) {
                widget.quillController!.updateSelection(savedSelection, ChangeSource.local);
                // SizeAttribute stores String values; convert to integer string
                widget.quillController!.formatSelection(
                  Attribute.clone(Attribute.size, newSize.toInt().toString()),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Font size controls (leftmost for quick access)
                    IconButton(
                      icon: const Icon(Icons.remove_rounded, size: 14),
                      onPressed: activeSize > 8.0
                          ? () => applySize(activeSize - 1.0)
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      tooltip: 'Decrease font size',
                    ),
                    GestureDetector(
                      onTap: () {
                        // Tap on the size label shows a quick preset menu
                        showDialog<double>(
                          context: context,
                          builder: (ctx) => SimpleDialog(
                            title: const Text('Font Size'),
                            children: [10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 24.0, 28.0, 32.0, 36.0, 48.0, 72.0]
                                .map((s) => SimpleDialogOption(
                                      onPressed: () { Navigator.pop(ctx, s); },
                                      child: Text('${s.toInt()}pt',
                                          style: TextStyle(
                                              fontWeight: s == activeSize ? FontWeight.bold : FontWeight.normal,
                                              color: s == activeSize ? accentColor : null)),
                                    ))
                                .toList(),
                          ),
                        ).then((s) {
                          if (s != null) applySize(s);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${activeSize.toInt()}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, size: 14),
                      onPressed: activeSize < 72.0
                          ? () => applySize(activeSize + 1.0)
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      tooltip: 'Increase font size',
                    ),
                    const VerticalDivider(width: 16, indent: 8, endIndent: 8),
                    // Font family chips — each chip renders its own name in that font
                    ...kAppEditorFonts.map((f) {
                      final isSelected = activeFont == f.name;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: ChoiceChip(
                          label: Text(
                            f.displayName,
                            style: (f.name == 'System'
                                    ? const TextStyle()
                                    : FontHelper.getTextStyle(f.name))
                                .copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? accentColor
                                  : theme.colorScheme.onSurface.withAlpha(220),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: accentColor.withAlpha(40),
                          onSelected: (_) => applyFont(f.name),
                          showCheckmark: false,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: isSelected
                              ? BorderSide(color: accentColor, width: 1.5)
                              : BorderSide.none,
                        ),
                      );
                    }),
                    const VerticalDivider(width: 16, indent: 8, endIndent: 8),
                    // Line spacing toggle
                    IconButton(
                      icon: const Icon(Icons.format_line_spacing_rounded, size: 15),
                      onPressed: () {
                        double nextHeight = 1.4;
                        if (selectedHeight == 1.2) {
                          nextHeight = 1.4;
                        } else if (selectedHeight == 1.4) nextHeight = 1.6;
                        else if (selectedHeight == 1.6) nextHeight = 1.8;
                        else if (selectedHeight == 1.8) nextHeight = 1.2;
                        ref.read(settingsProvider.notifier).updateEditorLineHeight(nextHeight);
                      },
                      tooltip: 'Line Spacing ${selectedHeight}x',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
              );
            case 'format':
              return TextFormatGroup(quillController: widget.quillController!, accentColor: accentColor);
            case 'color':
              return ColorPickerGroup(quillController: widget.quillController!, accentColor: accentColor);
            case 'heading':
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ToolbarTextButton(text: 'H1', tooltip: 'Heading 1', onTap: () => widget.quillController!.formatSelection(isH1 ? Attribute.clone(Attribute.header, null) : Attribute.h1), isActive: isH1, accentColor: accentColor),
                    ToolbarTextButton(text: 'H2', tooltip: 'Heading 2', onTap: () => widget.quillController!.formatSelection(isH2 ? Attribute.clone(Attribute.header, null) : Attribute.h2), isActive: isH2, accentColor: accentColor),
                    ToolbarTextButton(text: 'H3', tooltip: 'Heading 3', onTap: () => widget.quillController!.formatSelection(isH3 ? Attribute.clone(Attribute.header, null) : Attribute.h3), isActive: isH3, accentColor: accentColor),
                    ToolbarTextButton(text: 'H4', tooltip: 'Heading 4', onTap: () => widget.quillController!.formatSelection(isH4 ? Attribute.clone(Attribute.header, null) : Attribute.h4), isActive: isH4, accentColor: accentColor),
                    ToolbarTextButton(text: 'H5', tooltip: 'Heading 5', onTap: () => widget.quillController!.formatSelection(isH5 ? Attribute.clone(Attribute.header, null) : Attribute.h5), isActive: isH5, accentColor: accentColor),
                    ToolbarTextButton(text: 'H6', tooltip: 'Heading 6', onTap: () => widget.quillController!.formatSelection(isH6 ? Attribute.clone(Attribute.header, null) : Attribute.h6), isActive: isH6, accentColor: accentColor),
                    ToolbarTextButton(text: 'Paragraph', tooltip: 'Paragraph Text', onTap: () => widget.quillController!.formatSelection(Attribute.clone(Attribute.header, null)), isActive: isParagraph, accentColor: accentColor),
                  ],
                ),
              );
            case 'align':
              return AlignmentGroup(quillController: widget.quillController!, accentColor: accentColor);
            case 'lists':
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ToolbarActionButton(icon: Icons.format_list_bulleted, tooltip: 'Bullet List', onTap: () => widget.quillController!.formatSelection(isBullet ? Attribute.clone(Attribute.list, null) : Attribute.ul), isActive: isBullet, accentColor: accentColor),
                  ToolbarActionButton(icon: Icons.format_list_numbered, tooltip: 'Numbered List', onTap: () => widget.quillController!.formatSelection(isOrdered ? Attribute.clone(Attribute.list, null) : Attribute.ol), isActive: isOrdered, accentColor: accentColor),
                  ToolbarActionButton(icon: Icons.check_box_outlined, tooltip: 'Checklist', onTap: () => widget.quillController!.formatSelection(isChecklist ? Attribute.clone(Attribute.list, null) : Attribute.unchecked), isActive: isChecklist, accentColor: accentColor),
                  ToolbarActionButton(icon: Icons.format_quote_rounded, tooltip: 'Blockquote', onTap: () => widget.quillController!.formatSelection(isBlockquote ? Attribute.clone(Attribute.blockQuote, null) : Attribute.blockQuote), isActive: isBlockquote, accentColor: accentColor),
                ],
              );
            case 'insert':
              final showDrawing = settings.userMode == AppUserMode.student || settings.userMode == AppUserMode.normal || (settings.userMode == AppUserMode.custom && allowedTools.contains('color'));
              final showVoice = settings.userMode == AppUserMode.student || settings.userMode == AppUserMode.normal || (settings.userMode == AppUserMode.custom && allowedTools.contains('color'));
              final showDivider = allowedTools.contains('insert');
              final showImage = allowedTools.contains('insert');

              return MediaInsertGroup(
                noteId: widget.noteId,
                onInsertBlock: widget.onInsertBlock,
                showImage: showImage,
                showDrawing: showDrawing,
                showVoice: showVoice,
                showDivider: showDivider,
                showCode: allowedTools.contains('format'),
                borderCol: borderCol,
                isInline: true,
                accentColor: accentColor,
                isSpeechListening: widget.isSpeechListening,
                onSpeechToggle: widget.onSpeechToggle,
              );
            case 'indent':
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ToolbarActionButton(icon: Icons.format_indent_increase_rounded, tooltip: 'Indent', onTap: () => widget.quillController!.indentSelection(true), accentColor: accentColor),
                  ToolbarActionButton(icon: Icons.format_indent_decrease_rounded, tooltip: 'Outdent', onTap: () => widget.quillController!.indentSelection(false), accentColor: accentColor),
                  ToolbarActionButton(icon: Icons.format_line_spacing_rounded, tooltip: 'Line Break', onTap: () {
                    final index = widget.quillController!.selection.baseOffset;
                    final insertIndex = index >= 0 ? index : widget.quillController!.document.length - 1;
                    final length = widget.quillController!.selection.extentOffset - index;
                    widget.quillController!.replaceText(
                      insertIndex,
                      length >= 0 ? length : 0,
                      '\n',
                      TextSelection.collapsed(offset: insertIndex + 1),
                    );
                  }, accentColor: accentColor),
                ],
              );
          }
          return const SizedBox.shrink();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_activeToolbarGroup != null) ...[
              Material(
                color: Colors.transparent,
                elevation: 6,
                borderRadius: BorderRadius.circular(20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      constraints: BoxConstraints(maxWidth: toolbarWidth),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: barBg,
                        border: Border.all(color: borderCol, width: 1.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: subRow(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Material(
              color: Colors.transparent,
              elevation: 6,
              borderRadius: BorderRadius.circular(20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: toolbarWidth,
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: barBg,
                      border: Border.all(color: borderCol, width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HistoryActionGroup(
                            onUndo: widget.onUndo,
                            onRedo: widget.onRedo,
                            canUndo: widget.canUndo,
                            canRedo: widget.canRedo,
                          ),
                          const VerticalDivider(width: 16, indent: 12, endIndent: 12),

                          // Group buttons
                          ...filteredGroups.map((g) => ToolbarGroupButton(
                            icon: g.$2,
                            label: g.$3,
                            isActive: _activeToolbarGroup == g.$1,
                            accentColor: accentColor,
                            onTap: () => setState(() {
                              _activeToolbarGroup = (_activeToolbarGroup == g.$1 ? null : g.$1);
                            }),
                          )),

                          const VerticalDivider(width: 16, indent: 12, endIndent: 12),

                          // Speech Dictation
                          IconButton(
                            icon: Icon(
                              widget.isSpeechListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                              size: 20,
                              color: widget.isSpeechListening ? Colors.red : null,
                            ),
                            onPressed: widget.onSpeechToggle,
                            tooltip: 'Dictation (Voice typing)',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const ToolbarOverflowMenu(),
          ],
        );
      },
    );
  }
}
