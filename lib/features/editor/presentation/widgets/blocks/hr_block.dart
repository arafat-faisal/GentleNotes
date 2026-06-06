import 'package:flutter/material.dart';
import '../../../domain/entities/block_entity.dart';

class HrBlock extends StatelessWidget {
  final BlockEntity block;
  final VoidCallback onRemoved;
  final bool readOnly;

  const HrBlock({
    super.key,
    required this.block,
    required this.onRemoved,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
      child: MouseRegion(
        cursor: readOnly ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: readOnly ? null : () {
            // Show a quick tooltip/dialog or tap to delete directly
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [
                    Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 22),
                    SizedBox(width: 8),
                    Text('Remove Divider', style: TextStyle(fontSize: 16)),
                  ],
                ),
                content: const Text('Delete this horizontal rule divider?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: () {
                      Navigator.pop(ctx);
                      onRemoved();
                    },
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Divider(
                color: isDark ? const Color(0xFF252234) : const Color(0xFFE9E6F5),
                thickness: 1.5,
              ),
              Positioned(
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF13111C) : Colors.white,
                    border: Border.all(
                      color: isDark ? const Color(0xFF252234) : const Color(0xFFE9E6F5),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Divider',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: theme.hintColor,
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
