import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_action_delegate.dart';

class QuickActionsBar extends ConsumerWidget {
  const QuickActionsBar({super.key});

  Widget _buildQuickAction(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final delegate = ref.watch(homeActionDelegateProvider);

    return Card(
      elevation: 0,
      color: theme.colorScheme.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickAction(
                context,
                'Add Folder',
                Icons.create_new_folder_outlined,
                () => delegate.onFolderCreate(context),
              ),
              const SizedBox(width: 8),
              _buildQuickAction(
                context,
                'Import JSON',
                Icons.file_present_outlined,
                () => delegate.onImportBackup(context, ref),
              ),
              const SizedBox(width: 8),
              _buildQuickAction(
                context,
                'Templates',
                Icons.copy_all_outlined,
                () => delegate.onTemplatesTap(context),
              ),
              const SizedBox(width: 8),
              _buildQuickAction(
                context,
                'Calendar',
                Icons.calendar_month_outlined,
                () => delegate.onCalendarTap(context),
              ),
              const SizedBox(width: 8),
              _buildQuickAction(
                context,
                'Settings',
                Icons.tune,
                () => delegate.onSettingsTap(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
