import 'package:flutter/material.dart';

class AccountPrivacyNote extends StatelessWidget {
  const AccountPrivacyNote({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'GentleNotes is offline-first. Your workspace data, custom profiles, and drawings are stored safely on this device.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
