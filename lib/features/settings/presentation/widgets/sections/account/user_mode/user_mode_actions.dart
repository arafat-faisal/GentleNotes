import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../../models/models.dart';
import '../../../../controllers/settings_controller.dart';
import 'user_mode_grid.dart';
import 'user_mode_icon.dart';

class DeleteConfirmDialog extends ConsumerWidget {
  final CustomWorkspaceProfile profile;

  const DeleteConfirmDialog({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return AlertDialog(
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
    );
  }
}

class CreateProfileDialog extends ConsumerStatefulWidget {
  const CreateProfileDialog({super.key});

  @override
  ConsumerState<CreateProfileDialog> createState() => _CreateProfileDialogState();
}

class _CreateProfileDialogState extends ConsumerState<CreateProfileDialog> {
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
              
              CustomModeSelectorGrid(
                isAdvanced: _isAdvanced,
                onModeChanged: (val) {
                  setState(() {
                    _isAdvanced = val;
                    if (!val) {
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
                    } else {
                      _enabledLayouts.addAll(EditorLayoutVariant.values);
                      _enabledThemes.addAll(AppThemePreset.values);
                    }
                  });
                },
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
                        UserModeIcon.getLayoutIcon(variant), 
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
                                      Icon(UserModeIcon.getLayoutIcon(l), size: 14, color: theme.colorScheme.primary),
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
            ref.read(settingsProvider.notifier).saveCustomProfile(newProfile);
            ref.read(settingsProvider.notifier).selectProfile(newProfile.id);
            Navigator.pop(context);
          },
          child: const Text('Create Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
