import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../models/models.dart';
import '../../../controllers/settings_controller.dart';

class UserModeSelector extends ConsumerWidget {
  const UserModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final activeCustom = settings.activeCustomProfile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Workspace Profile',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...AppUserMode.values.where((m) => m != AppUserMode.custom).map((mode) {
              final isSelected = settings.activeProfileId == mode.name;
              return ChoiceChip(
                avatar: Icon(
                  mode.icon, 
                  size: 16, 
                  color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary
                ),
                label: Text(mode.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(settingsProvider.notifier).selectProfile(mode.name);
                  }
                },
              );
            }),
          ],
        ),
        
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Saved Profiles',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showCreateProfileDialog(context, ref),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('New Profile', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (settings.customProfiles.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              'No custom profiles saved yet. Click "New Profile" to create one!',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: settings.customProfiles.map((profile) {
              final isSelected = settings.activeProfileId == profile.id;
              return InputChip(
                avatar: Icon(
                  Icons.assignment_ind_outlined, 
                  size: 14, 
                  color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                ),
                label: Text(profile.name),
                selected: isSelected,
                checkmarkColor: isSelected ? theme.colorScheme.onPrimary : null,
                showCheckmark: false,
                selectedColor: theme.colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                deleteIconColor: isSelected 
                    ? theme.colorScheme.onPrimary.withValues(alpha: 0.8) 
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                onSelected: (selected) {
                  if (selected) {
                    ref.read(settingsProvider.notifier).selectProfile(profile.id);
                  }
                },
                onDeleted: () {
                  _showDeleteConfirmDialog(context, ref, profile);
                },
                deleteIcon: const Icon(Icons.cancel_rounded, size: 16),
              );
            }).toList(),
          ),

        if (activeCustom != null) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Active Profile Customization Depth',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Simple Mode'),
                selected: !activeCustom.isAdvanced,
                onSelected: (selected) {
                  if (selected) {
                    final updated = activeCustom.copyWith(isAdvanced: false);
                    ref.read(settingsProvider.notifier).saveCustomProfile(updated);
                    ref.read(settingsProvider.notifier).selectProfile(updated.id);
                  }
                },
              ),
              ChoiceChip(
                label: const Text('Advanced Mode'),
                selected: activeCustom.isAdvanced,
                onSelected: (selected) {
                  if (selected) {
                    final updated = activeCustom.copyWith(isAdvanced: true);
                    ref.read(settingsProvider.notifier).saveCustomProfile(updated);
                    ref.read(settingsProvider.notifier).selectProfile(updated.id);
                  }
                },
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Profile Customization Depth',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Simple Mode'),
                selected: !settings.isAdvancedMode,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(settingsProvider.notifier).updateIsAdvancedMode(false);
                  }
                },
              ),
              ChoiceChip(
                label: const Text('Advanced Mode'),
                selected: settings.isAdvancedMode,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(settingsProvider.notifier).updateIsAdvancedMode(true);
                  }
                },
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, CustomWorkspaceProfile profile) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Profile?', 
          style: theme.textTheme.titleMedium?.copyWith(
            fontFamily: 'Outfit', 
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text('Are you sure you want to delete the custom profile "${profile.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel', 
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              ref.read(settingsProvider.notifier).deleteCustomProfile(profile.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCreateProfileDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _CreateProfileDialog(ref: ref),
    );
  }
}

class _CreateProfileDialog extends StatefulWidget {
  final WidgetRef ref;
  const _CreateProfileDialog({required this.ref});

  @override
  State<_CreateProfileDialog> createState() => _CreateProfileDialogState();
}

class _CreateProfileDialogState extends State<_CreateProfileDialog> {
  final _nameController = TextEditingController();
  bool _isAdvanced = false;
  
  final Set<EditorLayoutVariant> _enabledLayouts = {
    EditorLayoutVariant.classic,
    EditorLayoutVariant.minimal,
  };
  
