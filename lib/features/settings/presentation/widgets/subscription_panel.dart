import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/models.dart';
import '../controllers/settings_controller.dart';

class SubscriptionPanel extends ConsumerWidget {
  final UserRole activeRole;
  const SubscriptionPanel({super.key, required this.activeRole});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    String description = '';
    switch (activeRole) {
      case UserRole.admin:
        description = 'Full Administrator privileges active. You can sync notes, publish default templates, and moderate workspaces.';
        break;
      case UserRole.subscriber:
        description = 'Premium Subscription active! Unlimited local database storage, Markdown Exports, and ready to connect to cloud syncing.';
        break;
      case UserRole.freeUser:
        description = 'Free account active. Storing notes locally. Subscribed web account is needed for cross-device database syncing.';
        break;
      case UserRole.guest:
        description = 'Guest session active. Offline workspace is locked to temporary application cache.';
        break;
    }

    return Card(
      elevation: 0,
      color: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.verified_user_rounded, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Subscription Role',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Configure role to test interface states',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 105,
                  child: DropdownButton<UserRole>(
                    isExpanded: true,
                    value: activeRole,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down_rounded),
                    items: UserRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(
                          role.displayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            fontFamily: 'Inter',
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(userRoleProvider.notifier).updateRole(val);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ready for subscription website connections in future phases.',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.blueGrey.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
