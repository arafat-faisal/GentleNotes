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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.brightness_6_rounded,
                          size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Theme Mode',
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildThemeModeToggle(context, ref, settings),
                ],
              ),
            ),
          ),
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
          _buildThemePresetPicker(context, ref, settings),
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
          _buildLayoutVariantPicker(context, ref, settings),
          const SizedBox(height: 24),

          // 4. Editor settings
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

          // 5. Backups Data Section
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

          // 6. About app link
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

  // ── Theme Mode Toggle ──────────────────────────────────────────────────────

  Widget _buildThemeModeToggle(
      BuildContext context, WidgetRef ref, AppSettingsModel settings) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    const modes = [
      (mode: ThemeModeSetting.light, icon: Icons.wb_sunny_rounded, label: 'Light'),
      (mode: ThemeModeSetting.system, icon: Icons.phone_android_rounded, label: 'Device'),
      (mode: ThemeModeSetting.dark, icon: Icons.nightlight_round, label: 'Dark'),
    ];

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Row(
        children: modes.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final isSelected = settings.themeMode == item.mode;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(settingsProvider.notifier).updateThemeMode(item.mode);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isSelected ? primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSelected
                      ? [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: 14,
                      color: isSelected
                          ? (theme.brightness == Brightness.dark ? Colors.black : Colors.white)
                          : theme.colorScheme.onSurface.withOpacity(0.55),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? (theme.brightness == Brightness.dark ? Colors.black : Colors.white)
                            : theme.colorScheme.onSurface.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Aesthetic Theme Preset Picker ─────────────────────────────────────────

  Widget _buildThemePresetPicker(
      BuildContext context, WidgetRef ref, AppSettingsModel settings) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final presets = AppThemePreset.values;

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        itemBuilder: (context, index) {
          final preset = presets[index];
          final isSelected = settings.themePreset == preset;
          final swatches = preset.swatchColors;
          final accentSwatch = swatches[0];

          return GestureDetector(
            onTap: () {
              ref.read(settingsProvider.notifier).updateThemePreset(preset);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 110,
              margin: EdgeInsets.only(
                left: index == 0 ? 8 : 6,
                right: index == presets.length - 1 ? 8 : 6,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? accentSwatch : theme.colorScheme.outlineVariant.withOpacity(0.4),
                  width: isSelected ? 2.5 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: accentSwatch.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))]
                    : null,
                color: isDark
                    ? (isSelected ? accentSwatch.withOpacity(0.1) : const Color(0xFF1C1829))
                    : (isSelected ? accentSwatch.withOpacity(0.06) : Colors.white),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Swatch row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: swatches
                        .map((c) => Container(
                              width: 18,
                              height: 18,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.3), width: 1),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  // Emoji
                  Text(preset.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 4),
                  // Name
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      preset.displayName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? accentSwatch : theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Icon(Icons.check_circle_rounded, size: 13, color: accentSwatch),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Layout Variant Picker ─────────────────────────────────────────────────

  Widget _buildLayoutVariantPicker(
      BuildContext context, WidgetRef ref, AppSettingsModel settings) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final variants = [
      (
        variant: EditorLayoutVariant.classic,
        icon: Icons.view_agenda_outlined,
        previewBuilder: (bool dark) => _LayoutPreviewClassic(isDark: dark),
      ),
      (
        variant: EditorLayoutVariant.minimal,
        icon: Icons.article_outlined,
        previewBuilder: (bool dark) => _LayoutPreviewMinimal(isDark: dark),
      ),
      (
        variant: EditorLayoutVariant.notebook,
        icon: Icons.menu_book_outlined,
        previewBuilder: (bool dark) => _LayoutPreviewNotebook(isDark: dark),
      ),
      (
        variant: EditorLayoutVariant.zen,
        icon: Icons.self_improvement_rounded,
        previewBuilder: (bool dark) => _LayoutPreviewZen(isDark: dark),
      ),
      (
        variant: EditorLayoutVariant.cards,
        icon: Icons.style_rounded,
        previewBuilder: (bool dark) => _LayoutPreviewCards(isDark: dark),
      ),
      (
        variant: EditorLayoutVariant.journal,
        icon: Icons.edit_note_rounded,
        previewBuilder: (bool dark) => _LayoutPreviewJournal(isDark: dark),
      ),
      (
        variant: EditorLayoutVariant.scrapbook,
        icon: Icons.dashboard_customize_outlined,
        previewBuilder: (bool dark) => _LayoutPreviewScrapbook(isDark: dark),
      ),
      (
        variant: EditorLayoutVariant.petal,
        icon: Icons.local_florist_outlined,
        previewBuilder: (bool dark) => _LayoutPreviewPetal(isDark: dark),
      ),
      (
        variant: EditorLayoutVariant.stardust,
        icon: Icons.auto_awesome_rounded,
        previewBuilder: (bool dark) => _LayoutPreviewStardust(isDark: dark),
      ),
    ];

    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: variants.length,
        itemBuilder: (context, index) {
          final item = variants[index];
          final isSelected = settings.editorLayout == item.variant;
          final accentColor = theme.colorScheme.primary;

          return GestureDetector(
            onTap: () {
              ref.read(settingsProvider.notifier).updateEditorLayout(item.variant);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 130,
              margin: EdgeInsets.only(
                left: index == 0 ? 8 : 6,
                right: index == variants.length - 1 ? 8 : 6,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? accentColor : theme.colorScheme.outlineVariant.withOpacity(0.4),
                  width: isSelected ? 2.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accentColor.withOpacity(0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
                color: isDark
                    ? (isSelected ? accentColor.withOpacity(0.08) : const Color(0xFF1C1829))
                    : (isSelected ? accentColor.withOpacity(0.05) : Colors.white),
              ),
              child: Column(
                children: [
                  // Mini preview thumbnail
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      child: item.previewBuilder(isDark),
                    ),
                  ),
                  // Label row
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: isSelected
                              ? accentColor.withOpacity(0.3)
                              : theme.colorScheme.outlineVariant.withOpacity(0.2),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.variant.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? accentColor : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, size: 16, color: accentColor)
                        else
                          Icon(Icons.circle_outlined, size: 16,
                              color: theme.colorScheme.onSurface.withOpacity(0.3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────────────────

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

// ── Layout Preview Thumbnails ──────────────────────────────────────────────

class _LayoutPreviewClassic extends StatelessWidget {
  final bool isDark;
  const _LayoutPreviewClassic({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF13111C) : const Color(0xFFFAF9FF);
    final bar = isDark ? const Color(0xFF1E1B2C) : Colors.white;
    final line = isDark ? const Color(0xFF2E2845) : const Color(0xFFE8E4F5);
    final accent = Theme.of(context).colorScheme.primary;
    final textMuted = isDark ? const Color(0xFF4A4370) : const Color(0xFFD1CBE8);
    final textMain = isDark ? const Color(0xFFCCC7E0) : const Color(0xFF3D3557);

    return Container(
      color: bg,
      child: Column(
        children: [
          // AppBar
          Container(
            height: 28,
            color: bar,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(Icons.arrow_back_ios_new_rounded, size: 8, color: accent),
                const SizedBox(width: 4),
                Expanded(child: Container(height: 6, decoration: BoxDecoration(color: textMain, borderRadius: BorderRadius.circular(3)))),
                const SizedBox(width: 4),
                Container(width: 8, height: 8, decoration: BoxDecoration(color: accent.withOpacity(0.5), shape: BoxShape.circle)),
              ],
            ),
          ),
          Container(height: 1, color: line),
          // Metadata bar
          Container(
            height: 18,
            color: bar,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _pill(accent.withOpacity(0.15), accent, 28),
                const SizedBox(width: 4),
                _pill(accent.withOpacity(0.15), accent, 22),
                const SizedBox(width: 4),
                _colorDots(),
              ],
            ),
          ),
          Container(height: 1, color: line),
          // Editor area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _line(textMain, 0.7),
                  const SizedBox(height: 4),
                  _line(textMuted, 0.5),
                  const SizedBox(height: 3),
                  _line(textMuted, 0.65),
                  const SizedBox(height: 3),
                  _line(textMuted, 0.4),
                ],
              ),
            ),
          ),
          // Tags bar
          Container(height: 1, color: line),
          Container(
            height: 16,
            color: bar,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(Icons.local_offer_outlined, size: 8, color: accent),
                const SizedBox(width: 4),
                Container(height: 5, width: 50, decoration: BoxDecoration(color: textMuted, borderRadius: BorderRadius.circular(2))),
              ],
            ),
          ),
          // Toolbar
          Container(height: 1, color: line),
          Container(
            height: 22,
            color: bar,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (i) => Icon(Icons.circle, size: 6, color: accent.withOpacity(0.5))),
            ),
          ),
        ],
      ),
    );
  }
}