  final Set<AppThemePreset> _enabledThemes = {
    AppThemePreset.none,
    AppThemePreset.midnightStars,
    AppThemePreset.floralRose,
    AppThemePreset.cookiesCream,
    AppThemePreset.sakura,
  };
  
  final Set<String> _enabledTools = {
    'format',
    'color',
    'heading',
    'align',
    'lists',
    'insert',
    'indent',
  };

  late EditorLayoutVariant _defaultLayout;
  late AppThemePreset _defaultTheme;

  @override
  void initState() {
    super.initState();
    _defaultLayout = EditorLayoutVariant.classic;
    _defaultTheme = AppThemePreset.none;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  IconData _getLayoutIcon(EditorLayoutVariant variant) {
    switch (variant) {
      case EditorLayoutVariant.classic: return Icons.view_agenda_outlined;
      case EditorLayoutVariant.minimal: return Icons.article_outlined;
      case EditorLayoutVariant.notebook: return Icons.menu_book_outlined;
      case EditorLayoutVariant.zen: return Icons.self_improvement_rounded;
      case EditorLayoutVariant.cards: return Icons.style_rounded;
      case EditorLayoutVariant.journal: return Icons.edit_note_rounded;
      case EditorLayoutVariant.scrapbook: return Icons.dashboard_customize_outlined;
      case EditorLayoutVariant.petal: return Icons.local_florist_outlined;
      case EditorLayoutVariant.stardust: return Icons.auto_awesome_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_enabledLayouts.contains(_defaultLayout)) {
      _defaultLayout = _enabledLayouts.first;
    }
    if (!_enabledThemes.contains(_defaultTheme)) {
      _defaultTheme = _enabledThemes.first;
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.dashboard_customize_rounded, color: theme.colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Create Workspace Profile',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Profile Name',
                  hintText: 'e.g., Writer Mode, Tech Logger',
                  prefixIcon: Icon(Icons.drive_file_rename_outline_rounded, color: theme.colorScheme.primary, size: 20),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                  ),
                ),
                style: const TextStyle(fontSize: 14, fontFamily: 'Inter'),
              ),
              const SizedBox(height: 24),
              
