import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class ColorPickerGroup extends StatefulWidget {
  final QuillController quillController;
  final Color accentColor;

  const ColorPickerGroup({
    super.key,
    required this.quillController,
    required this.accentColor,
  });

  @override
  State<ColorPickerGroup> createState() => _ColorPickerGroupState();
}

class _ColorPickerGroupState extends State<ColorPickerGroup> {
  String? _activeColorMode;
  bool _showCustomColorPicker = false;
  double _customHue = 0.0;
  double _customSaturation = 1.0;
  double _customLightness = 0.5;
  Color _customSelectedColor = const Color(0xFFEF4444);
  final List<Color> _userSavedColors = [];

  Color _getCurrentSelectedColor() {
    final style = widget.quillController.getSelectionStyle();
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
    final hexStr = color != null
        ? '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}'
        : null;

    if (_activeColorMode == 'text') {
      widget.quillController.formatSelection(ColorAttribute(hexStr));
    } else if (_activeColorMode == 'highlight') {
      widget.quillController.formatSelection(BackgroundAttribute(hexStr));
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
              data: const SliderThemeData(
                trackHeight: 10,
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
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
    final hexStr = '#${_customSelectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    
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
                              color: isSelected ? widget.accentColor : Colors.grey.shade400,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
    }

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
}
