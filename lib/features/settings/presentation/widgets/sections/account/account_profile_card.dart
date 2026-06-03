import 'package:flutter/material.dart';
import '../../../../../../models/models.dart';

class AccountProfileCard extends StatelessWidget {
  final CustomWorkspaceProfile? activeCustom;
  final AppUserMode userMode;

  const AccountProfileCard({
    super.key,
    required this.activeCustom,
    required this.userMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final custom = activeCustom;

    return Row(
      children: [
        Icon(
          custom != null ? Icons.settings_suggest_outlined : userMode.icon,
          color: theme.colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active Workspace: ${custom != null ? custom.name : userMode.displayName}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                custom != null
                    ? '${custom.isAdvanced ? "Advanced" : "Simple"} custom profile configuration.'
                    : userMode.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
