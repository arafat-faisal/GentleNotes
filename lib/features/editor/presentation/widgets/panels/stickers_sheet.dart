import 'package:flutter/material.dart';
import 'sticker_creator_sheet.dart';

class StickersSheet extends StatelessWidget {
  final Function(String stickerName) onSelect;

  const StickersSheet({
    super.key,
    required this.onSelect,
  });

  static const List<Map<String, String>> stickers = [
    {'name': 'cat', 'title': 'Cute Cat'},
    {'name': 'coffee', 'title': 'Happy Coffee'},
    {'name': 'idea', 'title': 'Bright Idea'},
    {'name': 'star', 'title': 'Happy Star'},
    {'name': 'cloud', 'title': 'Calm Cloud'},
    {'name': 'heart', 'title': 'Lovely Heart'},
    {'name': 'fire', 'title': 'Hot Fire'},
    {'name': 'sun', 'title': 'Sunny Day'},
    {'name': 'target', 'title': 'Aim Target'},
  ];

  void _showStickerCreatorDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StickerCreatorSheet(
        onSelect: onSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF13111C) : Colors.white;
    final borderColor = isDark ? const Color(0xFF252234) : const Color(0xFFE9E6F5);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pull handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3D3557) : const Color(0xFFD1CBE8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Insert Sticker',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: stickers.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showStickerCreatorDialog(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.all(8),
                      width: 110,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1B2C)
                            : const Color(0xFFF3F1FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2E2845).withValues(alpha: 0.5)
                              : const Color(0xFFE3DCF5).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2E2845)
                                  : const Color(0xFFE3DCF5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              size: 28,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Create Custom',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final sticker = stickers[index - 1];
                final name = sticker['name']!;
                final title = sticker['title']!;

                return GestureDetector(
                  onTap: () {
                    onSelect(name);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.all(8),
                    width: 110,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1B2C)
                          : const Color(0xFFF3F1FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2E2845).withValues(alpha: 0.5)
                            : const Color(0xFFE3DCF5).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Hero(
                            tag: 'picker_sticker_$name',
                            child: Image.asset(
                              'assets/images/stickers/$name.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
