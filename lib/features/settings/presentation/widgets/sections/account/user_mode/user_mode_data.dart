import '../../../../../../../models/models.dart';

class UserModeData {
  static const Set<EditorLayoutVariant> defaultSimpleLayouts = {
    EditorLayoutVariant.classic,
    EditorLayoutVariant.minimal,
  };

  static const Set<AppThemePreset> defaultSimpleThemes = {
    AppThemePreset.none,
    AppThemePreset.midnightStars,
    AppThemePreset.floralRose,
    AppThemePreset.cookiesCream,
    AppThemePreset.sakura,
  };

  static const Set<String> defaultSimpleTools = {
    'format',
    'color',
    'heading',
    'align',
    'lists',
    'insert',
    'indent',
  };

  static const List<(String, String)> toolbarGroups = [
    ('format', 'Basic Format'),
    ('color', 'Colors & Highlights'),
    ('heading', 'Headers (H1-H6)'),
    ('align', 'Alignments'),
    ('lists', 'Bullet/Checkbox Lists'),
    ('insert', 'Inserts'),
    ('indent', 'Indents & Breaks'),
  ];
}
