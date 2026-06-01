import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/models.dart';
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
        ],
      ),
    );
  }
}
