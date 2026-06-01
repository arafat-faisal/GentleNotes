import 'package:flutter/material.dart';
import '../../../../models/models.dart';

class AppSettingsModel {
  final ThemeModeSetting themeMode;
  final String accentColorHex;
  final LayoutMode layoutMode;
  final EditorMode editorMode;
  final NoteType defaultNoteType;
  final bool autoSaveEnabled;
  final String activeCodeTheme;
  final EditorLayoutVariant editorLayout;
  final AppThemePreset themePreset;
  final AppUserMode userMode;
  final bool isAdvancedMode;
  final String activeProfileId;
  final List<CustomWorkspaceProfile> customProfiles;
  final List<EditorLayoutVariant> customEnabledLayouts;
  final List<AppThemePreset> customEnabledThemes;
  final List<String> customEnabledTools;

  AppSettingsModel({
    required this.themeMode,
    required this.accentColorHex,
    required this.layoutMode,
    required this.editorMode,
    required this.defaultNoteType,
    required this.autoSaveEnabled,
    required this.activeCodeTheme,
    this.editorLayout = EditorLayoutVariant.classic,
    this.themePreset = AppThemePreset.none,
    this.userMode = AppUserMode.normal,
    this.isAdvancedMode = false,
    this.activeProfileId = 'normal',
    this.customProfiles = const [],
    this.customEnabledLayouts = const [
      EditorLayoutVariant.classic,
      EditorLayoutVariant.minimal,
      EditorLayoutVariant.notebook,
      EditorLayoutVariant.zen,
      EditorLayoutVariant.cards,
      EditorLayoutVariant.journal,
      EditorLayoutVariant.scrapbook,
      EditorLayoutVariant.petal,
      EditorLayoutVariant.stardust,
    ],
    this.customEnabledThemes = const [
      AppThemePreset.none,
      AppThemePreset.floralRose,
      AppThemePreset.cookiesCream,
      AppThemePreset.sakura,
      AppThemePreset.lavenderDream,
      AppThemePreset.oceanBreeze,
      AppThemePreset.midnightStars,
      AppThemePreset.cottagecore,
      AppThemePreset.candyPop,
      AppThemePreset.matchaLatte,
      AppThemePreset.cloudPastel,
    ],
    this.customEnabledTools = const [
      'format',
      'color',
      'heading',
      'align',
      'lists',
      'insert',
      'indent',
    ],
  });

  CustomWorkspaceProfile? get activeCustomProfile {
    try {
      return customProfiles.firstWhere((p) => p.id == activeProfileId);
    } catch (_) {
      return null;
    }
  }

  AppSettingsModel copyWith({
    ThemeModeSetting? themeMode,
    String? accentColorHex,
    LayoutMode? layoutMode,
    EditorMode? editorMode,
    NoteType? defaultNoteType,
    bool? autoSaveEnabled,
    String? activeCodeTheme,
    EditorLayoutVariant? editorLayout,
    AppThemePreset? themePreset,
    AppUserMode? userMode,
    bool? isAdvancedMode,
    String? activeProfileId,
    List<CustomWorkspaceProfile>? customProfiles,
    List<EditorLayoutVariant>? customEnabledLayouts,
    List<AppThemePreset>? customEnabledThemes,
    List<String>? customEnabledTools,
  }) {
    return AppSettingsModel(
      themeMode: themeMode ?? this.themeMode,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      layoutMode: layoutMode ?? this.layoutMode,
      editorMode: editorMode ?? this.editorMode,
      defaultNoteType: defaultNoteType ?? this.defaultNoteType,
      autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
      activeCodeTheme: activeCodeTheme ?? this.activeCodeTheme,
      editorLayout: editorLayout ?? this.editorLayout,
      themePreset: themePreset ?? this.themePreset,
      userMode: userMode ?? this.userMode,
      isAdvancedMode: isAdvancedMode ?? this.isAdvancedMode,
      activeProfileId: activeProfileId ?? this.activeProfileId,
      customProfiles: customProfiles ?? this.customProfiles,
      customEnabledLayouts: customEnabledLayouts ?? this.customEnabledLayouts,
      customEnabledThemes: customEnabledThemes ?? this.customEnabledThemes,
      customEnabledTools: customEnabledTools ?? this.customEnabledTools,
    );
  }

