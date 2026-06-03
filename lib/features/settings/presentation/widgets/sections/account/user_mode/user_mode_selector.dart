import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../../models/models.dart';
import '../../../../controllers/settings_controller.dart';
import 'user_mode_card.dart';
import 'user_mode_description.dart';
import 'user_mode_actions.dart';

class UserModeSelector extends ConsumerWidget {
  const UserModeSelector({super.key});

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, CustomWorkspaceProfile profile) {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmDialog(profile: profile),
    );
  }

  void _showCreateProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateProfileDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final activeCustom = settings.activeCustomProfile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Workspace Profile',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...AppUserMode.values.where((m) => m != AppUserMode.custom).map((mode) {
              final isSelected = settings.activeProfileId == mode.name;
              return StandardProfileChip(
                mode: mode,
                isSelected: isSelected,
              );
            }),
          ],
        ),
        
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Saved Profiles',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showCreateProfileDialog(context),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('New Profile', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (settings.customProfiles.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: UserModeDescription(
              text: 'No custom profiles saved yet. Click "New Profile" to create one!',
              isItalic: true,
              opacity: 0.4,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: settings.customProfiles.map((profile) {
              final isSelected = settings.activeProfileId == profile.id;
              return CustomProfileChip(
                profile: profile,
                isSelected: isSelected,
                onDelete: () => _showDeleteConfirmDialog(context, ref, profile),
              );
            }).toList(),
          ),

        if (activeCustom != null) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Active Profile Customization Depth',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Simple Mode'),
                selected: !activeCustom.isAdvanced,
                onSelected: (selected) {
                  if (selected) {
                    final updated = activeCustom.copyWith(isAdvanced: false);
                    ref.read(settingsProvider.notifier).saveCustomProfile(updated);
                    ref.read(settingsProvider.notifier).selectProfile(updated.id);
                  }
                },
              ),
              ChoiceChip(
                label: const Text('Advanced Mode'),
                selected: activeCustom.isAdvanced,
                onSelected: (selected) {
                  if (selected) {
                    final updated = activeCustom.copyWith(isAdvanced: true);
                    ref.read(settingsProvider.notifier).saveCustomProfile(updated);
                    ref.read(settingsProvider.notifier).selectProfile(updated.id);
                  }
                },
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Profile Customization Depth',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Simple Mode'),
                selected: !settings.isAdvancedMode,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(settingsProvider.notifier).updateIsAdvancedMode(false);
                  }
                },
              ),
              ChoiceChip(
                label: const Text('Advanced Mode'),
                selected: settings.isAdvancedMode,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(settingsProvider.notifier).updateIsAdvancedMode(true);
                  }
                },
              ),
            ],
          ),
        ],
      ],
    );
  }
}
