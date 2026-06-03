import 'package:flutter/material.dart';

class StickerGrid extends StatelessWidget {
  final VoidCallback onPickPhoto;
  final String photoPath;
  final String photoMask;
  final ValueChanged<String> onMaskSelected;
  final double photoBorderWidth;
  final ValueChanged<double> onBorderWidthChanged;
  final Color photoBorderColor;
  final ValueChanged<Color> onBorderColorChanged;

  const StickerGrid({
    super.key,
    required this.onPickPhoto,
    required this.photoPath,
    required this.photoMask,
    required this.onMaskSelected,
    required this.photoBorderWidth,
    required this.onBorderWidthChanged,
    required this.photoBorderColor,
    required this.onBorderColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: const Icon(Icons.image_search_rounded),
          label: Text(photoPath.isEmpty ? 'Select Photo from Gallery' : 'Change Photo'),
          onPressed: onPickPhoto,
        ),
        const SizedBox(height: 20),

        const Text('Cutout Shape Mask', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _maskBtn(context, 'original', Icons.crop_original_rounded, 'Original'),
            _maskBtn(context, 'circle', Icons.circle_outlined, 'Circle'),
            _maskBtn(context, 'rrect', Icons.rounded_corner_rounded, 'RRect'),
            _maskBtn(context, 'heart', Icons.favorite_border_rounded, 'Heart'),
            _maskBtn(context, 'star', Icons.star_border_rounded, 'Star'),
          ],
        ),
        const SizedBox(height: 20),

        const Text('Sticker Border Style', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        Slider(
          value: photoBorderWidth,
          min: 0.0,
          max: 10.0,
          divisions: 10,
          label: 'Border: ${photoBorderWidth.toInt()}px',
          onChanged: onBorderWidthChanged,
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _borderColorCircle(context, const Color(0xFF8B5CF6), 'Purple'),
            _borderColorCircle(context, const Color(0xFFEF4444), 'Red'),
            _borderColorCircle(context, const Color(0xFF10B981), 'Green'),
            _borderColorCircle(context, const Color(0xFFFACC15), 'Yellow'),
            _borderColorCircle(context, Colors.white, 'White'),
            _borderColorCircle(context, Colors.black, 'Black'),
          ],
        ),
      ],
    );
  }

  Widget _maskBtn(BuildContext context, String shape, IconData icon, String label) {
    final isSelected = photoMask == shape;
    final theme = Theme.of(context);

    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: isSelected ? theme.colorScheme.primary : Colors.grey),
          onPressed: () => onMaskSelected(shape),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: isSelected ? theme.colorScheme.primary : Colors.grey)),
      ],
    );
  }

  Widget _borderColorCircle(BuildContext context, Color color, String tooltip) {
    final isSelected = photoBorderColor == color;
    return GestureDetector(
      onTap: () => onBorderColorChanged(color),
      child: Tooltip(
        message: tooltip,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 26,
          height: 26,
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
        ),
      ),
    );
  }
}
