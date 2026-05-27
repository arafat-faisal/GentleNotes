/// Hive-backed implementation of [ILocalStorage].
///
/// This is the single concrete implementation of the storage interface.
/// All persistence logic lives here — the rest of the app talks only to
/// the [ILocalStorage] abstraction, never to this class directly.
///
/// To swap the backend (e.g., migrate to Drift/SQLite), create a new class
/// that implements [ILocalStorage] and update the provider in
/// [storageProvider] — zero UI changes required.
library hive_local_storage;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../constants/app_constants.dart';
import '../../models/models.dart';
import 'i_local_storage.dart';

class HiveLocalStorage implements ILocalStorage {
  late Box _foldersBox;
  late Box _notesBox;
  late Box _templatesBox;
  late Box _settingsBox;
  late SharedPreferences _sharedPrefs;

  // ── Singleton ───────────────────────────────────────────────────────────────
  static final HiveLocalStorage _instance = HiveLocalStorage._internal();
  factory HiveLocalStorage() => _instance;
  HiveLocalStorage._internal();

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  Future<void> init() async {
    await Hive.initFlutter();

    _foldersBox = await Hive.openBox(AppConstants.foldersBox);
    _notesBox = await Hive.openBox(AppConstants.notesBox);
    _templatesBox = await Hive.openBox(AppConstants.templatesBox);
    _settingsBox = await Hive.openBox(AppConstants.settingsBox);
    _sharedPrefs = await SharedPreferences.getInstance();

    await _seedInitialDataIfNeeded();
  }

  // ── Settings ────────────────────────────────────────────────────────────────

  @override
  AppSettingsModel getSettings() {
    final theme = _sharedPrefs.getString(AppConstants.prefThemeMode) ?? 'system';
    final accent = _sharedPrefs.getString(AppConstants.prefAccentColor) ?? AppConstants.defaultAccentHex;
    final layout = _sharedPrefs.getString(AppConstants.prefLayoutMode) ?? 'grid';
    final editor = _sharedPrefs.getString(AppConstants.prefEditorMode) ?? 'markdown';
    final noteType = _sharedPrefs.getString(AppConstants.prefDefaultNoteType) ?? 'mixed';
    final autoSave = _sharedPrefs.getBool(AppConstants.prefAutoSave) ?? true;
    final codeTheme = _sharedPrefs.getString(AppConstants.prefCodeTheme) ?? AppConstants.defaultCodeTheme;

    return AppSettingsModel(
      themeMode: ThemeModeSetting.values.firstWhere((e) => e.name == theme, orElse: () => ThemeModeSetting.system),
      accentColorHex: accent,
      layoutMode: LayoutMode.values.firstWhere((e) => e.name == layout, orElse: () => LayoutMode.grid),
      editorMode: EditorMode.values.firstWhere((e) => e.name == editor, orElse: () => EditorMode.markdown),
      defaultNoteType: NoteType.values.firstWhere((e) => e.name == noteType, orElse: () => NoteType.markdown),
      autoSaveEnabled: autoSave,
      activeCodeTheme: codeTheme,
    );
  }

  @override
  Future<void> saveSettings(AppSettingsModel settings) async {
    await _sharedPrefs.setString(AppConstants.prefThemeMode, settings.themeMode.name);
    await _sharedPrefs.setString(AppConstants.prefAccentColor, settings.accentColorHex);
    await _sharedPrefs.setString(AppConstants.prefLayoutMode, settings.layoutMode.name);
    await _sharedPrefs.setString(AppConstants.prefEditorMode, settings.editorMode.name);
    await _sharedPrefs.setString(AppConstants.prefDefaultNoteType, settings.defaultNoteType.name);
    await _sharedPrefs.setBool(AppConstants.prefAutoSave, settings.autoSaveEnabled);
    await _sharedPrefs.setString(AppConstants.prefCodeTheme, settings.activeCodeTheme);
  }

  // ── User Role ────────────────────────────────────────────────────────────────

  @override
  UserRole getUserRole() {
    final roleStr = _sharedPrefs.getString(AppConstants.prefUserRole) ?? 'subscriber';
    return UserRole.values.firstWhere((e) => e.name == roleStr, orElse: () => UserRole.subscriber);
  }

