import 'package:flutter/material.dart';

class ToolbarGroupButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color accentColor;

  const ToolbarGroupButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? accentColor.withValues(alpha: 0.12) : Colors.transparent,
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
                color: isActive ? accentColor : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ToolbarActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isActive;
  final Color accentColor;

  const ToolbarActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isActive = false,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? accentColor.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: isActive ? accentColor : theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}

class ToolbarTextButton extends StatelessWidget {
  final String text;
  final String tooltip;
  final VoidCallback onTap;
  final bool isActive;
  final Color accentColor;

  const ToolbarTextButton({
    super.key,
    required this.text,
    required this.tooltip,
    required this.onTap,
    this.isActive = false,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? accentColor.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isActive ? accentColor : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
