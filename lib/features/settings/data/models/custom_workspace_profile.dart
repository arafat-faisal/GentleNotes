import '../../../../models/models.dart';

class CustomWorkspaceProfile {
  final String id;
  final String name;
  final bool isAdvanced;
  final List<EditorLayoutVariant> enabledLayouts;
  final List<AppThemePreset> enabledThemes;
  final List<String> enabledTools;
  final EditorLayoutVariant defaultLayout;
  final AppThemePreset defaultTheme;

  CustomWorkspaceProfile({
    required this.id,
    required this.name,
    this.isAdvanced = false,
    required this.enabledLayouts,
    required this.enabledThemes,
    required this.enabledTools,
    this.defaultLayout = EditorLayoutVariant.classic,
    this.defaultTheme = AppThemePreset.none,
  });

  CustomWorkspaceProfile copyWith({
    String? id,
    String? name,
    bool? isAdvanced,
    List<EditorLayoutVariant>? enabledLayouts,
    List<AppThemePreset>? enabledThemes,
    List<String>? enabledTools,
    EditorLayoutVariant? defaultLayout,
    AppThemePreset? defaultTheme,
  }) {
    return CustomWorkspaceProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      isAdvanced: isAdvanced ?? this.isAdvanced,
      enabledLayouts: enabledLayouts ?? this.enabledLayouts,
      enabledThemes: enabledThemes ?? this.enabledThemes,
      enabledTools: enabledTools ?? this.enabledTools,
      defaultLayout: defaultLayout ?? this.defaultLayout,
      defaultTheme: defaultTheme ?? this.defaultTheme,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isAdvanced': isAdvanced ? 1 : 0,
      'enabledLayouts': enabledLayouts.map((e) => e.name).toList(),
      'enabledThemes': enabledThemes.map((e) => e.name).toList(),
      'enabledTools': enabledTools,
      'defaultLayout': defaultLayout.name,
      'defaultTheme': defaultTheme.name,
    };
  }

  factory CustomWorkspaceProfile.fromMap(Map<String, dynamic> map) {
    return CustomWorkspaceProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      isAdvanced: map['isAdvanced'] == 1 || map['isAdvanced'] == true,
      enabledLayouts: (map['enabledLayouts'] as List<dynamic>?)
              ?.map((e) => EditorLayoutVariant.values.firstWhere((x) => x.name == e, orElse: () => EditorLayoutVariant.classic))
              .toList() ??
          [EditorLayoutVariant.classic],
      enabledThemes: (map['enabledThemes'] as List<dynamic>?)
              ?.map((e) => AppThemePreset.values.firstWhere((x) => x.name == e, orElse: () => AppThemePreset.none))
              .toList() ??
          [AppThemePreset.none],
      enabledTools: (map['enabledTools'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      defaultLayout: EditorLayoutVariant.values.firstWhere((e) => e.name == map['defaultLayout'], orElse: () => EditorLayoutVariant.classic),
      defaultTheme: AppThemePreset.values.firstWhere((e) => e.name == map['defaultTheme'], orElse: () => AppThemePreset.none),
    );
  }
}