  @override
  Future<void> saveUserRole(UserRole role) async {
    await _sharedPrefs.setString(AppConstants.prefUserRole, role.name);
  }

  // ── Folders ──────────────────────────────────────────────────────────────────

  @override
  List<FolderModel> getFolders() {
    final List<FolderModel> folders = [];
    for (var key in _foldersBox.keys) {
      final val = _foldersBox.get(key);
      if (val is Map) {
        folders.add(FolderModel.fromMap(Map<String, dynamic>.from(val)));
      }
    }
    folders.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return folders;
  }

  @override
  Future<void> saveFolder(FolderModel folder) async {
    await _foldersBox.put(folder.id, folder.toMap());
  }

  @override
  Future<void> deleteFolder(String id) async {
    await _foldersBox.delete(id);
    // Orphan notes are unlinked from the deleted folder (not deleted themselves).
    final notes = getNotes().where((n) => n.folderId == id);
    for (var note in notes) {
      await saveNote(note.copyWith(folderId: null));
    }
  }

  // ── Notes ────────────────────────────────────────────────────────────────────

  @override
  List<NoteModel> getNotes() {
    final List<NoteModel> notes = [];
    for (var key in _notesBox.keys) {
      final val = _notesBox.get(key);
      if (val is Map) {
        notes.add(NoteModel.fromMap(Map<String, dynamic>.from(val)));
      }
    }
    // Sort: most recently updated first by default.
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  @override
  Future<void> saveNote(NoteModel note) async {
    await _notesBox.put(note.id, note.toMap());
  }

  @override
  Future<void> deleteNote(String id) async {
    await _notesBox.delete(id);
  }

  // ── Templates ────────────────────────────────────────────────────────────────

  @override
  List<NoteTemplateModel> getTemplates() {
    final List<NoteTemplateModel> templates = [];
    for (var key in _templatesBox.keys) {
      final val = _templatesBox.get(key);
      if (val is Map) {
        templates.add(NoteTemplateModel.fromMap(Map<String, dynamic>.from(val)));
      }
    }
    return templates;
  }

  @override
  Future<void> saveTemplate(NoteTemplateModel template) async {
    await _templatesBox.put(template.id, template.toMap());
  }

  @override
  Future<void> deleteTemplate(String id) async {
    final templates = getTemplates();
    try {
      final template = templates.firstWhere((t) => t.id == id);
      if (template.isBuiltIn) return; // Built-in templates are protected.
    } catch (_) {
      return;
    }
    await _templatesBox.delete(id);
  }

  // ── Seed Initial Data ────────────────────────────────────────────────────────

  Future<void> _seedInitialDataIfNeeded() async {
    final bool hasRunBefore = _sharedPrefs.getBool(AppConstants.prefHasSeededV1) ?? false;
    if (hasRunBefore) {
      // Still check if v2 stress-test note needs seeding.
      await _seedV2IfNeeded();
      return;
    }

    final uuid = const Uuid();

    // 1. Seed Built-In Templates
    for (var t in _getBuiltInTemplatesData(uuid)) {
      await saveTemplate(t);
    }

    // 2. Seed Default Folders
    final defaultFolders = [
      FolderModel(id: AppConstants.folderAiMl, name: 'AI/ML Learning', colorHex: '#6366F1', iconName: 'psychology_outlined', createdAt: DateTime.now(), updatedAt: DateTime.now(), sortOrder: 1),
      FolderModel(id: AppConstants.folderHackathons, name: 'Hackathon Ideas', colorHex: '#10B981', iconName: 'lightbulb_outline', createdAt: DateTime.now(), updatedAt: DateTime.now(), sortOrder: 2),
      FolderModel(id: AppConstants.folderDatathons, name: 'Datathon Experiments', colorHex: '#3B82F6', iconName: 'science_outlined', createdAt: DateTime.now(), updatedAt: DateTime.now(), sortOrder: 3),
      FolderModel(id: AppConstants.folderProjects, name: 'Projects', colorHex: '#F43F5E', iconName: 'work_outline', createdAt: DateTime.now(), updatedAt: DateTime.now(), sortOrder: 4),
      FolderModel(id: AppConstants.folderLanguage, name: 'Language Learning', colorHex: '#F59E0B', iconName: 'g_translate', createdAt: DateTime.now(), updatedAt: DateTime.now(), sortOrder: 5),
      FolderModel(id: AppConstants.folderPersonal, name: 'Personal Notes', colorHex: '#8B5CF6', iconName: 'book_outlined', createdAt: DateTime.now(), updatedAt: DateTime.now(), sortOrder: 6),
    ];
    for (var f in defaultFolders) {
      await saveFolder(f);
    }

    // 3. Seed Default Notes
    final defaultNotes = [
      NoteModel(
        id: uuid.v4(), folderId: AppConstants.folderAiMl, title: 'Machine Learning Basics',
        content: '# Machine Learning Basics\n\n## What I learned\nToday I reviewed the core concepts of Supervised vs Unsupervised learning.\n\n## Key concepts\n- **Supervised Learning**: Model learns on labeled data (e.g., classification, regression).\n- **Unsupervised Learning**: Model finds hidden patterns in unlabeled data (e.g., clustering, dimensionality reduction).\n\n## Next steps\nStudy gradient descent optimizations (SGD, Adam).',
        noteType: NoteType.markdown, tags: ['AI', 'ML', 'Basics'], attachments: [], templateId: 't-aiml',
        isPinned: true, isFavorite: true, colorHex: '#E0F2FE',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      NoteModel(
        id: uuid.v4(), folderId: AppConstants.folderDatathons, title: 'Titanic Dataset Plan',
        content: '# Titanic Dataset Plan\n\n## Goal\nPredict survival rates on the Titanic using passenger demographics.\n\n## Pipeline Steps\n1. Handle missing values (Age, Cabin, Embarked).\n2. Feature engineering: Extract Title from Name, create FamilySize.\n3. Model selection: Random Forest and LightGBM.\n4. Validation: 5-Fold Stratified Cross-Validation.',
        noteType: NoteType.markdown, tags: ['Kaggle', 'Titanic', 'EDA'], attachments: [], templateId: 't-datathon',
        isPinned: false, isFavorite: false, colorHex: '#FFF1F2',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      NoteModel(
        id: uuid.v4(), folderId: AppConstants.folderHackathons, title: 'Hackathon Pitch Idea',
        content: '# Problem\nUsers struggle to organize notes across multiple formats (voice, text, image, code) when learning new subjects quickly.\n\n# Proposed Solution\n**Gentle Notes**: A fluid, folder-based multi-format dashboard optimized for learners, featuring custom structured templates for fast documentation.',
        noteType: NoteType.markdown, tags: ['Idea', 'Pitch', 'Hackathon'], attachments: [], templateId: 't-hackathon',
        isPinned: true, isFavorite: true, colorHex: '#ECFDF5',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      NoteModel(
        id: uuid.v4(), folderId: AppConstants.folderDatathons, title: 'RandomForest Experiment Log',
        content: '# Experiment Name\nBaseline Random Forest Classifier\n\n# Dataset\nTitanic Passenger Cleaned v1\n\n# Preprocessing\n- Imputed Age with Median\n- One-Hot Encoded Sex and Embarked\n\n# Validation Score\nCV Accuracy: 0.812 (LB: 0.789)',
        noteType: NoteType.markdown, tags: ['RandomForest', 'Experiment'], attachments: [], templateId: 't-datathon',
        isPinned: false, isFavorite: false, colorHex: '#FDF4FF',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      NoteModel(
        id: uuid.v4(), folderId: AppConstants.folderLanguage, title: 'Spanish Vocabulary Practice',
        content: '# Spanish Vocabulary Practice\n\n## Basic Greetings & Phrases\n- **Hola**: Hello\n- **Buenos días**: Good morning\n- **Gracias**: Thank you\n- **Por favor**: Please\n- **¿Cómo estás?**: How are you?\n\n## Conjugation Practice (Present Tense - Hablar)\n- Yo hablo (I speak)\n- Tú hablas (You speak)\n- Él/Ella habla (He/She speaks)\n- Nosotros hablamos (We speak)\n- Ellos/Ellas hablan (They speak)',
        noteType: NoteType.mixed, tags: ['Spanish', 'Language', 'Vocabulary'], attachments: [], templateId: 't-language',
        isPinned: false, isFavorite: true, colorHex: '#FEF3C7',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        updatedAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ];
    for (var n in defaultNotes) {
      await saveNote(n);
    }

    await _sharedPrefs.setBool(AppConstants.prefHasSeededV1, true);
    await _seedV2IfNeeded();
  }

  Future<void> _seedV2IfNeeded() async {
    final bool hasSeededV2 = _sharedPrefs.getBool(AppConstants.prefHasSeededV2) ?? false;
    if (hasSeededV2) return;

    final stressNote = NoteModel(
      id: AppConstants.noteStressTest,
      folderId: AppConstants.folderAiMl,
      title: '🧪 Ultimate Notes App Stress Test Document',
      content: '''# 🧪 Ultimate Notes App Stress Test Document

***

## 🧱 1. Headings (All Levels)

# H1 Title
## H2 Subtitle
### H3 Section
#### H4 Subsection
##### H5 Detail
###### H6 Tiny

***

## ✍️ 2. Text Styles

* **Bold text**
* *Italic text*
* ***Bold + Italic***
* ~~Strikethrough~~
* `Inline code example`
* **Mixed `inline code` inside bold**

***

## 🔗 3. Links

* [Normal Hyperlink](https://www.google.com)
* Raw URL: <https://github.com>

***

## 📚 4. Lists

### ✅ Unordered
* Item 1
  * Sub item 1.1
    * Deep item 1.1.1
* Item 2

### 🔢 Ordered
1. First
2. Second
   1. Sub second
3. Third

### ☑️ Task List
* [x] Completed task
* [ ] Incomplete task

***

## 📊 5. Tables

| Feature     | Supported | Notes           |
| :---        | :----:    | ---:            |
| Markdown    | ✅         | Core format     |
| Code Blocks | ✅         | `code` test     |
| Tables      | ✅         | Alignment test  |
| Emojis 😎   | ✅         | Unicode support |

***

## 💻 6. Code Blocks

### 🐍 Python
```python
def fibonacci(n):
    a, b = 0, 1
    sequence = []
    for _ in range(n):
        sequence.append(a)
        a, b = b, a + b
    return sequence

print(fibonacci(10))
```

### 🌐 JavaScript
```javascript
const greet = (name) => {
  console.log(`Hello, \${name}! 🚀`);
};
greet("Faisal");
```

***

## 🎉 Done''',
      noteType: NoteType.markdown,
      tags: ['StressTest', 'Format', 'LaTeX', 'Tables'],
      attachments: [],
      templateId: null,
      isPinned: true,
      isFavorite: true,
      colorHex: '#F3E8FF',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await saveNote(stressNote);
    await _sharedPrefs.setBool(AppConstants.prefHasSeededV2, true);
  }

  List<NoteTemplateModel> _getBuiltInTemplatesData(Uuid uuid) {
    return [
      NoteTemplateModel(id: 't-aiml', name: 'AI/ML Learning Note', description: 'Template for keeping track of machine learning concepts, formulas, and next steps.', category: 'Learning', defaultTitle: 'ML Topic - [Topic Name]', defaultContent: '# Topic\n\n## What I learned\n\n## Key concepts\n\n## Code/Formula\n\n## Dataset/Example\n\n## Mistakes/Confusions\n\n## Next steps', defaultTags: ['AI', 'ML', 'Learning'], createdAt: DateTime.now(), updatedAt: DateTime.now(), isBuiltIn: true),
      NoteTemplateModel(id: 't-hackathon', name: 'Hackathon Idea Note', description: 'Brainstorm and draft ideas for hackathons with target user definition and submission strategies.', category: 'Hackathon', defaultTitle: 'Hackathon Idea - [Project Name]', defaultContent: '# Problem\n\n# Proposed Solution\n\n# Target Users\n\n# Dataset/API Needed\n\n# Features\n\n# Tech Stack\n\n# Team Roles\n\n# Submission Plan', defaultTags: ['Hackathon', 'Ideation'], createdAt: DateTime.now(), updatedAt: DateTime.now(), isBuiltIn: true),
      NoteTemplateModel(id: 't-datathon', name: 'Datathon Experiment Log', description: 'Track model hyperparameters, data preprocessing methods, and CV scores.', category: 'Data Science', defaultTitle: 'Experiment - [Model/Run Name]', defaultContent: '# Experiment Name\n\n# Dataset\n\n# Preprocessing\n\n# Model Used\n\n# Validation Score\n\n# What Improved\n\n# What Failed\n\n# Next Experiment', defaultTags: ['Datathon', 'Experiment', 'MLOps'], createdAt: DateTime.now(), updatedAt: DateTime.now(), isBuiltIn: true),
      NoteTemplateModel(id: 't-meeting', name: 'Project Meeting Note', description: 'Note template for organizing project meetings, meeting notes, action items, and deadlines.', category: 'Work', defaultTitle: 'Meeting - [Topic] - [Date]', defaultContent: '# Meeting Date\n\n# Members\n\n# Discussion Points\n\n# Decisions\n\n# Assigned Tasks\n\n# Deadline', defaultTags: ['Meeting', 'Project', 'Sync'], createdAt: DateTime.now(), updatedAt: DateTime.now(), isBuiltIn: true),
      NoteTemplateModel(id: 't-bug', name: 'Bug/Error Log', description: 'Document software bugs, environmental context, stack traces, and how you finally resolved them.', category: 'Development', defaultTitle: 'Bug - [Error Message]', defaultContent: '# Error\n\n# Context\n\n# Screenshot/Log\n\n# Possible Cause\n\n# Solution Tried\n\n# Final Fix', defaultTags: ['Bug', 'Debug', 'DevLog'], createdAt: DateTime.now(), updatedAt: DateTime.now(), isBuiltIn: true),
      NoteTemplateModel(id: 't-language', name: 'Language Practice Sheet', description: 'Template for vocabulary lists, grammar notes, and verb conjugations.', category: 'Learning', defaultTitle: 'Vocabulary - [Language/Topic]', defaultContent: '# Topic / Theme\n\n## Vocabulary List\n- Word/Phrase (Pronunciation) - Translation\n\n## Grammar Notes\n- Key rules and structures\n\n## Practice & Sentences\n- Example sentences', defaultTags: ['Language', 'Study', 'Vocabulary'], createdAt: DateTime.now(), updatedAt: DateTime.now(), isBuiltIn: true),
      NoteTemplateModel(id: 't-study', name: 'General Study Note', description: 'A versatile template for studying academic subjects, writing summaries, and listing revisions.', category: 'Learning', defaultTitle: 'Study - [Subject/Chapter]', defaultContent: '# Topic\n\n# Summary\n\n# Important Points\n\n# Examples\n\n# Questions\n\n# Revision Notes', defaultTags: ['Study', 'Notes', 'Reference'], createdAt: DateTime.now(), updatedAt: DateTime.now(), isBuiltIn: true),
      NoteTemplateModel(id: 't-journal', name: 'Daily Learning Journal', description: 'Simple journal template to track your personal day-to-day progress and goals.', category: 'Journal', defaultTitle: 'Journal - [Date]', defaultContent: '# Date\n\n# Today I learned\n\n# Practice done\n\n# Problems faced\n\n# Tomorrow plan', defaultTags: ['Journal', 'DailyLog', 'Goals'], createdAt: DateTime.now(), updatedAt: DateTime.now(), isBuiltIn: true),
      NoteTemplateModel(id: 't-research', name: 'Research Summary', description: 'Read and dissect research papers, noting methods, core takeaways, and limitations.', category: 'Research', defaultTitle: 'Paper Summary - [Title]', defaultContent: '# Paper/Article\n\n# Main idea\n\n# Method\n\n# Key findings\n\n# Limitations\n\n# How I can use this', defaultTags: ['Research', 'Paper', 'Academic'], createdAt: DateTime.now(), updatedAt: DateTime.now(), isBuiltIn: true),
      NoteTemplateModel(id: 't-code', name: 'Code Snippet Note', description: 'Document and explain reusable blocks of code for software engineering.', category: 'Development', defaultTitle: 'Snippet - [Functionality]', defaultContent: '# Snippet Title\n\n# Language\n\n# Use Case\n\n```\n// Code goes here\n```\n\n# Explanation\n\n# Related Links', defaultTags: ['Code', 'Snippet', 'Reference'], createdAt: DateTime.now(), updatedAt: DateTime.now(), isBuiltIn: true),
    ];
  }
}
