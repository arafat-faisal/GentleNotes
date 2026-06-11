import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/settings_controller.dart';
import 'account/account_action_buttons.dart';
import 'account/account_privacy_note.dart';
import 'account/account_profile_card.dart';
import 'account/storage_status_card.dart';
import 'account/subscription_status_card.dart';
import 'account/user_mode/user_mode_selector.dart';

class AccountSettingsSection extends ConsumerWidget {
  const AccountSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final userRole = ref.watch(userRoleProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        SubscriptionStatusCard(activeRole: userRole),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          color: theme.cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccountProfileCard(
                  activeCustom: settings.activeCustomProfile,
                  userMode: settings.userMode,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const UserModeSelector(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const StorageStatusCard(),
        const SizedBox(height: 24),
        const AccountActionButtons(),
        const SizedBox(height: 24),
        const AccountPrivacyNote(),
        const SizedBox(height: 16),
      ],
    );
  }
}
