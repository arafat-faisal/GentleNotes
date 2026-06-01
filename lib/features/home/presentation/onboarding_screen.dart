import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../models/models.dart';
import '../../settings/presentation/controllers/settings_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Beautiful Folder Organization',
      description: 'Create custom folders and nested directories with color codes and unique icons. Keep your ideas, learning, and projects clean.',
      icon: Icons.folder_copy_outlined,
      gradientColors: [Colors.indigo, Colors.blue],
    ),
    OnboardingPageData(
      title: 'Built-in Templates',
      description: 'Start writing immediately with structured templates for AI/ML learning, hackathons, meeting notes, code snippets, and research logs.',
      icon: Icons.assignment_outlined,
      gradientColors: [const Color(0xFF10B981), Colors.teal],
    ),
    OnboardingPageData(
      title: 'Import, Export & Share',
      description: 'Export your notes as beautiful Markdown or cross-platform JSON. Import shared notes and templates from team members instantly.',
      icon: Icons.share_outlined,
      gradientColors: [const Color(0xFFF43F5E), Colors.orange],
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding_v1', true);
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == _pages.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            
            // Slider content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length + 1,
                itemBuilder: (context, index) {
                  if (index == _pages.length) {
                    return _buildProfileSelectionPage(theme);
                  }
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon Circle
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: page.gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: page.gradientColors.first.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            page.icon,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 48),
                        
                        // Title
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onBackground,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Description
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onBackground.withOpacity(0.6),
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Page indicator and buttons
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dot indicators
                  Row(
                    children: List.generate(_pages.length + 1, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: isActive ? 24 : 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  
                  // Action button
                  ElevatedButton(
                    onPressed: () {
                      if (isLastPage) {
                        _completeOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLastPage ? 'Get Started' : 'Next',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isLastPage ? Icons.check : Icons.arrow_forward,
                          size: 18,
                        ),
                      ],
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

  Widget _buildProfileSelectionPage(ThemeData theme) {
    final settings = ref.watch(settingsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Text(
            'Choose Your Profile',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'GentleNotes will customize your editor layouts, color themes, and tool options for your writing mode.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          // Customization Depth Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => ref.read(settingsProvider.notifier).updateIsAdvancedMode(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !settings.isAdvancedMode ? theme.colorScheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Simple Mode',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: !settings.isAdvancedMode ? Colors.white : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => ref.read(settingsProvider.notifier).updateIsAdvancedMode(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: settings.isAdvancedMode ? theme.colorScheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Advanced Mode',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: settings.isAdvancedMode ? Colors.white : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: AppUserMode.values.map((mode) {
              final isSelected = settings.userMode == mode;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.04)
                      : theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        ref.read(settingsProvider.notifier).updateUserMode(mode);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                mode.icon,
                                size: 20,
                                color: isSelected ? Colors.white : theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mode.displayName,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Outfit',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    mode.description,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: theme.colorScheme.primary,
                                size: 20,
                              )
                            else
                              Icon(
                                Icons.circle_outlined,
                                color: theme.colorScheme.onSurface.withOpacity(0.2),
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (isSelected && mode != AppUserMode.custom && !settings.isAdvancedMode) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Simple Mode applied: Layout: ${settings.editorLayout.displayName} | Theme: ${settings.themePreset.displayName}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (isSelected && mode == AppUserMode.custom && !settings.isAdvancedMode) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Custom profile settings are locked. Toggle "Advanced Mode" above to choose custom configurations.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (isSelected && mode == AppUserMode.custom && settings.isAdvancedMode) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enabled Layouts',
                              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: EditorLayoutVariant.values.map((variant) {
                                final isEnabled = settings.customEnabledLayouts.contains(variant);
                                return FilterChip(
                                  label: Text(variant.displayName),
                                  selected: isEnabled,
                                  onSelected: (selected) {
                                    final list = List<EditorLayoutVariant>.from(settings.customEnabledLayouts);
                                    if (selected) {
                                      list.add(variant);
                                    } else {
                                      if (list.length > 1) list.remove(variant);
                                    }
                                    ref.read(settingsProvider.notifier).updateCustomEnabledLayouts(list);
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Enabled Themes',
                              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: AppThemePreset.values.map((preset) {
                                final isEnabled = settings.customEnabledThemes.contains(preset);
                                return FilterChip(
                                  label: Text('${preset.emoji} ${preset.displayName}'),
                                  selected: isEnabled,
                                  onSelected: (selected) {
                                    final list = List<AppThemePreset>.from(settings.customEnabledThemes);
                                    if (selected) {
                                      list.add(preset);
                                    } else {
                                      if (list.length > 1) list.remove(preset);
                                    }
                                    ref.read(settingsProvider.notifier).updateCustomEnabledThemes(list);
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Enabled Editor Toolbar Groups',
                              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ('format', 'Basic Format (Bold, Italic...)'),
                                ('color', 'Colors & Highlights'),
                                ('heading', 'Headers (H1-H6)'),
                                ('align', 'Alignments'),
                                ('lists', 'Bullet/Checkbox Lists'),
                                ('insert', 'Inserts (Media, Drawing, Record...)'),
                                ('indent', 'Indentation & Line Breaks'),
                              ].map((t) {
                                final isEnabled = settings.customEnabledTools.contains(t.$1);
                                return FilterChip(
                                  label: Text(t.$2),
                                  selected: isEnabled,
                                  onSelected: (selected) {
                                    final list = List<String>.from(settings.customEnabledTools);
                                    if (selected) {
                                      list.add(t.$1);
                                    } else {
                                      if (list.length > 1) list.remove(t.$1);
                                    }
                                    ref.read(settingsProvider.notifier).updateCustomEnabledTools(list);
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
  });
}
