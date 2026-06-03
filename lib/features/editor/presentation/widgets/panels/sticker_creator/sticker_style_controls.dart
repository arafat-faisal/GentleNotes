import 'package:flutter/material.dart';

class StickerStyleControls extends StatelessWidget {
  final double cornerRadius;
  final double borderWidth;
  final ValueChanged<double> onCornerRadiusChanged;
  final ValueChanged<double> onBorderWidthChanged;

  const StickerStyleControls({
    super.key,
    required this.cornerRadius,
    required this.borderWidth,
    required this.onCornerRadiusChanged,
    required this.onBorderWidthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Corner Radius', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              Slider(
                value: cornerRadius,
                min: 0.0,
                max: 48.0,
                divisions: 12,
                label: cornerRadius.toInt().toString(),
                onChanged: onCornerRadiusChanged,
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Border Width', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              Slider(
                value: borderWidth,
                min: 0.0,
                max: 6.0,
                divisions: 6,
                label: borderWidth.toInt().toString(),
                onChanged: onBorderWidthChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