class _LayoutPreviewMinimal extends StatelessWidget {
  final bool isDark;
  const _LayoutPreviewMinimal({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0D0B18) : const Color(0xFFFBFAFF);
    final line = isDark ? const Color(0xFF252234) : const Color(0xFFEEEBFF);
    final accent = Theme.of(context).colorScheme.primary;
    final textMuted = isDark ? const Color(0xFF4A4370) : const Color(0xFFD1CBE8);
    final textMain = isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF1A1A2E);

    return Container(
      color: bg,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row back + menu
          Row(
            children: [
              Icon(Icons.arrow_back_ios_new_rounded, size: 8, color: accent),
              const Spacer(),
              Icon(Icons.more_vert, size: 8, color: textMuted),
            ],
          ),
          const SizedBox(height: 8),
          // Big inline title
          Container(height: 10, width: 80, decoration: BoxDecoration(color: textMain, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 4),
          Container(height: 1, color: line),
          const SizedBox(height: 8),
          // Body lines
          _line(textMuted, 0.9),
          const SizedBox(height: 4),
          _line(textMuted, 0.7),
          const SizedBox(height: 4),
          _line(textMuted, 0.55),
          const Spacer(),
          // Floating compact toolbar
          Align(
            alignment: Alignment.center,
            child: Container(
              height: 16,
              width: 80,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (i) => Container(width: 5, height: 5, decoration: BoxDecoration(color: accent.withOpacity(0.6), shape: BoxShape.circle))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LayoutPreviewNotebook extends StatelessWidget {
  final bool isDark;
  const _LayoutPreviewNotebook({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF13111C) : const Color(0xFFF8F6FF);
    final sidebar = isDark ? const Color(0xFF1C1829) : Colors.white;
    final line = isDark ? const Color(0xFF2E2845) : const Color(0xFFE8E4F5);
    final accent = Theme.of(context).colorScheme.primary;
    final textMuted = isDark ? const Color(0xFF4A4370) : const Color(0xFFD1CBE8);
    final textMain = isDark ? const Color(0xFFCCC7E0) : const Color(0xFF3D3557);

    return Container(
      color: bg,
      child: Row(
        children: [
          // Left sidebar
          Container(
            width: 40,
            color: sidebar,
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_back_ios_new_rounded, size: 8, color: accent),
                const SizedBox(height: 8),
                Container(height: 5, width: 28, decoration: BoxDecoration(color: textMuted, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 5),
                Container(height: 5, width: 20, decoration: BoxDecoration(color: accent.withOpacity(0.4), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 8),
                Container(height: 1, color: line),
                const SizedBox(height: 8),
                Icon(Icons.folder_outlined, size: 8, color: textMuted),
                const SizedBox(height: 5),
                Container(height: 4, width: 24, decoration: BoxDecoration(color: textMuted.withOpacity(0.5), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 6),
                Icon(Icons.local_offer_outlined, size: 8, color: textMuted),
                const SizedBox(height: 5),
                Container(height: 4, width: 20, decoration: BoxDecoration(color: textMuted.withOpacity(0.5), borderRadius: BorderRadius.circular(2))),
              ],
            ),
          ),
          Container(width: 1, color: line),
          // Right content
          Expanded(
            child: Column(
              children: [
                // Toolbar
                Container(
                  height: 20,
                  color: sidebar,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (i) => Icon(Icons.circle, size: 5, color: accent.withOpacity(0.5))),
                  ),
                ),
                Container(height: 1, color: line),
                // Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                  child: Container(height: 8, decoration: BoxDecoration(color: textMain, borderRadius: BorderRadius.circular(3))),
                ),
                Container(height: 1, color: line),
                // Body
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _line(textMuted, 0.9),
                        const SizedBox(height: 4),
                        _line(textMuted, 0.7),
                        const SizedBox(height: 4),
                        _line(textMuted, 0.5),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LayoutPreviewZen extends StatelessWidget {
  final bool isDark;
  const _LayoutPreviewZen({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF090B16) : const Color(0xFFFDFCFF);
    final accent = Theme.of(context).colorScheme.primary;
    final textMuted = isDark ? const Color(0xFF3D3557) : const Color(0xFFD8D4EE);
    final textMain = isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF2A2540);

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Faded back button
          Icon(Icons.arrow_back_ios_new_rounded, size: 7, color: accent.withOpacity(0.3)),
          const SizedBox(height: 10),
          // Big title
          Container(height: 9, width: 70, decoration: BoxDecoration(color: textMain.withOpacity(0.8), borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 6),
          // Body — nice spacious lines
          _line(textMuted, 1.0),
          const SizedBox(height: 5),
          _line(textMuted, 0.8),
          const SizedBox(height: 5),
          _line(textMuted, 0.6),
          const SizedBox(height: 5),
          _line(textMuted, 0.9),
          const Spacer(),
          // Ghost save button
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withOpacity(0.2)),
              ),
              child: Icon(Icons.save_outlined, size: 8, color: accent.withOpacity(0.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LayoutPreviewCards extends StatelessWidget {
  final bool isDark;
  const _LayoutPreviewCards({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF13111C) : const Color(0xFFF5F3FF);
    final card = isDark ? const Color(0xFF1E1B2C) : Colors.white;
    final line = isDark ? const Color(0xFF2E2845) : const Color(0xFFE8E4F5);
    final accent = Theme.of(context).colorScheme.primary;
    final coverColor = accent;
    final textMuted = isDark ? const Color(0xFF4A4370) : const Color(0xFFD1CBE8);
    final textMain = isDark ? Colors.white.withOpacity(0.85) : Colors.white;

    return Container(
      color: bg,
      child: Column(
        children: [
          // Cover card
          Container(
            height: 52,
            color: coverColor,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.arrow_back_ios_new_rounded, size: 7, color: Colors.white.withOpacity(0.8)),
                    const Spacer(),
                    Icon(Icons.more_vert, size: 7, color: Colors.white.withOpacity(0.8)),
                  ],
                ),
                const SizedBox(height: 6),
                Container(height: 8, width: 65, decoration: BoxDecoration(color: textMain.withOpacity(0.9), borderRadius: BorderRadius.circular(3))),
                const SizedBox(height: 3),
                Container(height: 5, width: 40, decoration: BoxDecoration(color: textMain.withOpacity(0.5), borderRadius: BorderRadius.circular(2))),
              ],
            ),
          ),
          // Metadata chips row
          Container(
            height: 18,
            color: card,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _pill(accent.withOpacity(0.15), accent, 24),
                const SizedBox(width: 4),
                _pill(accent.withOpacity(0.15), accent, 18),
              ],
            ),
          ),
          Container(height: 1, color: line),
          // Editor content area
          Expanded(
            child: Container(
              color: card,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _line(textMuted, 0.9),
                  const SizedBox(height: 4),
                  _line(textMuted, 0.65),
                  const SizedBox(height: 4),
                  _line(textMuted, 0.5),
                ],
              ),
            ),
          ),
          // Bottom toolbar
          Container(height: 1, color: line),
          Container(
            height: 20,
            color: card,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (i) => Icon(Icons.circle, size: 5, color: accent.withOpacity(0.5))),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared micro-helpers for preview thumbnails ───────────────────────────

Widget _line(Color color, double widthFactor) {
  return LayoutBuilder(builder: (ctx, box) {
    return Container(
      height: 5,
      width: box.maxWidth * widthFactor,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
  });
}

/// Simple horizontal bar – same as [_line] but used by the newer preview widgets.
Widget _bar(Color color, double widthFactor) {
  return LayoutBuilder(builder: (ctx, box) {
    return Container(
      height: 5,
      width: box.maxWidth * widthFactor,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
  });
}

Widget _pill(Color bg, Color border, double width) {
  return Container(
    height: 10,
    width: width,
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: border.withOpacity(0.3)),
    ),
  );
}

Widget _colorDots() {
  const colors = [Color(0xFFFEE2E2), Color(0xFFFEF3C7), Color(0xFFECFDF5), Color(0xFFE0F2FE)];
  return Row(
    children: colors.map((c) => Container(
      margin: const EdgeInsets.only(left: 2),
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    )).toList(),
  );
}

// ── Journal Layout Preview ────────────────────────────────────────────────────
class _LayoutPreviewJournal extends StatelessWidget {
  final bool isDark;
  const _LayoutPreviewJournal({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0F1A0A) : const Color(0xFFFFFDF5);
    final lineColor = isDark ? const Color(0xFF1E2D15) : const Color(0xFFE8F0DA);
    final accent = isDark ? const Color(0xFF88C070) : const Color(0xFF5A8A3C);
    final textLine = isDark ? const Color(0xFF2A3D20) : const Color(0xFFD5E8BE);

    return Container(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date header strip
          Container(
            height: 22,
            color: accent.withOpacity(isDark ? 0.25 : 0.12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              _bar(accent.withOpacity(0.6), 0.35),
              const Spacer(),
              _bar(accent.withOpacity(0.4), 0.2),
            ]),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            child: _bar(isDark ? Colors.white70 : const Color(0xFF2A3D20), 0.7),
          ),
          Divider(height: 1, color: accent.withOpacity(0.3)),
          // Ruled lines
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: List.generate(6, (i) => Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: lineColor, width: 1)),
                      ),
                    ),
                  )),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      _bar(textLine, 0.8),
                      const SizedBox(height: 6),
                      _bar(textLine, 0.65),
                      const SizedBox(height: 6),
                      _bar(textLine, 0.75),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scrapbook Layout Preview ──────────────────────────────────────────────────
class _LayoutPreviewScrapbook extends StatelessWidget {
  final bool isDark;
  const _LayoutPreviewScrapbook({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A0F1A) : const Color(0xFFFFF8FF);
    return Container(
      color: bg,
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sticky note panels row
          SizedBox(
            height: 44,
            child: Row(
              children: [
                _stickyNote(const Color(0xFFFFE4F0), const Color(0xFFFF69B4), 'Title', isDark),
                const SizedBox(width: 4),
                _stickyNote(const Color(0xFFE4F0FF), const Color(0xFF69B4FF), 'Folder', isDark),
                const SizedBox(width: 4),
                _stickyNote(const Color(0xFFE4FFE4), const Color(0xFF69C869), 'Tags', isDark),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Editor card
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF241824) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF69B4).withOpacity(0.2)),
              ),
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(isDark ? const Color(0xFFFF69B4) : const Color(0xFFCC5599), 0.5),
                  const SizedBox(height: 4),
                  _bar(isDark ? const Color(0xFFBB90BB) : const Color(0xFF8855AA), 0.75),
                  const SizedBox(height: 4),
                  _bar(isDark ? const Color(0xFFBB90BB) : const Color(0xFF8855AA), 0.6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stickyNote(Color bg, Color accent, String label, bool isDark) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? accent.withOpacity(0.15) : bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: accent.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 20, height: 3, color: accent, margin: const EdgeInsets.only(bottom: 2)),
            Container(height: 2, color: accent.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}

// ── Petal Layout Preview ──────────────────────────────────────────────────────
class _LayoutPreviewPetal extends StatelessWidget {
  final bool isDark;
  const _LayoutPreviewPetal({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A0710) : const Color(0xFFFFF5F9);
    return Container(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Curved floral header
          ClipPath(
            clipper: _PetalClipper(),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF9B1B5A), const Color(0xFF4A0B2A)]
                      : [const Color(0xFFFF9EC8), const Color(0xFFFFCDE0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(Colors.white.withOpacity(0.9), 0.6),
                  const SizedBox(height: 4),
                  _bar(Colors.white.withOpacity(0.6), 0.4),
                ],
              ),
            ),
          ),
          // Editor area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(isDark ? const Color(0xFF7A3050) : const Color(0xFFD4557A), 0.7),
                  const SizedBox(height: 5),
                  _bar(isDark ? const Color(0xFF5A2A40) : const Color(0xFFE8A0B8), 0.85),
                  const SizedBox(height: 5),
                  _bar(isDark ? const Color(0xFF5A2A40) : const Color(0xFFE8A0B8), 0.6),
                ],
              ),
            ),
          ),
          // Petal chip row
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
            child: Row(children: [
              _pill(const Color(0xFFFFCDE0), const Color(0xFFFF9EC8), 28),
              const SizedBox(width: 4),
              _pill(const Color(0xFFFFDDEC), const Color(0xFFFFB3CE), 20),
              const SizedBox(width: 4),
              _pill(const Color(0xFFFFEEF5), const Color(0xFFFF9EC8), 24),
            ]),
          ),
        ],
      ),
    );
  }
}

