import 'package:flutter_test/flutter_test.dart';
import 'package:gentle_notes/models/models.dart';
import 'package:gentle_notes/core/utils/quill_paste_handler.dart';

void main() {
  test('FolderModel serialization test', () {
    final folder = FolderModel(
      id: 'test-id',
      name: 'Test Folder',
      colorHex: '#6366F1',
      iconName: 'folder',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      sortOrder: 1,
    );

    final map = folder.toMap();
    expect(map['id'], 'test-id');
    expect(map['name'], 'Test Folder');

    final deserialized = FolderModel.fromMap(map);
    expect(deserialized.id, folder.id);
    expect(deserialized.name, folder.name);
  });

  test('Workspace Profiles allowed settings filtering test', () {
    final defaultSettings = AppSettingsModel(
      themeMode: ThemeModeSetting.system,
      accentColorHex: '#6366F1',
      layoutMode: LayoutMode.grid,
      editorMode: EditorMode.gentleNote,
      defaultNoteType: NoteType.mixed,
      autoSaveEnabled: true,
      activeCodeTheme: 'vs-dark',
    );

    expect(defaultSettings.isAdvancedMode, isFalse);
    expect(defaultSettings.userMode, AppUserMode.normal);
    
    expect(defaultSettings.allowedLayouts, [EditorLayoutVariant.classic, EditorLayoutVariant.minimal]);
    expect(defaultSettings.allowedThemes, [
      AppThemePreset.none,
      AppThemePreset.midnightStars,
      AppThemePreset.floralRose,
      AppThemePreset.cookiesCream,
      AppThemePreset.sakura,
    ]);

    final advancedSettings = defaultSettings.copyWith(isAdvancedMode: true);
    expect(advancedSettings.allowedLayouts.length, EditorLayoutVariant.values.length);
    expect(advancedSettings.allowedThemes.length, AppThemePreset.values.length);

    final coderSimple = defaultSettings.copyWith(userMode: AppUserMode.coder);
    expect(coderSimple.allowedLayouts, [EditorLayoutVariant.classic, EditorLayoutVariant.minimal]);
    expect(coderSimple.allowedThemes, [
      AppThemePreset.none,
      AppThemePreset.midnightStars,
      AppThemePreset.floralRose,
      AppThemePreset.cookiesCream,
      AppThemePreset.sakura,
    ]);

    final coderAdvanced = coderSimple.copyWith(isAdvancedMode: true);
    expect(coderAdvanced.allowedLayouts, containsAll([EditorLayoutVariant.classic, EditorLayoutVariant.notebook]));
    expect(coderAdvanced.allowedThemes, containsAll([AppThemePreset.none, AppThemePreset.midnightStars]));

    final map = coderSimple.toMap();
    expect(map['userMode'], 'coder');
    expect(map['isAdvancedMode'], 0);

    final fromMapSettings = AppSettingsModel.fromMap(map);
    expect(fromMapSettings.userMode, AppUserMode.coder);
    expect(fromMapSettings.isAdvancedMode, isFalse);
  });

  test('Custom Workspace Profile serialization and filtering test', () {
    final profile = CustomWorkspaceProfile(
      id: 'test-profile-1',
      name: 'Writer Profile',
      isAdvanced: false,
      enabledLayouts: [EditorLayoutVariant.classic],
      enabledThemes: [AppThemePreset.cookiesCream, AppThemePreset.floralRose],
      enabledTools: ['format', 'lists'],
      defaultLayout: EditorLayoutVariant.classic,
      defaultTheme: AppThemePreset.cookiesCream,
    );

    // Test model serialization
    final map = profile.toMap();
    expect(map['id'], 'test-profile-1');
    expect(map['name'], 'Writer Profile');
    expect(map['isAdvanced'], 0);

    final fromMapProfile = CustomWorkspaceProfile.fromMap(map);
    expect(fromMapProfile.name, 'Writer Profile');
    expect(fromMapProfile.isAdvanced, isFalse);
    expect(fromMapProfile.enabledThemes.length, 2);

    // Test settings integration
    var settings = AppSettingsModel(
      themeMode: ThemeModeSetting.system,
      accentColorHex: '#6366F1',
      layoutMode: LayoutMode.grid,
      editorMode: EditorMode.gentleNote,
      defaultNoteType: NoteType.mixed,
      autoSaveEnabled: true,
      activeCodeTheme: 'vs-dark',
      customProfiles: [profile],
    );

    // Select custom profile
    settings = settings.copyWith(activeProfileId: 'test-profile-1', userMode: AppUserMode.custom);
    expect(settings.activeCustomProfile, isNotNull);
    expect(settings.activeCustomProfile!.name, 'Writer Profile');

    // Test simple mode filter rules for custom profile
    expect(settings.allowedLayouts, [EditorLayoutVariant.classic, EditorLayoutVariant.minimal]);
    expect(settings.allowedThemes, [
      AppThemePreset.none,
      AppThemePreset.midnightStars,
      AppThemePreset.floralRose,
      AppThemePreset.cookiesCream,
      AppThemePreset.sakura,
    ]);

    // Turn on advanced custom profile and verify it uses the customized subsets
    final advProfile = profile.copyWith(isAdvanced: true);
    settings = settings.copyWith(customProfiles: [advProfile]);

    expect(settings.allowedLayouts, [EditorLayoutVariant.classic]);
    expect(settings.allowedThemes, [AppThemePreset.cookiesCream, AppThemePreset.floralRose]);
    expect(settings.allowedTools, ['format', 'lists']);
    expect(settings.profileDefaultLayout, EditorLayoutVariant.classic);
    expect(settings.profileDefaultTheme, AppThemePreset.cookiesCream);
  });

  group('QuillPasteHandler Tests', () {
    test('detectMarkdown should identify markdown correctly', () {
      expect(QuillPasteHandler.detectMarkdown('# Heading'), isTrue);
      expect(QuillPasteHandler.detectMarkdown('**bold** text'), isTrue);
      expect(QuillPasteHandler.detectMarkdown('- bullet item'), isTrue);
      expect(QuillPasteHandler.detectMarkdown('just some plain text without formatting'), isFalse);
    });

    test('convertHtmlToMarkdown should strip style/script and format tags', () {
      const html = '<h1>Heading</h1><p>This is <strong>bold</strong> and <em>italic</em>.</p><script>alert("hi")</script>';
      final markdown = QuillPasteHandler.convertHtmlToMarkdown(html);
      expect(markdown, contains('# Heading'));
      expect(markdown, contains('This is **bold** and *italic*.'));
      expect(markdown, isNot(contains('<script>')));
      expect(markdown, isNot(contains('alert')));
    });
  });
}
