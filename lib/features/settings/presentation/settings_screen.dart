import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/widgets/gentle_scaffold.dart';
import '../../../models/models.dart';
import '../data/settings_repository.dart';
import '../../../app/theme/theme_models.dart';
import '../../../services/export_import_service.dart';
import '../../notes/data/notes_repository.dart';
import '../../folders/data/folders_repository.dart';

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
          // 1. Subscription & Account Section (Premium Design)
          _buildSubscriptionPanel(context, ref, userRole),
          const SizedBox(height: 24),

          // 2. Personalization Theme Header
          _buildSectionHeader(context, 'Personalization'),
          const SizedBox(height: 8),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  // Theme Selector Row
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Theme Mode'),
                    subtitle: Text(settings.themeMode.name.toUpperCase()),
                    trailing: DropdownButton<ThemeModeSetting>(
                      value: settings.themeMode,
                      items: ThemeModeSetting.values.map((mode) {
                        return DropdownMenuItem(
                          value: mode,
                          child: Text(mode.name.toUpperCase(), style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(settingsProvider.notifier).updateThemeMode(val);
                        }
                      },
                    ),
                  ),
                  const Divider(indent: 16, endIndent: 16),

                  // Accent Colors Selector
                  ListTile(
                    leading: const Icon(Icons.color_lens_outlined),
                    title: const Text('Accent Accent Color'),
                    subtitle: Text(
                      kAccentColors.firstWhere((c) => c.hex.toLowerCase() == settings.accentColorHex.toLowerCase(), orElse: () => kAccentColors.first).name,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: SizedBox(
                      height: 48,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: kAccentColors.length,
                        itemBuilder: (context, index) {
                          final customColor = kAccentColors[index];
                          final isSelected = settings.accentColorHex.toLowerCase() == customColor.hex.toLowerCase();
                          return GestureDetector(
                            onTap: () {
                              ref.read(settingsProvider.notifier).updateAccentColor(customColor.hex);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: customColor.color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: theme.colorScheme.onBackground, width: 2.5)
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: customColor.color.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 3. Editor settings
          _buildSectionHeader(context, 'Editor Preferences'),
          const SizedBox(height: 8),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                // Default Note Type
                ListTile(
                  leading: const Icon(Icons.notes_outlined),
                  title: const Text('Default Note Type'),
                  trailing: DropdownButton<NoteType>(
                    value: settings.defaultNoteType,
                    items: NoteType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(settingsProvider.notifier).updateDefaultNoteType(val);
                      }
                    },
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),

                // Code Preview Theme Selector
                ListTile(
                  leading: const Icon(Icons.code_rounded),
                  title: const Text('Code Preview Theme'),
                  subtitle: const Text('Select visual syntax highlight theme'),
                  trailing: DropdownButton<String>(
                    value: settings.activeCodeTheme,
                    items: const [
                      DropdownMenuItem(value: 'vs-dark', child: Text('VS Code Dark', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'vs-light', child: Text('VS Code Light', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'monokai', child: Text('Monokai', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'github', child: Text('GitHub Light', style: TextStyle(fontSize: 13))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(settingsProvider.notifier).updateActiveCodeTheme(val);
                      }
                    },
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),

                // Auto Save Toggle
                SwitchListTile(
                  secondary: const Icon(Icons.sync),
                  title: const Text('Auto-save Drafts'),
                  subtitle: const Text('Saves edits automatically every 4 seconds'),
                  value: settings.autoSaveEnabled,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).toggleAutoSave(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. Backups Data Section
          _buildSectionHeader(context, 'Backup & Cloud Sync'),
          const SizedBox(height: 8),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined),
                  title: const Text('Cloud Sync State'),
                  subtitle: Text(
                    userRole == UserRole.subscriber || userRole == UserRole.admin
                        ? 'Connected. (Subscribed User Workspace Demo)'
                        : 'Offline Mode. Connect your subscription to sync.',
                  ),
                  trailing: userRole == UserRole.subscriber || userRole == UserRole.admin
                      ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
                      : const Icon(Icons.cloud_off, color: Colors.grey),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.download_rounded, color: Colors.indigo),
                  title: const Text('Import Backup File'),
                  subtitle: const Text('Load full JSON backup database or raw text notes'),
                  onTap: () => _handleImportBackup(context, ref),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.upload_rounded, color: Colors.indigo),
                  title: const Text('Export Backup File'),
                  subtitle: const Text('Save entire folders, templates, and notes as JSON'),
                  onTap: () => _handleExportBackup(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 5. About app link
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

  Widget _buildSubscriptionPanel(BuildContext context, WidgetRef ref, UserRole activeRole) {
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
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
                
                // Dropdown to switch mock roles
                DropdownButton<UserRole>(
                  value: activeRole,
                  underline: const SizedBox(),
                  items: UserRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(userRoleProvider.notifier).updateRole(val);
                    }
                  },
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
            
            // Helpful connection notice
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

  // --- ACTING HANDLERS ---

  Future<void> _handleExportBackup(BuildContext context) async {
    final jsonStr = ExportImportService().exportBackupAsJson();
    await Share.share(jsonStr, subject: 'GentleNotes_Backup_${DateTime.now().millisecondsSinceEpoch}.json');
  }

  Future<void> _handleImportBackup(BuildContext context, WidgetRef ref) async {
    final success = await ExportImportService().pickAndImportFile();
    if (success) {
      // Reload repos
      ref.read(foldersProvider.notifier).loadFolders();
      ref.read(notesProvider.notifier).loadNotes();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup restored successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to restore backup or cancelled.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
