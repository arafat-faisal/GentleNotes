import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/models.dart';
import '../../../../core/utils/logger.dart';
import '../controllers/settings_controller.dart';

class EditorPreferencesPanel extends ConsumerWidget {
  final AppSettingsModel settings;
  const EditorPreferencesPanel({super.key, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.notes_outlined),
            title: const Text('Default Note Type'),
            trailing: SizedBox(
              width: 140,
              child: DropdownButton<NoteType>(
                isExpanded: true,
                value: settings.defaultNoteType,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down_rounded),
                items: NoteType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      type.displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(settingsProvider.notifier).updateDefaultNoteType(val);
                  }
                },
              ),
            ),
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.edit_note_rounded),
            title: const Text('Editor Mode'),
            subtitle: const Text('Continuous text or block-based editor'),
            trailing: SizedBox(
              width: 120,
              child: DropdownButton<EditorMode>(
                isExpanded: true,
                value: settings.editorMode,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down_rounded),
                items: EditorMode.values.map((mode) {
                  return DropdownMenuItem(
                    value: mode,
                    child: Text(
                      mode.displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(settingsProvider.notifier).updateEditorMode(val);
                  }
                },
              ),
            ),
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.code_rounded),
            title: const Text('Code Preview Theme'),
            subtitle: const Text('Select visual syntax highlight theme'),
            trailing: SizedBox(
              width: 120,
              child: DropdownButton<String>(
                isExpanded: true,
                value: settings.activeCodeTheme,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down_rounded),
                items: const [
                  DropdownMenuItem(
                    value: 'vs-dark',
                    child: Text('VS Code Dark', style: TextStyle(fontSize: 13, fontFamily: 'Inter')),
                  ),
                  DropdownMenuItem(
                    value: 'vs-light',
                    child: Text('VS Code Light', style: TextStyle(fontSize: 13, fontFamily: 'Inter')),
                  ),
                  DropdownMenuItem(
                    value: 'monokai',
                    child: Text('Monokai', style: TextStyle(fontSize: 13, fontFamily: 'Inter')),
                  ),
                  DropdownMenuItem(
                    value: 'github',
                    child: Text('GitHub Light', style: TextStyle(fontSize: 13, fontFamily: 'Inter')),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref.read(settingsProvider.notifier).updateActiveCodeTheme(val);
                  }
                },
              ),
            ),
          ),
          const Divider(indent: 16, endIndent: 16),
          SwitchListTile(
            secondary: const Icon(Icons.sync),
            title: const Text('Auto-save Drafts'),
            subtitle: const Text('Saves edits automatically every 4 seconds'),
            value: settings.autoSaveEnabled,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).toggleAutoSave(val);
            },
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.font_download_outlined),
            title: const Text('Editor Font Family'),
            subtitle: const Text('Choose typeface for note text'),
            trailing: SizedBox(
              width: 140,
              child: DropdownButton<String>(
                isExpanded: true,
                value: settings.editorFontFamily,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down_rounded),
                items: [
                  ('System', 'System Default'),
                  ('Inter', 'Inter (Sans)'),
                  ('Outfit', 'Outfit (Modern)'),
                  ('Roboto Mono', 'Roboto Mono (Code)'),
                  ('Lora', 'Lora (Serif)'),
                  ('Georgia', 'Georgia (Classic)'),
                  ('Lexend', 'Lexend (Readable)'),
                ].map((item) {
                  return DropdownMenuItem(
                    value: item.$1,
                    child: Text(
                      item.$2,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(settingsProvider.notifier).updateEditorFontFamily(val);
                  }
                },
              ),
            ),
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.format_size_rounded),
            title: const Text('Editor Font Size'),
            subtitle: const Text('Scale note text size'),
            trailing: SizedBox(
              width: 150,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${settings.editorFontSize.toInt()} px',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: settings.editorFontSize,
                      min: 12.0,
                      max: 24.0,
                      divisions: 12,
                      onChanged: (val) {
                        ref.read(settingsProvider.notifier).updateEditorFontSize(val);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.format_line_spacing_rounded),
            title: const Text('Editor Line Height'),
            subtitle: const Text('Adjust line spacing for comfort'),
            trailing: SizedBox(
              width: 140,
              child: DropdownButton<double>(
                isExpanded: true,
                value: settings.editorLineHeight,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down_rounded),
                items: [
                  (1.2, 'Compact (1.2)'),
                  (1.4, 'Normal (1.4)'),
                  (1.6, 'Reading (1.6)'),
                  (1.8, 'Relaxed (1.8)'),
                ].map((item) {
                  return DropdownMenuItem(
                    value: item.$1,
                    child: Text(
                      item.$2,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(settingsProvider.notifier).updateEditorLineHeight(val);
                  }
                },
              ),
            ),
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Diagnostic Logs'),
            subtitle: const Text('View and export application logs'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showLogsDialog(context),
          ),
        ],
      ),
    );
  }

  void _showLogsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final logsStr = AppLogger.exportLogs();
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.bug_report_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Diagnostic Logs'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                  ),
                  child: logsStr.isEmpty
                      ? const Center(child: Text('No logs available'))
                      : SingleChildScrollView(
                          child: SelectableText(
                            logsStr,
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 11,
                            ),
                          ),
                        ),
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () {
                    AppLogger.clear();
                    setDialogState(() {});
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                  label: const Text('Clear', style: TextStyle(color: Colors.red)),
                ),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: logsStr));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logs copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_all_rounded, size: 18),
                  label: const Text('Copy All'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
