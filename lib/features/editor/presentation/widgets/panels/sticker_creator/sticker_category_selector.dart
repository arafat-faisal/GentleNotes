import 'package:flutter/material.dart';

class StickerCategorySelector extends StatelessWidget {
  final TabController tabController;
  final bool isDark;

  const StickerCategorySelector({
    super.key,
    required this.tabController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1829) : const Color(0xFFF3F1FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: tabController,
        indicator: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(text: 'Doodle'),
          Tab(text: 'Text Card'),
          Tab(text: 'Photo Mask'),
        ],
      ),
    );
  }
}
