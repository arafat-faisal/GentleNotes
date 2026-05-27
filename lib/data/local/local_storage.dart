import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart';

class LocalStorage {
  static const String _foldersBoxName = 'gentle_folders_box_v1';
  static const String _notesBoxName = 'gentle_notes_box_v1';
  static const String _templatesBoxName = 'gentle_templates_box_v1';
  static const String _settingsBoxName = 'gentle_settings_box_v1';

  late Box _foldersBox;
  late Box _notesBox;
  late Box _templatesBox;
  late Box _settingsBox;
  late SharedPreferences _sharedPrefs;

  static final LocalStorage _instance = LocalStorage._internal();

  factory LocalStorage() {
    return _instance;
  }

  LocalStorage._internal();

  Future<void> init() async {
    await Hive.initFlutter();
    
    _foldersBox = await Hive.openBox(_foldersBoxName);
    _notesBox = await Hive.openBox(_notesBoxName);
    _templatesBox = await Hive.openBox(_templatesBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _sharedPrefs = await SharedPreferences.getInstance();

    await _seedInitialDataIfNeeded();
  }

  // --- SETTINGS STORAGE ---

  AppSettingsModel getSettings() {
    final theme = _sharedPrefs.getString('themeMode') ?? 'system';
    final accent = _sharedPrefs.getString('accentColorHex') ?? '#6366F1';
    final layout = _sharedPrefs.getString('layoutMode') ?? 'grid';
    final editor = _sharedPrefs.getString('editorMode') ?? 'markdown';
    final noteType = _sharedPrefs.getString('defaultNoteType') ?? 'mixed';
    final autoSave = _sharedPrefs.getBool('autoSaveEnabled') ?? true;
    final codeTheme = _sharedPrefs.getString('activeCodeTheme') ?? 'vs-dark';

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

  Future<void> saveSettings(AppSettingsModel settings) async {
    await _sharedPrefs.setString('themeMode', settings.themeMode.name);
    await _sharedPrefs.setString('accentColorHex', settings.accentColorHex);
    await _sharedPrefs.setString('layoutMode', settings.layoutMode.name);
    await _sharedPrefs.setString('editorMode', settings.editorMode.name);
    await _sharedPrefs.setString('defaultNoteType', settings.defaultNoteType.name);
    await _sharedPrefs.setBool('autoSaveEnabled', settings.autoSaveEnabled);
    await _sharedPrefs.setString('activeCodeTheme', settings.activeCodeTheme);
  }

  // --- USER ROLE STORAGE ---

  UserRole getUserRole() {
    final roleStr = _sharedPrefs.getString('userRole') ?? 'subscriber'; // default role is subscriber for demo
    return UserRole.values.firstWhere((e) => e.name == roleStr, orElse: () => UserRole.subscriber);
  }

  Future<void> saveUserRole(UserRole role) async {
    await _sharedPrefs.setString('userRole', role.name);
  }

  // --- FOLDERS DATA ---

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

  Future<void> saveFolder(FolderModel folder) async {
    await _foldersBox.put(folder.id, folder.toMap());
  }

  Future<void> deleteFolder(String id) async {
    await _foldersBox.delete(id);
    // Also remove notes pointing to this folder or set their folderId to null
    final notes = getNotes().where((n) => n.folderId == id);
    for (var note in notes) {
      await saveNote(note.copyWith(folderId: null));
    }
  }

  // --- NOTES DATA ---

  List<NoteModel> getNotes() {
    final List<NoteModel> notes = [];
    for (var key in _notesBox.keys) {
      final val = _notesBox.get(key);
      if (val is Map) {
        notes.add(NoteModel.fromMap(Map<String, dynamic>.from(val)));
      }
    }
    // Sort recent first by default
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  Future<void> saveNote(NoteModel note) async {
    await _notesBox.put(note.id, note.toMap());
  }

  Future<void> deleteNote(String id) async {
    await _notesBox.delete(id);
  }

  // --- TEMPLATES DATA ---

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

  Future<void> saveTemplate(NoteTemplateModel template) async {
    await _templatesBox.put(template.id, template.toMap());
  }

  Future<void> deleteTemplate(String id) async {
    if (getTemplates().firstWhere((t) => t.id == id).isBuiltIn) {
      // Don't delete built-in templates
      return;
    }
    await _templatesBox.delete(id);
  }

  // --- SEED INITIAL DATA ---

  Future<void> _seedInitialDataIfNeeded() async {
    final bool hasRunBefore = _sharedPrefs.getBool('has_seeded_v1') ?? false;
    if (hasRunBefore) return;

    final uuid = const Uuid();

    // 1. Seed Built-In Templates
    final builtInTemplates = _getBuiltInTemplatesData(uuid);
    for (var t in builtInTemplates) {
      await saveTemplate(t);
    }

    // 2. Seed Default Folders
    final defaultFolders = [
      FolderModel(
        id: 'f-aiml',
        name: 'AI/ML Learning',
        colorHex: '#6366F1', // Indigo
        iconName: 'psychology_outlined',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sortOrder: 1,
      ),
      FolderModel(
        id: 'f-hackathons',
        name: 'Hackathon Ideas',
        colorHex: '#10B981', // Emerald
        iconName: 'lightbulb_outline',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sortOrder: 2,
      ),
      FolderModel(
        id: 'f-datathons',
        name: 'Datathon Experiments',
        colorHex: '#3B82F6', // Blue
        iconName: 'science_outlined',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sortOrder: 3,
      ),
      FolderModel(
        id: 'f-projects',
        name: 'Projects',
        colorHex: '#F43F5E', // Rose
        iconName: 'work_outline',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sortOrder: 4,
      ),
      FolderModel(
        id: 'f-language',
        name: 'Language Learning',
        colorHex: '#F59E0B', // Amber
        iconName: 'g_translate',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sortOrder: 5,
      ),
      FolderModel(
        id: 'f-personal',
        name: 'Personal Notes',
        colorHex: '#8B5CF6', // Purple
        iconName: 'book_outlined',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sortOrder: 6,
      ),
    ];

    for (var f in defaultFolders) {
      await saveFolder(f);
    }

    // 3. Seed Default Notes
    final defaultNotes = [
      NoteModel(
        id: uuid.v4(),
        folderId: 'f-aiml',
        title: 'Machine Learning Basics',
        content: '# Machine Learning Basics\n\n## What I learned\nToday I reviewed the core concepts of Supervised vs Unsupervised learning.\n\n## Key concepts\n- **Supervised Learning**: Model learns on labeled data (e.g., classification, regression).\n- **Unsupervised Learning**: Model finds hidden patterns in unlabeled data (e.g., clustering, dimensionality reduction).\n\n## Next steps\nStudy gradient descent optimizations (SGD, Adam).',
        noteType: NoteType.markdown,
        tags: ['AI', 'ML', 'Basics'],
        attachments: [],
        templateId: 't-aiml',
        isPinned: true,
        isFavorite: true,
        colorHex: '#E0F2FE', // soft blue note
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      NoteModel(
        id: uuid.v4(),
        folderId: 'f-datathons',
        title: 'Titanic Dataset Plan',
        content: '# Titanic Dataset Plan\n\n## Goal\nPredict survival rates on the Titanic using passenger demographics.\n\n## Pipeline Steps\n1. Handle missing values (Age, Cabin, Embarked).\n2. Feature engineering: Extract Title from Name, create FamilySize.\n3. Model selection: Random Forest and LightGBM.\n4. Validation: 5-Fold Stratified Cross-Validation.',
        noteType: NoteType.markdown,
        tags: ['Kaggle', 'Titanic', 'EDA'],
        attachments: [],
        templateId: 't-datathon',
        isPinned: false,
        isFavorite: false,
        colorHex: '#FFF1F2', // soft rose
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      NoteModel(
        id: uuid.v4(),
        folderId: 'f-hackathons',
        title: 'Hackathon Pitch Idea',
        content: '# Problem\nUsers struggle to organize notes across multiple formats (voice, text, image, code) when learning new subjects quickly.\n\n# Proposed Solution\n**Gentle Notes**: A fluid, folder-based multi-format dashboard optimized for learners, featuring custom structured templates for fast documentation.',
        noteType: NoteType.markdown,
        tags: ['Idea', 'Pitch', 'Hackathon'],
        attachments: [],
        templateId: 't-hackathon',
        isPinned: true,
        isFavorite: true,
        colorHex: '#ECFDF5', // soft emerald
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      NoteModel(
        id: uuid.v4(),
        folderId: 'f-datathons',
        title: 'RandomForest Experiment Log',
        content: '# Experiment Name\nBaseline Random Forest Classifier\n\n# Dataset\nTitanic Passenger Cleaned v1\n\n# Preprocessing\n- Imputed Age with Median\n- One-Hot Encoded Sex and Embarked\n\n# Validation Score\nCV Accuracy: 0.812 (LB: 0.789)',
        noteType: NoteType.markdown,
        tags: ['RandomForest', 'Experiment'],
        attachments: [],
        templateId: 't-datathon',
        isPinned: false,
        isFavorite: false,
        colorHex: '#FDF4FF', // soft purple
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      NoteModel(
        id: uuid.v4(),
        folderId: 'f-language',
        title: 'Spanish Vocabulary Practice',
        content: '# Spanish Vocabulary Practice\n\n## Basic Greetings & Phrases\n- **Hola**: Hello\n- **Buenos días**: Good morning\n- **Gracias**: Thank you\n- **Por favor**: Please\n- **¿Cómo estás?**: How are you?\n\n## Conjugation Practice (Present Tense - Hablar)\n- Yo hablo (I speak)\n- Tú hablas (You speak)\n- Él/Ella habla (He/She speaks)\n- Nosotros hablamos (We speak)\n- Ellos/Ellas hablan (They speak)',
        noteType: NoteType.mixed,
        tags: ['Spanish', 'Language', 'Vocabulary'],
        attachments: [],
        templateId: 't-language',
        isPinned: false,
        isFavorite: true,
        colorHex: '#FEF3C7', // soft amber
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        updatedAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ];

    for (var n in defaultNotes) {
      await saveNote(n);
    }

    // Seed V2 Stress Test Note
    final bool hasSeededV2 = _sharedPrefs.getBool('has_seeded_v2') ?? false;
    if (!hasSeededV2) {
      final stressNote = NoteModel(
        id: 'n-stress-test',
        folderId: 'f-aiml',
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
* <u>Underline (HTML)</u>
* `Inline code example`
* **Mixed `inline code` inside bold**
* **Nested formatting: **bold** and *italic* and `code` inside one paragraph**

***

## 🔗 3. Links

* [Normal Hyperlink](https://www.google.com)
* Raw URL: <https://github.com>
* Anchor link: [H1 Title](#h1-title)

***

## 📚 4. Lists

### ✅ Unordered
* Item 1
  * Sub item 1.1
    * Deep item 1.1.1
      * Extremely deep item 1.1.1.1
* Item 2

### 🔢 Ordered
1. First
2. Second
   1. Sub second
   2. Sub second 2
3. Third

### ☑️ Task List
* [x] Completed task
* [ ] Incomplete task
* [ ] Another task

***

## 📊 5. Tables

| Feature     | Supported | Notes           |
| :---        | :----:    | ---:            |
| Markdown    | ✅         | Core format     |
| Code Blocks | ✅         | `code` test     |
| Tables      | ✅         | Alignment test  |
| Emojis 😎   | ✅         | Unicode support |

***

## 💻 6. Code Blocks (Multi-Language)

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

### ⚙️ C++
```cpp
#include <iostream>
using namespace std;

int main() {
    cout << "Hello World!" << endl;
    return 0;
}
```

### ☕ Java
```java
public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello, World!");
    }
}
```

### 🐘 SQL
```sql
SELECT users.name, orders.total
FROM users
INNER JOIN orders ON users.id = orders.user_id
WHERE orders.total > 1000
ORDER BY orders.total DESC;
```

### 📦 JSON
```json
{
  "app": "Gentle Notes",
  "version": "1.0",
  "features": ["notes", "folders", "themes", "sharing"],
  "active": true
}
```

### 🛠️ Bash/Shell
```bash
echo "Testing nested blocks"
mkdir -p /tmp/gentle-notes
```

***

## 🧩 7. Blockquotes

> This is a simple quote.

> Nested quote:
>
> > Level 2
> >
> > > Level 3

***

## 🧮 8. Math / LaTeX

Inline:  
\$E = mc^2\$

Block:

\$\$
\\int_0^\\infty e^{-x} dx = 1
\$\$

Matrix:

\$\$
\\begin{bmatrix}
1 & 2 \\\\
3 & 4
\\end{bmatrix}
\$\$

***

## 🎨 9. Mixed Content Block

> 🚀 **Important Notice**
>
> * Ensure rendering supports:
>   * `inline code`
>   * emojis 😄
>   * **nested formatting**
>
> Example:
>
> ```bash
> echo "Testing nested blocks"
> ```

***

## 🔣 10. Special Characters

```
! @ # \$ % ^ & * ( ) _ + - = { } [ ] | \\ : ; " ' < > , . ? /
```

Unicode:

* বাংলা text: আমি একজন ডেভেলপার
* Japanese: こんにちは
* Arabic: مرحبا
* Emoji mix: 🚀🔥💡📦🧠⚡

***

## 🧵 11. Horizontal Rules

***
---
___

***

## 🧪 12. Edge Cases

### Extremely Long Line
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

### Nested Everything
* Item
  * **Bold**
    * *Italic*
      * `Code`
        * <https://example.com>

### Repeated Inline Code
`1``2``3``4``5``6``7``8``9``10``11``12``13``14``15``16``17``18``19``20`

### Emoji Flood
😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄

***

## 📌 13. HTML Embeds

<div style="color: red; font-weight: bold;">
This is raw HTML styled text.
</div>

<details>
<summary>Click to expand</summary>

Hidden content here 👀

</details>

***

## 🧠 14. Pseudo Markdown + Code Mix

```md
# This is a markdown block inside a code block
- It should NOT render
- Only display as text
```

***

## 🧷 15. File-like Snippets

### `.env`
```
API_KEY=1234567890
SECRET_KEY=abcdef
DEBUG=true
```

### `.yaml`
```yaml
app:
  name: GentleNotes
  version: 1.0
  features:
    - notes
    - folders
    - sync
```

***

## 🎉 Done''',
        noteType: NoteType.markdown,
        tags: ['StressTest', 'Format', 'LaTeX', 'Tables'],
        attachments: [],
        templateId: null,
        isPinned: true,
        isFavorite: true,
        colorHex: '#F3E8FF', // Soft purple
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await saveNote(stressNote);
      await _sharedPrefs.setBool('has_seeded_v2', true);
    }

    await _sharedPrefs.setBool('has_seeded_v1', true);
  }

  List<NoteTemplateModel> _getBuiltInTemplatesData(Uuid uuid) {
    return [
      NoteTemplateModel(
        id: 't-aiml',
        name: 'AI/ML Learning Note',
        description: 'Template for keeping track of machine learning concepts, formulas, and next steps.',
        category: 'Learning',
        defaultTitle: 'ML Topic - [Topic Name]',
        defaultContent: '# Topic\n\n## What I learned\n\n## Key concepts\n\n## Code/Formula\n\n## Dataset/Example\n\n## Mistakes/Confusions\n\n## Next steps',
        defaultTags: ['AI', 'ML', 'Learning'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isBuiltIn: true,
      ),
      NoteTemplateModel(
        id: 't-hackathon',
        name: 'Hackathon Idea Note',
        description: 'Brainstorm and draft ideas for hackathons with target user definition and submission strategies.',
        category: 'Hackathon',
        defaultTitle: 'Hackathon Idea - [Project Name]',
        defaultContent: '# Problem\n\n# Proposed Solution\n\n# Target Users\n\n# Dataset/API Needed\n\n# Features\n\n# Tech Stack\n\n# Team Roles\n\n# Submission Plan',
        defaultTags: ['Hackathon', 'Ideation'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isBuiltIn: true,
      ),
      NoteTemplateModel(
        id: 't-datathon',
        name: 'Datathon Experiment Log',
        description: 'Track model hyperparameters, data preprocessing methods, and CV scores.',
        category: 'Data Science',
        defaultTitle: 'Experiment - [Model/Run Name]',
        defaultContent: '# Experiment Name\n\n# Dataset\n\n# Preprocessing\n\n# Model Used\n\n# Validation Score\n\n# What Improved\n\n# What Failed\n\n# Next Experiment',
        defaultTags: ['Datathon', 'Experiment', 'MLOps'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isBuiltIn: true,
      ),
      NoteTemplateModel(
        id: 't-meeting',
        name: 'Project Meeting Note',
        description: 'Note template for organizing project meetings, meeting notes, action items, and deadlines.',
        category: 'Work',
        defaultTitle: 'Meeting - [Topic] - [Date]',
        defaultContent: '# Meeting Date\n\n# Members\n\n# Discussion Points\n\n# Decisions\n\n# Assigned Tasks\n\n# Deadline',
        defaultTags: ['Meeting', 'Project', 'Sync'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isBuiltIn: true,
      ),
      NoteTemplateModel(
        id: 't-bug',
        name: 'Bug/Error Log',
        description: 'Document software bugs, environmental context, stack traces, and how you finally resolved them.',
        category: 'Development',
        defaultTitle: 'Bug - [Error Message]',
        defaultContent: '# Error\n\n# Context\n\n# Screenshot/Log\n\n# Possible Cause\n\n# Solution Tried\n\n# Final Fix',
        defaultTags: ['Bug', 'Debug', 'DevLog'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isBuiltIn: true,
      ),
      NoteTemplateModel(
        id: 't-language',
        name: 'Language Practice Sheet',
        description: 'Template for vocabulary lists, grammar notes, and verb conjugations.',
        category: 'Learning',
        defaultTitle: 'Vocabulary - [Language/Topic]',
        defaultContent: '# Topic / Theme\n\n## Vocabulary List\n- Word/Phrase (Pronunciation) - Translation\n\n## Grammar Notes\n- Key rules and structures\n\n## Practice & Sentences\n- Example sentences',
        defaultTags: ['Language', 'Study', 'Vocabulary'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isBuiltIn: true,
      ),
      NoteTemplateModel(
        id: 't-study',
        name: 'General Study Note',
        description: 'A versatile template for studying academic subjects, writing summaries, and listing revisions.',
        category: 'Learning',
        defaultTitle: 'Study - [Subject/Chapter]',
        defaultContent: '# Topic\n\n# Summary\n\n# Important Points\n\n# Examples\n\n# Questions\n\n# Revision Notes',
        defaultTags: ['Study', 'Notes', 'Reference'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isBuiltIn: true,
      ),
      NoteTemplateModel(
        id: 't-journal',
        name: 'Daily Learning Journal',
        description: 'Simple journal template to track your personal day-to-day progress and goals.',
        category: 'Journal',
        defaultTitle: 'Journal - [Date]',
        defaultContent: '# Date\n\n# Today I learned\n\n# Practice done\n\n# Problems faced\n\n# Tomorrow plan',
        defaultTags: ['Journal', 'DailyLog', 'Goals'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isBuiltIn: true,
      ),
      NoteTemplateModel(
        id: 't-research',
        name: 'Research Summary',
        description: 'Read and dissect research papers, noting methods, core takeaways, and limitations.',
        category: 'Research',
        defaultTitle: 'Paper Summary - [Title]',
        defaultContent: '# Paper/Article\n\n# Main idea\n\n# Method\n\n# Key findings\n\n# Limitations\n\n# How I can use this',
        defaultTags: ['Research', 'Paper', 'Academic'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isBuiltIn: true,
      ),
      NoteTemplateModel(
        id: 't-code',
        name: 'Code Snippet Note',
        description: 'Document and explain reusable blocks of code for software engineering.',
        category: 'Development',
        defaultTitle: 'Snippet - [Functionality]',
        defaultContent: '# Snippet Title\n\n# Language\n\n# Use Case\n\n```\n// Code goes here\n```\n\n# Explanation\n\n# Related Links',
        defaultTags: ['Code', 'Snippet', 'Reference'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isBuiltIn: true,
      ),
    ];
  }
}