              Text(
                'CUSTOMIZATION DEPTH',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.0,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isAdvanced = false;
                          _enabledLayouts.clear();
                          _enabledLayouts.addAll([EditorLayoutVariant.classic, EditorLayoutVariant.minimal]);
                          _enabledThemes.clear();
                          _enabledThemes.addAll([
                            AppThemePreset.none,
                            AppThemePreset.midnightStars,
                            AppThemePreset.floralRose,
                            AppThemePreset.cookiesCream,
                            AppThemePreset.sakura,
                          ]);
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: !_isAdvanced 
                              ? theme.colorScheme.primary.withValues(alpha: 0.06) 
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: !_isAdvanced 
                                ? theme.colorScheme.primary 
                                : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                            width: !_isAdvanced ? 2 : 1,
                          ),
                          boxShadow: !_isAdvanced
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : null,
                        ),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.spa_rounded, 
                                  color: !_isAdvanced ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                  size: 22,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Simple Mode',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: !_isAdvanced ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Keep layouts minimal (Classic, Minimal) and use 5 standard themes.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                            if (!_isAdvanced)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isAdvanced = true;
                          _enabledLayouts.addAll(EditorLayoutVariant.values);
                          _enabledThemes.addAll(AppThemePreset.values);
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _isAdvanced 
                              ? theme.colorScheme.primary.withValues(alpha: 0.06) 
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isAdvanced 
                                ? theme.colorScheme.primary 
                                : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                            width: _isAdvanced ? 2 : 1,
                          ),
                          boxShadow: _isAdvanced
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : null,
                        ),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.tune_rounded, 
                                  color: _isAdvanced ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                  size: 22,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Advanced Mode',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _isAdvanced ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Unlock all layout variations, cover designs, themes, and fine-tune permissions.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                            if (_isAdvanced)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_isAdvanced) ...[
                Text(
                  'ENABLED LAYOUTS',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.0,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: EditorLayoutVariant.values.map((variant) {
                    final isChecked = _enabledLayouts.contains(variant);
                    return FilterChip(
                      avatar: Icon(
                        _getLayoutIcon(variant), 
                        size: 13, 
                        color: isChecked ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      label: Text(
                        variant.displayName, 
                        style: const TextStyle(fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w500),
                      ),
                      selected: isChecked,
                      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      checkmarkColor: theme.colorScheme.primary,
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(
                        color: isChecked ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                        width: isChecked ? 1.5 : 1,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _enabledLayouts.add(variant);
                          } else {
                            if (_enabledLayouts.length > 1) {
                              _enabledLayouts.remove(variant);
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                Text(
                  'ENABLED THEMES',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.0,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: AppThemePreset.values.map((preset) {
                    final isChecked = _enabledThemes.contains(preset);
                    return FilterChip(
                      label: Text(
                        '${preset.emoji} ${preset.displayName}', 
                        style: const TextStyle(fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w500),
                      ),
                      selected: isChecked,
                      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      checkmarkColor: theme.colorScheme.primary,
                      showCheckmark: isChecked,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(
                        color: isChecked ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                        width: isChecked ? 1.5 : 1,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _enabledThemes.add(preset);
                          } else {
                            if (_enabledThemes.length > 1) {
                              _enabledThemes.remove(preset);
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],

              Text(
                'ENABLED EDITOR TOOLBAR GROUPS',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.0,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ('format', 'Basic Format'),
                  ('color', 'Colors & Highlights'),
                  ('heading', 'Headers (H1-H6)'),
                  ('align', 'Alignments'),
                  ('lists', 'Bullet/Checkbox Lists'),
                  ('insert', 'Inserts'),
                  ('indent', 'Indents & Breaks'),
                ].map((t) {
                  final isChecked = _enabledTools.contains(t.$1);
                  return FilterChip(
                    label: Text(
                      t.$2, 
                      style: const TextStyle(fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w500),
                    ),
                    selected: isChecked,
                    selectedColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    checkmarkColor: theme.colorScheme.primary,
                    showCheckmark: isChecked,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(
                      color: isChecked ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                      width: isChecked ? 1.5 : 1,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _enabledTools.add(t.$1);
                        } else {
                          if (_enabledTools.length > 1) {
                            _enabledTools.remove(t.$1);
                          }
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              Text(
                'DEFAULT SELECTIONS',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.0,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Default Layout', 
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: theme.colorScheme.surface,
                            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<EditorLayoutVariant>(
                              isExpanded: true,
                              value: _defaultLayout,
                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12, fontFamily: 'Inter'),
                              icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
                              items: _enabledLayouts.map((l) {
                                return DropdownMenuItem(
                                  value: l, 
                                  child: Row(
                                    children: [
                                      Icon(_getLayoutIcon(l), size: 14, color: theme.colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Text(l.displayName),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _defaultLayout = val);
                                  }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Default Theme', 
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: theme.colorScheme.surface,
                            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<AppThemePreset>(
                              isExpanded: true,
                              value: _defaultTheme,
                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12, fontFamily: 'Inter'),
                              icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
                              items: _enabledThemes.map((t) {
                                return DropdownMenuItem(
                                  value: t, 
                                  child: Text('${t.emoji} ${t.displayName}'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _defaultTheme = val);
                                  }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            elevation: 2,
            shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          ),
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a profile name')),
              );
              return;
            }
            final newProfile = CustomWorkspaceProfile(
              id: 'profile_${DateTime.now().millisecondsSinceEpoch}',
              name: name,
              isAdvanced: _isAdvanced,
              enabledLayouts: _enabledLayouts.toList(),
              enabledThemes: _enabledThemes.toList(),
              enabledTools: _enabledTools.toList(),
              defaultLayout: _defaultLayout,
              defaultTheme: _defaultTheme,
            );
            widget.ref.read(settingsProvider.notifier).saveCustomProfile(newProfile);
            widget.ref.read(settingsProvider.notifier).selectProfile(newProfile.id);
            Navigator.pop(context);
          },
          child: const Text('Create Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
