import 'package:flutter_test/flutter_test.dart';
import 'package:gentle_notes/models/models.dart';
import 'package:gentle_notes/core/utils/quill_paste_handler.dart';
import 'package:gentle_notes/core/utils/quill_markdown_converter.dart';
import 'package:gentle_notes/features/editor/domain/entities/block_type.dart';
import 'package:gentle_notes/features/editor/domain/usecases/convert_delta_to_blocks.dart';
import 'package:gentle_notes/features/editor/domain/usecases/convert_blocks_to_delta.dart';

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

  group('Sticker Feature Tests', () {
    test('QuillMarkdownConverter should convert markdown sticker to delta and back', () {
      const markdown = '![sticker:cat](sticker://cat)\n';
      final deltaJson = QuillMarkdownConverter.markdownToDeltaJson(markdown);
      expect(deltaJson, contains('"sticker":"cat"'));

      final convertedMarkdown = QuillMarkdownConverter.deltaToMarkdown(deltaJson);
      expect(convertedMarkdown.trim(), '![sticker:cat](sticker://cat)');
    });

    test('ConvertDeltaToBlocks and ConvertBlocksToDelta should handle stickers', () {
      const deltaJson = '[{"insert":{"sticker":"coffee"}},{"insert":"\\n"}]';
      final blocks = ConvertDeltaToBlocks.execute(deltaJson);
      expect(blocks.length, 1);
      expect(blocks.first.type, BlockType.sticker);
      expect(blocks.first.content, 'coffee');

      final reconvertedDelta = ConvertBlocksToDelta.execute(blocks);
      expect(reconvertedDelta, contains('"sticker":"coffee"'));
    });

    test('FloatingStickerModel serialization and NoteModel integration test', () {
      final sticker = FloatingStickerModel(
        id: 'stick-1',
        name: 'cat',
        x: 100.5,
        y: 200.5,
        width: 150.0,
        height: 150.0,
        opacity: 0.8,
        hasBackground: true,
        textOver: 'Meow',
        textBehavior: 'over',
      );

      final stickerMap = sticker.toMap();
      expect(stickerMap['id'], 'stick-1');
      expect(stickerMap['name'], 'cat');
      expect(stickerMap['x'], 100.5);
      expect(stickerMap['y'], 200.5);
      expect(stickerMap['opacity'], 0.8);
      expect(stickerMap['hasBackground'], 1);
      expect(stickerMap['textOver'], 'Meow');
      expect(stickerMap['textBehavior'], 'over');

      final deserializedSticker = FloatingStickerModel.fromMap(stickerMap);
      expect(deserializedSticker.id, sticker.id);
      expect(deserializedSticker.name, sticker.name);
      expect(deserializedSticker.x, sticker.x);
      expect(deserializedSticker.y, sticker.y);
      expect(deserializedSticker.opacity, sticker.opacity);
      expect(deserializedSticker.hasBackground, sticker.hasBackground);
      expect(deserializedSticker.textOver, sticker.textOver);
      expect(deserializedSticker.textBehavior, sticker.textBehavior);

      final note = NoteModel(
        id: 'note-1',
        title: 'Note with stickers',
        content: 'Hello World',
        noteType: NoteType.text,
        tags: const [],
        attachments: const [],
        isPinned: false,
        isFavorite: false,
        colorHex: '#FFFFFF',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        stickers: [sticker],
      );

      final noteMap = note.toMap();
      expect(noteMap['stickers'], isList);
      expect((noteMap['stickers'] as List).length, 1);

      final deserializedNote = NoteModel.fromMap(noteMap);
      expect(deserializedNote.stickers.length, 1);
      expect(deserializedNote.stickers.first.name, 'cat');
      expect(deserializedNote.stickers.first.textOver, 'Meow');
    });
  });
}
