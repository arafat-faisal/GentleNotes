import 'package:flutter/material.dart';

class StickerTextInput extends StatelessWidget {
  final String cardText;
  final ValueChanged<String> onTextChanged;
  final Color cardTextColor;
  final ValueChanged<Color> onTextColorChanged;

  const StickerTextInput({
    super.key,
    required this.cardText,
    required this.onTextChanged,
    required this.cardTextColor,
    required this.onTextColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'Sticker Text',
            hintText: 'Enter typography text...',
            prefixIcon: const Icon(Icons.text_fields),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          maxLength: 32,
          onChanged: onTextChanged,
          controller: TextEditingController(text: cardText)..selection = TextSelection.fromPosition(TextPosition(offset: cardText.length)),
        ),
        const SizedBox(height: 12),
        const Text('Text Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            _colorCircle(context, Colors.white, 'White'),
            _colorCircle(context, Colors.black, 'Black'),
            _colorCircle(context, const Color(0xFFFACC15), 'Yellow'),
            _colorCircle(context, const Color(0xFFF43F5E), 'Red'),
            _colorCircle(context, const Color(0xFF60A5FA), 'Blue'),
          ],
        ),
      ],
    );
  }

  Widget _colorCircle(BuildContext context, Color color, String tooltip) {
    final isSelected = cardTextColor == color;
    return GestureDetector(
      onTap: () => onTextColorChanged(color),
      child: Tooltip(
        message: tooltip,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : (color == Colors.white ? Colors.grey.shade300 : Colors.transparent),
              width: isSelected ? 3 : 1,
            ),
          ),
          child: isSelected
              ? Icon(
                  Icons.check,
                  size: 16,
                  color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}
