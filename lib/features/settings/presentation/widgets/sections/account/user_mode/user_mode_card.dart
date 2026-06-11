import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../../models/models.dart';
import '../../../../controllers/settings_controller.dart';

class StandardProfileChip extends ConsumerWidget {
  final AppUserMode mode;
  final bool isSelected;

  const StandardProfileChip({
    super.key,
    required this.mode,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ChoiceChip(
      avatar: Icon(
        mode.icon, 
        size: 16, 
        color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
      ),
      label: Text(mode.displayName),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref.read(settingsProvider.notifier).selectProfile(mode.name);
        }
      },
    );
  }
}

class CustomProfileChip extends ConsumerWidget {
  final CustomWorkspaceProfile profile;
  final bool isSelected;
  final VoidCallback onDelete;

  const CustomProfileChip({
    super.key,
    required this.profile,
    required this.isSelected,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return InputChip(
      avatar: Icon(
        Icons.assignment_ind_outlined, 
        size: 14, 
        color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
      ),
      label: Text(profile.name),
      selected: isSelected,
      checkmarkColor: isSelected ? theme.colorScheme.onPrimary : null,
      showCheckmark: false,
      selectedColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      deleteIconColor: isSelected 
          ? theme.colorScheme.onPrimary.withValues(alpha: 0.8) 
          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
      onSelected: (selected) {
        if (selected) {
          ref.read(settingsProvider.notifier).selectProfile(profile.id);
        }
      },
      onDeleted: onDelete,
      deleteIcon: const Icon(Icons.cancel_rounded, size: 16),
    );
  }
}