class _PetalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 12);
    path.quadraticBezierTo(size.width / 2, size.height + 6, size.width, size.height - 12);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_) => false;
}

// ── Stardust Layout Preview ───────────────────────────────────────────────────
class _LayoutPreviewStardust extends StatelessWidget {
  final bool isDark;
  const _LayoutPreviewStardust({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0A051A), const Color(0xFF14083A)]
              : [const Color(0xFF1A0E3A), const Color(0xFF2D1060)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Star dots
          ..._buildStars(),
          // Content
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _bar(const Color(0xFFDDB8FF), 0.6),
                const SizedBox(height: 5),
                _bar(const Color(0xFFAA80DD), 0.4),
                const SizedBox(height: 10),
                _bar(const Color(0xFFCC99FF).withOpacity(0.7), 0.8),
                const SizedBox(height: 4),
                _bar(const Color(0xFFCC99FF).withOpacity(0.7), 0.65),
                const SizedBox(height: 4),
                _bar(const Color(0xFFCC99FF).withOpacity(0.7), 0.72),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStars() {
    final positions = [
      (left: 10.0, top: 12.0, size: 2.0),
      (left: 60.0, top: 6.0, size: 1.5),
      (left: 95.0, top: 18.0, size: 2.0),
      (left: 30.0, top: 30.0, size: 1.0),
      (left: 80.0, top: 40.0, size: 1.5),
      (left: 50.0, top: 50.0, size: 1.0),
      (left: 15.0, top: 60.0, size: 1.5),
      (left: 110.0, top: 55.0, size: 1.0),
    ];
    return positions
        .map((s) => Positioned(
              left: s.left,
              top: s.top,
              child: Container(
                width: s.size,
                height: s.size,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ))
        .toList();
  }
}
