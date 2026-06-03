import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/settings_controller.dart';
import '../editor_preferences_panel.dart';

class EditorSettingsSection extends ConsumerWidget {
  const EditorSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return EditorPreferencesPanel(settings: settings);
  }
}
