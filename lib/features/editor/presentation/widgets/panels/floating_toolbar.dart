import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import '../../../domain/entities/block_type.dart';
import 'voice_recorder_bottom_sheet.dart';

class FloatingToolbar extends StatefulWidget {
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
  State<FloatingToolbar> createState() => _FloatingToolbarState();
}

class _FloatingToolbarState extends State<FloatingToolbar> {
  String? _activeToolbarGroup;
  String? _activeColorMode;
  bool _showCustomColorPicker = false;
  double _customHue = 0.0;
  double _customSaturation = 1.0;
  double _customLightness = 0.5;
  Color _customSelectedColor = const Color(0xFFEF4444);
  final List<Color> _userSavedColors = [];

  Color _getCurrentSelectedColor() {
    if (widget.quillController == null) return Colors.transparent;
    final style = widget.quillController!.getSelectionStyle();
    if (_activeColorMode == 'text') {
      final attr = style.attributes[Attribute.color.key];
      if (attr != null && attr.value is String) {
        return Color(int.parse('FF${(attr.value as String).replaceAll('#', '')}', radix: 16));
      }
      return Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;
    } else if (_activeColorMode == 'highlight') {
      final attr = style.attributes[Attribute.background.key];
      if (attr != null && attr.value is String) {
        return Color(int.parse('FF${(attr.value as String).replaceAll('#', '')}', radix: 16));
      }
      return Colors.transparent;
    }
    return Colors.transparent;
  }

  void _applyColor(Color? color) {
    if (widget.quillController == null) return;
    final hexStr = color != null
        ? '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}'
        : null;

    if (_activeColorMode == 'text') {
      widget.quillController!.formatSelection(ColorAttribute(hexStr));
    } else if (_activeColorMode == 'highlight') {
      widget.quillController!.formatSelection(BackgroundAttribute(hexStr));
    }
    setState(() {});
  }

  void _updateCustomColor() {
    _customSelectedColor = HSLColor.fromAHSL(1.0, _customHue, _customSaturation, _customLightness).toColor();
    _applyColor(_customSelectedColor);
  }

  void _updateCustomColorPickerFromSelection() {
    final color = _getCurrentSelectedColor();
    if (color != Colors.transparent &&
        color != (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)) {
      final hsl = HSLColor.fromColor(color);
      setState(() {
        _customHue = hsl.hue;
        _customSaturation = hsl.saturation;
        _customLightness = hsl.lightness;
        _customSelectedColor = color;
      });
    }
  }

  Widget _buildColorSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required Gradient gradient,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 38,
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              gradient: gradient,
            ),
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 10,
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                thumbColor: Colors.white,
                overlayColor: Colors.transparent,
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineCustomColorPicker(ThemeData theme, bool isDark) {
    final hexStr = '#${_customSelectedColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildColorSlider(
          label: 'Hue',
          value: _customHue,
          min: 0.0,
          max: 360.0,
          gradient: LinearGradient(
            colors: List.generate(360, (index) => HSLColor.fromAHSL(1.0, index.toDouble(), 1.0, 0.5).toColor()),
          ),
          onChanged: (val) {
            setState(() {
              _customHue = val;
              _updateCustomColor();
            });
          },
        ),
        const SizedBox(height: 6),
        _buildColorSlider(
          label: 'Sat',
          value: _customSaturation,
          min: 0.0,
          max: 1.0,
          gradient: LinearGradient(
            colors: [
              HSLColor.fromAHSL(1.0, _customHue, 0.0, _customLightness).toColor(),
              HSLColor.fromAHSL(1.0, _customHue, 1.0, _customLightness).toColor(),
            ],
          ),
          onChanged: (val) {
            setState(() {
              _customSaturation = val;
              _updateCustomColor();
            });
          },
        ),
        const SizedBox(height: 6),
        _buildColorSlider(
          label: 'Light',
          value: _customLightness,
          min: 0.0,
          max: 1.0,
          gradient: LinearGradient(
            colors: [
              Colors.black,
              HSLColor.fromAHSL(1.0, _customHue, _customSaturation, 0.5).toColor(),
              Colors.white,
            ],
          ),
          onChanged: (val) {
            setState(() {
              _customLightness = val;
              _updateCustomColor();
            });
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _customSelectedColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              hexStr,
              style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              tooltip: 'Save to Palette',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                if (!_userSavedColors.contains(_customSelectedColor)) {
                  setState(() {
                    _userSavedColors.add(_customSelectedColor);
                  });
                }
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 24,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _userSavedColors.map((c) {
                      final isSelected = _getCurrentSelectedColor() == c;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _customSelectedColor = c;
                            final hsl = HSLColor.fromColor(c);
                            _customHue = hsl.hue;
                            _customSaturation = hsl.saturation;
                            _customLightness = hsl.lightness;
                          });
                          _applyColor(c);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? theme.colorScheme.primary : Colors.grey.shade400,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF13111C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Insert Image',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF8B5CF6)),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF8B5CF6)),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (source != null) {
      final file = await picker.pickImage(source: source);
      if (file != null) {
        widget.onInsertBlock(BlockType.image, content: 'file://${file.path}');
      }
    }
  }

  void _recordAudio(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoiceRecorderBottomSheet(
        noteId: widget.noteId,
        onAttach: (filePath) {
          widget.onInsertBlock(BlockType.audio, content: filePath);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final barBg = isDark
        ? const Color(0xFF13111C).withOpacity(0.85)
        : Colors.white.withOpacity(0.85);
    final borderCol = isDark
        ? const Color(0xFF2E2845).withOpacity(0.5)
        : const Color(0xFFE3DCF5).withOpacity(0.5);

    return LayoutBuilder(
      builder: (context, constraints) {
        final toolbarWidth = constraints.maxWidth.clamp(0.0, 500.0);

    if (widget.quillController == null) {
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
                    IconButton(
                      icon: Icon(Icons.undo_rounded, size: 20, color: widget.canUndo ? theme.colorScheme.primary : theme.disabledColor),
                      onPressed: widget.canUndo ? widget.onUndo : null,
                      tooltip: 'Undo',
                    ),
                    IconButton(
                      icon: Icon(Icons.redo_rounded, size: 20, color: widget.canRedo ? theme.colorScheme.primary : theme.disabledColor),
                      onPressed: widget.canRedo ? widget.onRedo : null,
                      tooltip: 'Redo',
                    ),
                    const VerticalDivider(width: 16, indent: 12, endIndent: 12),
                    IconButton(
                      icon: const Icon(Icons.title_rounded, size: 20),
                      onPressed: () => widget.onInsertBlock(BlockType.heading, attributes: {'header': 1}),
                      tooltip: 'Heading 1',
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_list_bulleted_rounded, size: 20),
                      onPressed: () => widget.onInsertBlock(BlockType.checklist),
                      tooltip: 'To-do List',
                    ),
                    IconButton(
                      icon: const Icon(Icons.code_rounded, size: 20),
                      onPressed: () => widget.onInsertBlock(BlockType.code),
                      tooltip: 'Code Snippet',
                    ),
                    IconButton(
                      icon: const Icon(Icons.image_outlined, size: 20),
                      onPressed: () => _pickImage(context),
                      tooltip: 'Insert Image',
                    ),
                    IconButton(
                      icon: const Icon(Icons.draw_outlined, size: 20),
                      onPressed: () => widget.onInsertBlock(BlockType.drawing),
                      tooltip: 'Sketch Canvas',
                    ),
                    IconButton(
                      icon: const Icon(Icons.mic_none_rounded, size: 20),
                      onPressed: () => _recordAudio(context),
                      tooltip: 'Voice Recording',
                    ),
                    IconButton(
                      icon: const Icon(Icons.horizontal_rule_rounded, size: 20),
                      onPressed: () => widget.onInsertBlock(BlockType.horizontalRule),
                      tooltip: 'Divider',
                    ),
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
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Quill formatting toolbar style
    const groups = [
      ('format', Icons.format_bold, 'Format'),
      ('color',   Icons.palette_outlined, 'Color'),
      ('heading', Icons.title_rounded, 'Heading'),
      ('align',   Icons.format_align_left_rounded, 'Align'),
      ('lists',   Icons.format_list_bulleted, 'Lists'),
      ('insert',  Icons.add_box_outlined, 'Insert'),
      ('indent',  Icons.format_indent_increase_rounded, 'Indent'),
    ];

    final accentColor = theme.colorScheme.primary;

    Widget groupBtn(String id, IconData icon, String label) {
      final isActive = _activeToolbarGroup == id;
      return GestureDetector(
        onTap: () => setState(() {
          _activeToolbarGroup = (isActive ? null : id);
          if (_activeToolbarGroup != 'color') {
            _activeColorMode = null;
            _showCustomColorPicker = false;
          }
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? accentColor.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isActive ? accentColor : theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? accentColor : theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget sub(IconData icon, String tooltip, VoidCallback onTap, {bool active = false}) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: active ? accentColor.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: active ? accentColor : theme.colorScheme.onSurface),
          ),
        ),
      );
    }

    Widget subText(String text, String tooltip, VoidCallback onTap, {bool active = false}) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: active ? accentColor.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: active ? accentColor : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      );
    }

    final style = widget.quillController!.getSelectionStyle();
    final isBold = style.containsKey(Attribute.bold.key);
    final isItalic = style.containsKey(Attribute.italic.key);
    final isUnderline = style.containsKey(Attribute.underline.key);
    final isStrike = style.containsKey(Attribute.strikeThrough.key);
    final isCode = style.containsKey(Attribute.inlineCode.key);

    final isH1 = style.attributes[Attribute.header.key]?.value == 1;
    final isH2 = style.attributes[Attribute.header.key]?.value == 2;
    final isH3 = style.attributes[Attribute.header.key]?.value == 3;
    final isH4 = style.attributes[Attribute.header.key]?.value == 4;
    final isH5 = style.attributes[Attribute.header.key]?.value == 5;
    final isH6 = style.attributes[Attribute.header.key]?.value == 6;
    final isParagraph = style.attributes[Attribute.header.key]?.value == null;

    final alignVal = style.attributes[Attribute.align.key]?.value;
    final isAlignLeft = alignVal == null || alignVal == 'left';
    final isAlignCenter = alignVal == 'center';
    final isAlignRight = alignVal == 'right';
    final isAlignJustify = alignVal == 'justify';

    final listVal = style.attributes[Attribute.list.key]?.value;
    final isBullet = listVal == 'bullet';
    final isOrdered = listVal == 'ordered';
    final isChecklist = listVal == 'checked' || listVal == 'unchecked';
    final isBlockquote = style.containsKey(Attribute.blockQuote.key);
    final isCodeBlock = style.containsKey(Attribute.codeBlock.key);

    Widget subRow() {
      switch (_activeToolbarGroup) {
        case 'format':
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              sub(Icons.format_bold, 'Bold', () {
                widget.quillController!.formatSelection(isBold ? Attribute.clone(Attribute.bold, null) : Attribute.bold);
              }, active: isBold),
              sub(Icons.format_italic, 'Italic', () {
                widget.quillController!.formatSelection(isItalic ? Attribute.clone(Attribute.italic, null) : Attribute.italic);
              }, active: isItalic),
              sub(Icons.format_underlined, 'Underline', () {
                widget.quillController!.formatSelection(isUnderline ? Attribute.clone(Attribute.underline, null) : Attribute.underline);
              }, active: isUnderline),
              sub(Icons.format_strikethrough, 'Strikethrough', () {
                widget.quillController!.formatSelection(isStrike ? Attribute.clone(Attribute.strikeThrough, null) : Attribute.strikeThrough);
              }, active: isStrike),
              sub(Icons.code_rounded, 'Inline Code', () => widget.quillController!.formatSelection(isCode ? Attribute.clone(Attribute.inlineCode, null) : Attribute.inlineCode), active: isCode),
            ],
          );
        case 'color':
          final textColors = [
            const Color(0xFF000000),
            const Color(0xFFEF4444),
            const Color(0xFFF97316),
            const Color(0xFFEAB308),
            const Color(0xFF22C55E),
            const Color(0xFF06B6D4),
            const Color(0xFF3B82F6),
            const Color(0xFF6366F1),
            const Color(0xFF8B5CF6),
            const Color(0xFFEC4899),
            const Color(0xFF6B7280),
            const Color(0xFFFFFFFF),
          ];
          final highlights = [
            const Color(0xFFFFFF00),
            const Color(0xFFADFF2F),
            const Color(0xFF87CEEB),
            const Color(0xFFFFB6C1),
            const Color(0xFFFFD700),
            const Color(0xFFFFA07A),
            const Color(0xFF98FB98),
            const Color(0xFFDDA0DD),
            const Color(0xFFE2E8F0),
            const Color(0xFFFFC0CB),
          ];
          if (_activeColorMode == null) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _activeColorMode = 'text';
                      _showCustomColorPicker = false;
                    });
                    _updateCustomColorPickerFromSelection();
                  },
                  icon: Icon(Icons.format_color_text, color: theme.colorScheme.primary, size: 16),
                  label: Text('Text', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 11)),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _activeColorMode = 'highlight';
                      _showCustomColorPicker = false;
                    });
                    _updateCustomColorPickerFromSelection();
                  },
                  icon: Icon(Icons.highlight, color: theme.colorScheme.primary, size: 16),
                  label: Text('Highlight', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 11)),
                ),
              ],
            );
          } else {
            final colorsToUse = _activeColorMode == 'text' ? textColors : highlights;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() {
                        _activeColorMode = null;
                        _showCustomColorPicker = false;
                      }),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Tooltip(
                              message: 'Clear Color',
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  _applyColor(null);
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.shade400),
                                  ),
                                  child: const Icon(Icons.format_color_reset_rounded, size: 14, color: Colors.red),
                                ),
                              ),
                            ),
                            ...colorsToUse.map((c) {
                              final isSelected = _getCurrentSelectedColor() == c;
                              return GestureDetector(
                                onTap: () {
                                  _applyColor(c);
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : (c == Colors.white ? Colors.grey.shade300 : Colors.transparent),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check,
                                          size: 12,
                                          color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                        )
                                      : null,
                                ),
                              );
                            }),
                            Tooltip(
                              message: 'Custom Color',
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => setState(() {
                                  _showCustomColorPicker = !_showCustomColorPicker;
                                }),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _showCustomColorPicker ? theme.colorScheme.primary : Colors.transparent,
                                    border: Border.all(color: theme.colorScheme.primary),
                                  ),
                                  child: Icon(
                                    Icons.palette_outlined,
                                    size: 14,
                                    color: _showCustomColorPicker
                                        ? Colors.white
                                        : theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_showCustomColorPicker) ...[
                  const Divider(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: _buildInlineCustomColorPicker(theme, isDark),
                  ),
                ],
              ],
            );
          }
        case 'heading':
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                subText('H1', 'Heading 1', () => widget.quillController!.formatSelection(isH1 ? Attribute.clone(Attribute.header, null) : Attribute.h1), active: isH1),
                subText('H2', 'Heading 2', () => widget.quillController!.formatSelection(isH2 ? Attribute.clone(Attribute.header, null) : Attribute.h2), active: isH2),
                subText('H3', 'Heading 3', () => widget.quillController!.formatSelection(isH3 ? Attribute.clone(Attribute.header, null) : Attribute.h3), active: isH3),
                subText('H4', 'Heading 4', () => widget.quillController!.formatSelection(isH4 ? Attribute.clone(Attribute.header, null) : Attribute.h4), active: isH4),
                subText('H5', 'Heading 5', () => widget.quillController!.formatSelection(isH5 ? Attribute.clone(Attribute.header, null) : Attribute.h5), active: isH5),
                subText('H6', 'Heading 6', () => widget.quillController!.formatSelection(isH6 ? Attribute.clone(Attribute.header, null) : Attribute.h6), active: isH6),
                subText('Paragraph', 'Paragraph Text', () => widget.quillController!.formatSelection(Attribute.clone(Attribute.header, null)), active: isParagraph),
              ],
            ),
          );
        case 'align':
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              sub(Icons.format_align_left_rounded, 'Align Left', () => widget.quillController!.formatSelection(Attribute.leftAlignment), active: isAlignLeft),
              sub(Icons.format_align_center_rounded, 'Align Center', () => widget.quillController!.formatSelection(Attribute.centerAlignment), active: isAlignCenter),
              sub(Icons.format_align_right_rounded, 'Align Right', () => widget.quillController!.formatSelection(Attribute.rightAlignment), active: isAlignRight),
              sub(Icons.format_align_justify_rounded, 'Justify', () => widget.quillController!.formatSelection(Attribute.justifyAlignment), active: isAlignJustify),
            ],
          );
        case 'lists':
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              sub(Icons.format_list_bulleted, 'Bullet List', () => widget.quillController!.formatSelection(isBullet ? Attribute.clone(Attribute.list, null) : Attribute.ul), active: isBullet),
              sub(Icons.format_list_numbered, 'Numbered List', () => widget.quillController!.formatSelection(isOrdered ? Attribute.clone(Attribute.list, null) : Attribute.ol), active: isOrdered),
              sub(Icons.check_box_outlined, 'Checklist', () => widget.quillController!.formatSelection(isChecklist ? Attribute.clone(Attribute.list, null) : Attribute.unchecked), active: isChecklist),
              sub(Icons.format_quote_rounded, 'Blockquote', () => widget.quillController!.formatSelection(isBlockquote ? Attribute.clone(Attribute.blockQuote, null) : Attribute.blockQuote), active: isBlockquote),
            ],
          );
        case 'insert':
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                sub(Icons.image_outlined, 'Insert Image', () => _pickImage(context)),
                sub(Icons.horizontal_rule_rounded, 'Divider', () {
                  widget.onInsertBlock(BlockType.horizontalRule);
                }),
                sub(Icons.data_object_rounded, 'Code Block', () => widget.quillController!.formatSelection(isCodeBlock ? Attribute.clone(Attribute.codeBlock, null) : Attribute.codeBlock), active: isCodeBlock),
                sub(Icons.mic_outlined, 'Voice Note', () => _recordAudio(context)),
                sub(Icons.mic_none_outlined, 'Dictation (STT)', widget.onSpeechToggle, active: widget.isSpeechListening),
                sub(Icons.draw_outlined, 'Drawing', () => widget.onInsertBlock(BlockType.drawing)),
              ],
            ),
          );
        case 'indent':
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              sub(Icons.format_indent_increase_rounded, 'Indent', () => widget.quillController!.indentSelection(true)),
              sub(Icons.format_indent_decrease_rounded, 'Outdent', () => widget.quillController!.indentSelection(false)),
              sub(Icons.format_line_spacing_rounded, 'Line Break', () {
                final index = widget.quillController!.selection.baseOffset;
                final insertIndex = index >= 0 ? index : widget.quillController!.document.length - 1;
                final length = widget.quillController!.selection.extentOffset - index;
                widget.quillController!.replaceText(
                  insertIndex,
                  length >= 0 ? length : 0,
                  '\n',
                  TextSelection.collapsed(offset: insertIndex + 1),
                );
              }),
            ],
          );
      }
      return const SizedBox.shrink();
    }

    Widget? previewBanner;
    if (_activeToolbarGroup == 'color' && _activeColorMode != null) {
      final selection = widget.quillController!.selection;
      final hasSelection = selection.baseOffset != selection.extentOffset;
      if (!hasSelection) {
        final previewColor = _getCurrentSelectedColor();
        final isHighlight = _activeColorMode == 'highlight';
        previewBanner = Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1B2C) : const Color(0xFFF3F1FA),
            border: Border(bottom: BorderSide(color: borderCol)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Preview: ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isHighlight ? previewColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'Sample Text',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isHighlight
                        ? (previewColor.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                        : (previewColor == Colors.transparent
                            ? (isDark ? Colors.white : Colors.black)
                            : previewColor),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(Select text to apply)',
                style: TextStyle(
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                ),
              ),
            ],
          ),
        );
      }
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (previewBanner != null) ...[
                        previewBanner,
                        const SizedBox(height: 6),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: subRow(),
                      ),
                    ],
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
                      // Undo / Redo
                      IconButton(
                        icon: Icon(Icons.undo_rounded, size: 20, color: widget.canUndo ? theme.colorScheme.primary : theme.disabledColor),
                        onPressed: widget.canUndo ? widget.onUndo : null,
                        tooltip: 'Undo',
                      ),
                      IconButton(
                        icon: Icon(Icons.redo_rounded, size: 20, color: widget.canRedo ? theme.colorScheme.primary : theme.disabledColor),
                        onPressed: widget.canRedo ? widget.onRedo : null,
                        tooltip: 'Redo',
                      ),
                      const VerticalDivider(width: 16, indent: 12, endIndent: 12),

                      // Group buttons
                      ...groups.map((g) => groupBtn(g.$1, g.$2, g.$3)),

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
      ],
    );
      },
    );
  }
}

