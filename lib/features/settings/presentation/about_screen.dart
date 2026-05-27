import 'package:flutter/material.dart';
import '../../../core/widgets/gentle_scaffold.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return GentleScaffold(
      title: 'About Gentle Notes',
      showBackButton: true,
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // Logo Section
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: primary.withOpacity(0.2), width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Gentle Notes',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '“Organize your learning, ideas, and projects beautifully.”',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Version 1.0.0 (MVP)',
                    style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Overview description
          Text(
            'The App',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: primary),
          ),
          const SizedBox(height: 8),
          Text(
            'Gentle Notes is an elegant, folder-based note organizer and productivity dashboard. '
            'Designed using Flutter Clean Architecture, it focuses on helping students, researchers, developers, '
            'and hackathon/datathon teams organize their structured knowledge and notes. '
            'With offline-first Hive storage, dynamic accent colors, and custom templates, Gentle Notes ensures '
            'a clean, focused writing and reading experience on any device.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 24),

          // Key features bullet point
          Text(
            'Core Features',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: primary),
          ),
          const SizedBox(height: 12),
          _buildFeatureBullet(context, 'Customizable Folders', 'Sort notes into directories, customize folder colors, and select unique icons.'),
          _buildFeatureBullet(context, '10 Built-In Templates', 'Structured note logs for AI/ML learning, hackathons, datathon experiment runs, and code snippets.'),
          _buildFeatureBullet(context, 'Diverse Note Formats', 'Write plain text, interactive checklists, code blocks, or full markdown documentation.'),
          _buildFeatureBullet(context, 'Seamless Sharing & Backups', 'Share notes as Markdown, export folders/databases as JSON files, and pick/restore backup documents.'),
          _buildFeatureBullet(context, 'Responsive Layout System', 'Multi-pane sidebar dashboard adapts automatically between Mobile, Tablet, Web, and Desktop.'),
          _buildFeatureBullet(context, 'Personalization Settings', 'Instantly toggle theme modes (Light/Dark/System) and active accent color palettes.'),
          const SizedBox(height: 24),

          // Architecture and future notes
          Text(
            'Future Scope',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: primary),
          ),
          const SizedBox(height: 8),
          Text(
            'The app is structured as website-ready. Future updates will introduce cross-device cloud synchronization, '
            'shared workspaces, real-time collaboration with friends, AI note summaries, and specialized admin views.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 48),

          // Footer info
          Center(
            child: Text(
              'Gentle Notes • Open Source Productivity',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBullet(BuildContext context, String title, String subtitle) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
