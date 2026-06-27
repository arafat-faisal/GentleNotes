# GentleNotes Home Screen Architectural Audit

This document provides a comprehensive audit of the Home screen, detailing its layout systems, visual designs, dependencies, state management connections, and integration with the rest of the **GentleNotes** application.

---

## 1. File Structure & Organization

The Home feature is located within `lib/features/home/` and is divided as follows:

*   **`lib/features/home/presentation/home_screen.dart`**: The main entry point containing the parent `HomeScreen` class (a `ConsumerStatefulWidget`), which sets up the overall scaffolding (AppBar title, main actions, and FAB).
*   **`lib/features/home/presentation/widgets/home_layout_switcher.dart`**: A consumer widget that dynamically swaps the active body layout based on the user's settings preset.
*   **`lib/features/home/presentation/widgets/layouts/`**: Subfolder containing the 7 distinct layout options:
    *   `home_calendar_layout.dart`
    *   `home_compact_layout.dart`
    *   `home_focus_layout.dart`
    *   `home_magazine_layout.dart`
    *   `home_notebook_layout.dart`
    *   `home_calendar_layout.dart`
    *   `home_compact_layout.dart`
*   **`lib/features/home/presentation/widgets/`**: Reusable subcomponents displayed inside layouts:
    *   `home_search_bar.dart` (Search text input and horizontal tag filter chips)
    *   `stats_summary_grid.dart` (Summary showing total notes, folders, and study hours)
    *   `quick_actions_bar.dart` (Shortcuts for study hub, quick templates, drawing pads)
    *   `folder_list_grid.dart` (Renders folders in List or Grid mode depending on configuration)
    *   `note_list_view.dart` (Lists notes sequentially)
    *   `folder_card.dart` & `note_card.dart` (Card item visual wrappers)

---

## 2. Dynamic Layout Presets

The app features a highly customizable layout system driven by the `HomeLayoutPreset` enum. The active layout is looked up reactively from `settingsProvider`.

### 1. Dashboard Layout (`home_dashboard_layout.dart`)
*   **Visual Structure**: Vertical scrolling feed organized into sections.
*   **Components**: Search bar -> Tag chips -> Stats grid -> Quick actions row -> Folders shelf -> Recent notes list.
*   **Aesthetic**: Comprehensive, information-rich look suitable for a landing hub.
*   **Interaction**: Features a grid/list toggle for folders which persists in `settingsProvider`.

### 2. Focus Layout (`home_focus_layout.dart`)
*   **Visual Structure**: Highly minimal view designed for distraction-free reading/writing.
*   **Components**: Headline Focus banner -> Daily productivity quote card -> Search bar -> Pinned Focus Tasks.
*   **Aesthetic**: Clean, spacious padding. It filters out non-pinned notes, showing only notes designated as active tasks.
*   **Unique Feature**: Selects a daily motivational quote based on the current day index.

### 3. Notebook Shelves Layout (`home_notebook_layout.dart`)
*   **Visual Structure**: Horizontal folder categories combined with a foldered list.
*   **Components**: Headline banner -> Horizontal scrollable Folder Shelf (representing folder cards with custom colors/icons) -> Foldered notes list.
*   **Aesthetic**: Visual representation of physical notebooks on shelves.
*   **Interaction**: Tapping a folder tab filters the recent notes feed in real-time. Selecting "All Folders" resets the filter.

### 4. Magazine Layout (`home_magazine_layout.dart`)
*   **Visual Structure**: Asymmetric editorial layout.
*   **Components**: Search bar -> "Featured Cover" (a hero card representation of the most recently updated note) -> "Recent Articles" grid.
*   **Aesthetic**: High-end publication feel with larger imagery/margins. 
*   **Unique Feature**: The Hero Card features a dynamic background gradient constructed directly from the note's custom color code.

### 5. Calendar Layout (`home_calendar_layout.dart`)
*   **Visual Structure**: Time-based planner view.
*   **Components**: Daily planner banner -> Horizontal 7-day calendar carousel -> Selected date notes list.
*   **Aesthetic**: Organizer-book style.
*   **Unique Feature**: Allows users to tap on dates in the carousel to see exactly what notes were modified on those specific days.

### 6. Compact Layout (`home_compact_layout.dart`)
*   **Visual Structure**: High-density view.
*   **Aesthetic**: Minimizes padding, font sizes, and list margins, showing more elements on small screen form factors.

### 7. Minimal Feed Layout (`home_minimal_feed_layout.dart`)
*   **Visual Structure**: Simple vertical stream.
*   **Aesthetic**: Excludes stats, folders, and actions, displaying only a simple search bar followed by a vertical scroll of notes.

---

## 3. Riverpod State Connections

The Home screen acts as a central consumer of global application states:

1.  **`settingsProvider`**: Tracks UI configuration presets (`homeLayout`, `layoutMode`, theme settings). Modifying presets updates the layout dynamically.
2.  **`foldersProvider`**: Manages the list of folders. Tapping a folder card navigates to `/folders/:id`.
3.  **`filteredNotesProvider`**: Synthesizes notes reactively based on `notesProvider` (all notes), `searchQueryProvider` (active search bar string), and `selectedTagFilterProvider` (selected tag chip). Whenever the search bar text changes or a tag chip is selected, the list of notes on the Home screen updates instantly.

---

## 4. Navigation & Connection Map

The Home Screen serves as the root router hub of the application:

*   **FAB ("New Note")**: Navigates to `/notes/create`.
*   **Settings Icon (AppBar)**: Navigates to `/settings`.
*   **Import Icon (AppBar)**: Invokes `ExportImportService().pickAndImportFile()` to restore a backup or import external markdown files, then triggers folder and note reloading.
*   **NoteCard Tap**: Navigates to `/notes/edit/:id` (opens the editor workspace for that note).
*   **FolderCard Tap**: Navigates to `/folders/:id` (opens folder details showing files nested inside it).
*   **Quick Actions Bar**:
    *   *Study Hub*: Navigates to PDF workspaces/folders.
    *   *Templates*: Navigates to `/templates` to view and choose note structures.
    *   *Planner*: Navigates to `/planner` (Daily schedule, calendar timeline, and reminders).
    *   *Goals*: Navigates to `/goals` (Goals Dashboard).

---

## 5. Potential UI/UX Enhancements for AI Research

Here are some architectural improvements that can be suggested to an AI model for research and implementation:

1.  **Drag-and-Drop Reordering**: Allow drag-and-drop actions directly on the FolderListGrid to customize sorting orders.
2.  **Interactive Widgets**: Implement quick-actions directly from the stats grid (e.g., tapping "Study Hours" launches a study-timer bottom sheet).
3.  **Search Indexing**: Refactor the simple text filter inside `filteredNotesProvider` to use a tokenized local search index (e.g., matching titles, tags, and body text with relevance scoring).
4.  **Swipe Quick-Actions**: Integrate swipe-to-delete, swipe-to-pin, or swipe-to-favorite actions directly on the Home screen note items.
5.  **Multi-Select Mode**: Support long-pressing note cards on the home screen to enter a batch selection state (allowing mass-deletion, moving to folders, or merging notes).
