import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/gentle_scaffold.dart';
import 'controllers/settings_controller.dart';
import 'widgets/backup_sync_panel.dart';
import 'widgets/editor_layout_picker.dart';
import 'widgets/editor_preferences_panel.dart';
import 'widgets/subscription_panel.dart';
import 'widgets/theme_mode_toggle.dart';
import 'widgets/theme_preset_picker.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final userRole = ref.watch(userRoleProvider);

    return GentleScaffold(
      title: 'App Settings',
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. Subscription & Account Section
          SubscriptionPanel(activeRole: userRole),
          const SizedBox(height: 24),

          // 2. Personalization Theme
          _buildSectionHeader(context, 'Personalization'),
          const SizedBox(height: 8),
          ThemeModeToggle(settings: settings),
          const SizedBox(height: 24),

          // 3. Aesthetic Theme Preset
          _buildSectionHeader(context, 'Aesthetic Theme'),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Each theme is a full app skin — it sets colours for every element in both Light and Dark mode.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ThemePresetPicker(settings: settings),
          const SizedBox(height: 24),

          // 4. Editor Layout Variant Selector
          _buildSectionHeader(context, 'Editor Layout'),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Choose the visual layout style for the note editor',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          EditorLayoutPicker(settings: settings),
          const SizedBox(height: 24),

          // 5. Editor Preferences
          _buildSectionHeader(context, 'Editor Preferences'),
          const SizedBox(height: 8),
          EditorPreferencesPanel(settings: settings),
          const SizedBox(height: 24),

          // 6. Backup & Cloud Sync
          _buildSectionHeader(context, 'Backup & Cloud Sync'),
          const SizedBox(height: 8),
          BackupSyncPanel(userRole: userRole),
          const SizedBox(height: 24),

          // 7. About App Link
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About Gentle Notes'),
            subtitle: const Text('V1.0.0 (MVP Build)'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/about'),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
