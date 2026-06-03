import 'package:flutter/material.dart';
import 'sticker_creator_controller.dart';

class StickerColorControls extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final bool showGradients;
  final int selectedGradientIndex;
  final ValueChanged<int> onGradientSelected;

  const StickerColorControls({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.showGradients = false,
    this.selectedGradientIndex = 0,
    required this.onGradientSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (showGradients) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Background Style', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: StickerCreatorController.cardGradients.length,
              itemBuilder: (context, index) {
                final grad = StickerCreatorController.cardGradients[index];
                final isSelected = selectedGradientIndex == index;
                final hasGrad = grad.length > 1;

                return GestureDetector(
                  onTap: () => onGradientSelected(index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 70,
                    decoration: BoxDecoration(
                      color: hasGrad ? null : grad.first,
                      gradient: hasGrad ? LinearGradient(colors: grad) : null,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
                        width: isSelected ? 3.0 : 1.0,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check_circle_outline,
                            color: grad.first.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: StickerCreatorController.curatedColors.length,
        itemBuilder: (context, index) {
          final c = StickerCreatorController.curatedColors[index];
          final isSelected = selectedColor == c;

          return GestureDetector(
            onTap: () => onColorSelected(c),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (c == Colors.white ? Colors.grey.shade300 : Colors.transparent),
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 14,
                      color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