  EditorLayoutVariant get profileDefaultLayout {
    final activeCustom = activeCustomProfile;
    if (activeCustom != null) {
      return activeCustom.defaultLayout;
    }
    switch (userMode) {
      case AppUserMode.normal:
        return EditorLayoutVariant.classic;
      case AppUserMode.coder:
        return EditorLayoutVariant.classic;
      case AppUserMode.student:
        return EditorLayoutVariant.journal;
      case AppUserMode.researcher:
        return EditorLayoutVariant.zen;
      case AppUserMode.custom:
        return EditorLayoutVariant.classic;
    }
  }

  AppThemePreset get profileDefaultTheme {
    final activeCustom = activeCustomProfile;
    if (activeCustom != null) {
      return activeCustom.defaultTheme;
    }
    switch (userMode) {
      case AppUserMode.normal:
        return AppThemePreset.none;
      case AppUserMode.coder:
        return AppThemePreset.midnightStars;
      case AppUserMode.student:
        return AppThemePreset.floralRose;
      case AppUserMode.researcher:
        return AppThemePreset.cookiesCream;
      case AppUserMode.custom:
        return AppThemePreset.none;
    }
  }

  List<EditorLayoutVariant> get allowedLayouts {
    final activeCustom = activeCustomProfile;
    final isAdvanced = activeCustom != null ? activeCustom.isAdvanced : isAdvancedMode;

    if (!isAdvanced) {
      return const [
        EditorLayoutVariant.classic,
        EditorLayoutVariant.minimal,
      ];
    }
    if (activeCustom != null) {
      return activeCustom.enabledLayouts;
    }
    switch (userMode) {
      case AppUserMode.normal:
        return EditorLayoutVariant.values;
      case AppUserMode.coder:
        return const [
          EditorLayoutVariant.classic,
          EditorLayoutVariant.notebook,
        ];
      case AppUserMode.student:
        return const [
          EditorLayoutVariant.classic,
          EditorLayoutVariant.journal,
          EditorLayoutVariant.scrapbook,
          EditorLayoutVariant.cards,
        ];
      case AppUserMode.researcher:
        return const [
          EditorLayoutVariant.minimal,
          EditorLayoutVariant.zen,
          EditorLayoutVariant.notebook,
        ];
      case AppUserMode.custom:
        return customEnabledLayouts;
    }
  }

  List<AppThemePreset> get allowedThemes {
    final activeCustom = activeCustomProfile;
    final isAdvanced = activeCustom != null ? activeCustom.isAdvanced : isAdvancedMode;

    if (!isAdvanced) {
      return const [
        AppThemePreset.none,
        AppThemePreset.midnightStars,
        AppThemePreset.floralRose,
        AppThemePreset.cookiesCream,
        AppThemePreset.sakura,
      ];
    }
    if (activeCustom != null) {
      return activeCustom.enabledThemes;
    }
    switch (userMode) {
      case AppUserMode.normal:
        return AppThemePreset.values;
      case AppUserMode.coder:
        return const [
          AppThemePreset.none,
          AppThemePreset.midnightStars,
        ];
      case AppUserMode.student:
        return const [
          AppThemePreset.floralRose,
          AppThemePreset.sakura,
          AppThemePreset.candyPop,
          AppThemePreset.matchaLatte,
        ];
      case AppUserMode.researcher:
        return const [
          AppThemePreset.cookiesCream,
          AppThemePreset.oceanBreeze,
          AppThemePreset.cottagecore,
          AppThemePreset.cloudPastel,
        ];
      case AppUserMode.custom:
        return customEnabledThemes;
    }
  }

