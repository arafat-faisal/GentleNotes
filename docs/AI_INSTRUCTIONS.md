# AI Coding Assistant Guidelines & Workspace Rules

This document serves as the single source of truth for AI agents (e.g., Antigravity) working on the **GentleNotes** codebase. Read and follow these architectural guidelines, UI standards, and data formatting rules to avoid regressions.

---

## 🎨 UI/UX & Design Guidelines

### 1. Safe Area & Display Boundaries
* **Mandatory SafeArea**: Always wrap full-screen Scaffold bodies or tab views (like `TabBarView` inside `_ArticleDetailPage`) in a `SafeArea` widget. Never let interactive elements (toolbars, list items, action buttons) bleed under the physical device notch, status bar, or bottom system navigation overlays.
* **Layout Sizing**: Ensure sizing is responsive and respects phone aspect ratios. Do not set absolute heights on containers holding scrollable lists or editors.

### 2. Premium Dark/Light Aesthetics
* Use vibrant, curated colors and sleek dark modes. Avoid generic system colors (pure red, blue, green).
* Use the HSL-tailored color schemes and variables defined in [`lib/core/theme/app_colors.dart`](file:///d:/WebProjects/GentleNotes/lib/core/theme/app_colors.dart).
* Use modern typography (Outfit/Inter fonts) instead of browser/system defaults.

### 3. Integrated Browsing & Manual Control
* **No Auto-Launch Loops**: Never auto-launch the integrated browser or system custom tabs inside widget lifecycle states (`initState` or `didUpdateWidget`). Doing so causes infinite redirection loops.
* **Explicit Tap Only**: Always require an explicit user tap (e.g., "Open in Browser" button) to navigate to web links, keeping the landing cards clean and leaving navigation entirely under user control.

---

## 📝 Note System & Rich-Text Editor

### 1. Document Format & JSON Delta Encoding
* **Quill Delta Objects**: Rich-text notes in the app are stored as standard Quill delta JSON objects:
  ```json
  {"ops": [{"insert": "Text\n", "attributes": {"bold": true}}]}
  ```
* **No Double Encoding**: Do not wrap existing delta JSON inside text insert blocks when saving. Always verify if the content already represents a JSON object structure before writing.

### 2. Plain Text Conversion
* When reading note content for search indexing or card previews, use the `NoteModel.plainText` getter. 
* It is configured to safely decode both standard Quill JSON objects `{"ops": [...]}` and legacy array formats `[...]` to clean plain text. Keep this parser intact in [`lib/features/notes/data/models/note_model.dart`](file:///d:/WebProjects/GentleNotes/lib/features/notes/data/models/note_model.dart).

### 3. Standard Editor Components
* **Quill Editor Use**: Never use raw, plain `TextField` elements for notes. Always implement the standard rich-text system:
  * [`QuillEditor.basic`](file:///d:/WebProjects/GentleNotes/lib/features/editor/presentation/widgets/editor_body_widget.dart) for text entry.
  * [`QuillSimpleToolbar`](file:///d:/WebProjects/GentleNotes/lib/features/editor/presentation/widgets/layouts/classic/classic_header.dart) for inline format selectors (Bold, Italic, Header, lists, links).
* **Note Creation**: When creating a note programmatically, always set the type to **`NoteType.mixed`** so it launches in rich-text mode in the main notes manager.
* **Link Insertion**: To link resources or pages in the editor, use Quill's native `LinkAttribute`:
  ```dart
  _quillCtrl.formatText(position, length, LinkAttribute(url));
  ```
  Do not append raw markdown strings (e.g. `[Title](url)`) inside rich-text documents.

---

## 🛠️ Build, Play Store & Git Workflows

### 1. Play Store Release Configurations
* **Target SDK**: Google Play requires target SDK 34+. The app uses **`targetSdk = 35`** and **`compileSdk = 36`** in [`android/app/build.gradle.kts`](file:///d:/WebProjects/GentleNotes/android/app/build.gradle.kts).
* **Signing Keystore**: Release builds use the keystore at `android/app/upload-keystore.jks` with password/alias `gentlenotespass` / `upload`. Ensure this configuration remains unmodified.
* **Release Testing**: Verify release compilation by building the appbundle using the production flavor target:
  ```powershell
  flutter build appbundle --flavor prod -t lib/main_prod.dart --debug
  ```

### 2. Git Branch Rule
* **develop Branch**: Always implement, debug, and test code changes directly on the **`develop`** branch.
* **main Branch**: Keep `main` reserved for production releases. When a feature is complete and verified:
  1. Commit and push changes to `develop`.
  2. Switch to `main`, merge `develop`, and push `main` to GitHub.
  3. Return to `develop` before completing your turn.
