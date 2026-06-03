import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/gentle_scaffold.dart';
import 'widgets/sections/about_settings_section.dart';
import 'widgets/sections/account_settings_section.dart';
import 'widgets/sections/backup_settings_section.dart';
import 'widgets/sections/developer_settings_section.dart';
import 'widgets/sections/editor_settings_section.dart';
import 'widgets/sections/theme_settings_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: GentleScaffold(
        title: 'App Settings',
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                ),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: theme.colorScheme.onPrimary,
                unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.65),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(
                    height: 38,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_outline_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Profile'),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    height: 38,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.palette_outlined, size: 16),
                          SizedBox(width: 6),
                          Text('Appearance'),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    height: 38,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.settings_suggest_outlined, size: 16),
                          SizedBox(width: 6),
                          Text('Editor & Cloud'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  const AccountSettingsSection(),
                  const ThemeSettingsSection(),
                  _buildEditorAndCloudTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorAndCloudTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: const [
        EditorSettingsSection(),
        SizedBox(height: 20),
        BackupSettingsSection(),
        SizedBox(height: 20),
        AboutSettingsSection(),
        DeveloperSettingsSection(),
      ],
    );
  }
}