  List<String> get allowedTools {
    final activeCustom = activeCustomProfile;
    if (activeCustom != null) {
      return activeCustom.enabledTools;
    }
    switch (userMode) {
      case AppUserMode.normal:
        return const [
          'format',
          'color',
          'heading',
          'align',
          'lists',
          'insert',
          'indent',
        ];
      case AppUserMode.coder:
        return const [
          'format',
          'lists',
          'insert',
        ];
      case AppUserMode.student:
        return const [
          'format',
          'color',
          'lists',
          'insert',
        ];
      case AppUserMode.researcher:
        return const [
          'format',
          'heading',
          'align',
          'lists',
          'indent',
          'insert',
        ];
      case AppUserMode.custom:
        return customEnabledTools;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode.name,
      'accentColorHex': accentColorHex,
      'layoutMode': layoutMode.name,
      'editorMode': editorMode.name,
      'defaultNoteType': defaultNoteType.name,
      'autoSaveEnabled': autoSaveEnabled ? 1 : 0,
      'activeCodeTheme': activeCodeTheme,
      'editorLayout': editorLayout.name,
      'themePreset': themePreset.name,
      'userMode': userMode.name,
      'isAdvancedMode': isAdvancedMode ? 1 : 0,
      'activeProfileId': activeProfileId,
      'customProfiles': customProfiles.map((p) => p.toMap()).toList(),
      'customEnabledLayouts': customEnabledLayouts.map((e) => e.name).toList(),
      'customEnabledThemes': customEnabledThemes.map((e) => e.name).toList(),
      'customEnabledTools': customEnabledTools,
    };
  }

  factory AppSettingsModel.fromMap(Map<String, dynamic> map) {
    return AppSettingsModel(
      themeMode: ThemeModeSetting.values.firstWhere((e) => e.name == map['themeMode'], orElse: () => ThemeModeSetting.system),
      accentColorHex: map['accentColorHex'] ?? '#6366F1',
      layoutMode: LayoutMode.values.firstWhere((e) => e.name == map['layoutMode'], orElse: () => LayoutMode.grid),
      editorMode: EditorMode.values.firstWhere((e) => e.name == map['editorMode'], orElse: () => EditorMode.gentleNote),
      defaultNoteType: NoteType.values.firstWhere((e) => e.name == map['defaultNoteType'], orElse: () => NoteType.markdown),
      autoSaveEnabled: (map['autoSaveEnabled'] == 1 || map['autoSaveEnabled'] == true || map['autoSaveEnabled'] == null),
      activeCodeTheme: map['activeCodeTheme'] ?? 'vs-dark',
      editorLayout: EditorLayoutVariant.values.firstWhere(
        (e) => e.name == map['editorLayout'],
        orElse: () => EditorLayoutVariant.classic,
      ),
      themePreset: AppThemePreset.values.firstWhere(
        (e) => e.name == map['themePreset'],
        orElse: () => AppThemePreset.none,
      ),
      userMode: AppUserMode.values.firstWhere(
        (e) => e.name == map['userMode'],
        orElse: () => AppUserMode.normal,
      ),
      isAdvancedMode: map['isAdvancedMode'] == 1 || map['isAdvancedMode'] == true,
      activeProfileId: map['activeProfileId'] ?? 'normal',
      customProfiles: (map['customProfiles'] as List<dynamic>?)
              ?.map((e) => CustomWorkspaceProfile.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
      customEnabledLayouts: (map['customEnabledLayouts'] as List<dynamic>?)
              ?.map((e) => EditorLayoutVariant.values.firstWhere((x) => x.name == e, orElse: () => EditorLayoutVariant.classic))
              .toList() ??
          EditorLayoutVariant.values.toList(),
      customEnabledThemes: (map['customEnabledThemes'] as List<dynamic>?)
              ?.map((e) => AppThemePreset.values.firstWhere((x) => x.name == e, orElse: () => AppThemePreset.none))
              .toList() ??
          AppThemePreset.values.toList(),
      customEnabledTools: (map['customEnabledTools'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['format', 'color', 'heading', 'align', 'lists', 'insert', 'indent'],
    );
  }

  Color get accentColor {
    final hex = accentColorHex.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return const Color(0xFF6366F1);
  }
}
