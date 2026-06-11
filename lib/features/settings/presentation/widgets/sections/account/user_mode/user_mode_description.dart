import 'package:flutter/material.dart';

class UserModeDescription extends StatelessWidget {
  final String text;
  final bool isItalic;
  final double opacity;

  const UserModeDescription({
    super.key,
    required this.text,
    this.isItalic = false,
    this.opacity = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: opacity),
        fontStyle: isItalic ? FontStyle.italic : null,
      ),
    );
  }
}
