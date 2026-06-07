import 'package:flutter/material.dart';
import '../../../domain/entities/block_entity.dart';

class StickerBlock extends StatelessWidget {
  final BlockEntity block;
  final VoidCallback onRemoved;
  final bool readOnly;

  const StickerBlock({
    super.key,
    required this.block,
    required this.onRemoved,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final stickerName = block.content;
    if (stickerName.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF252234) : const Color(0xFFE9E6F5),
                    width: 1,
                  ),
                  color: isDark ? const Color(0xFF1B1826) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/stickers/$stickerName.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.sticky_note_2_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
              ),
              if (!readOnly)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Material(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        onRemoved();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6.0),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
