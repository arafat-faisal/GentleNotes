# GentleNotes Home Page Audit: Overview & Entry Points

This directory contains a detailed breakdown of the **Home Screen** in **GentleNotes**, a production-ready, offline-first notes and goals application built with Flutter, Riverpod, and Hive. 

This audit is organized in a modular structure to serve as a comprehensive knowledge injection source for an AI research agent.

---

## 📂 Audit Folder Structure

*   📁 [overview.md](file:///d:/WebProjects/GentleNotes/docs/home_page_audit/overview.md): High-level role of the Home Screen, file layout, and component map. (You are here)
*   📁 [ui_layouts.md](file:///d:/WebProjects/GentleNotes/docs/home_page_audit/ui_layouts.md): Visual design, widget composition, and detailed breakdown of the 7 dynamic layout presets.
*   📁 [state_connections.md](file:///d:/WebProjects/GentleNotes/docs/home_page_audit/state_connections.md): Reactive Riverpod providers, controllers, and real-time state filtering mechanisms.
*   📁 [navigation_map.md](file:///d:/WebProjects/GentleNotes/docs/home_page_audit/navigation_map.md): Deep-dive into page routing (`GoRouter`), app navigation chrome (`GentleScaffold`), and cross-feature routing.
*   📁 [suggestions_for_ai.md](file:///d:/WebProjects/GentleNotes/docs/home_page_audit/suggestions_for_ai.md): Actionable UX/UI enhancements, architectural improvements, and advanced features for next-step implementation.

---

## 🏛️ Central Role of the Home Screen

The Home Screen (`HomeScreen` in `lib/features/home/presentation/home_screen.dart`) serves as the core operational center of GentleNotes. It acts as:
1.  **A Portal to All Features**: Via persistent navigation (mobile bottom nav and desktop sidebar), the user accesses Notes, Folders, Templates, Goals, Planner, Settings, and About screens.
2.  **A Multi-Faceted Visual Dashboard**: Rather than a static list of files, it supports **7 distinct layout systems** tailored to different user behaviors (e.g., productivity-focused, chronological, or publishing/magazine-oriented).
3.  **A State Broker**: It binds local user intent (search queries, active category selections, tag filters) with reactive data layers to serve real-time content feeds.

---

## 📁 Source Code File Locations

The following map outlines the code repositories of the home feature:

| Path / File | Type | Purpose |
| :--- | :--- | :--- |
| [`lib/features/home/presentation/home_screen.dart`](file:///d:/WebProjects/GentleNotes/lib/features/home/presentation/home_screen.dart) | Entry Widget | Main parent scaffold, settings drawer bindings, action buttons, backup import hook. |
| [`lib/features/home/presentation/widgets/home_layout_switcher.dart`](file:///d:/WebProjects/GentleNotes/lib/features/home/presentation/widgets/home_layout_switcher.dart) | Presets Switcher | Intercepts current UI settings and renders the selected dashboard preset layout. |
| [`lib/features/home/presentation/widgets/layouts/`](file:///d:/WebProjects/GentleNotes/lib/features/home/presentation/widgets/layouts) | Presets Subfolder | Houses the 7 layout implementations. |
| [`lib/features/home/presentation/widgets/home_search_bar.dart`](file:///d:/WebProjects/GentleNotes/lib/features/home/presentation/widgets/home_search_bar.dart) | Search Component | Handles user text search input and horizontal tag filtering chips. |
| [`lib/features/home/presentation/widgets/stats_summary_grid.dart`](file:///d:/WebProjects/GentleNotes/lib/features/home/presentation/widgets/stats_summary_grid.dart) | Stats Component | Aggregates summary cards for notes, folders, templates, and favorites. |
| [`lib/features/home/presentation/widgets/quick_actions_bar.dart`](file:///d:/WebProjects/GentleNotes/lib/features/home/presentation/widgets/quick_actions_bar.dart) | Actions Component | Provides quick triggers (e.g. creating folders, opening calendar, manual import). |
| [`lib/features/home/presentation/widgets/folder_list_grid.dart`](file:///d:/WebProjects/GentleNotes/lib/features/home/presentation/widgets/folder_list_grid.dart) | Folders Component | Renders the folders collection, dynamically toggling list or grid based on user setting. |
| [`lib/features/home/presentation/widgets/note_list_view.dart`](file:///d:/WebProjects/GentleNotes/lib/features/home/presentation/widgets/note_list_view.dart) | Notes Feed | Feeds notes sorted chronologically. |
| [`lib/features/home/presentation/widgets/folder_card.dart`](file:///d:/WebProjects/GentleNotes/lib/features/home/presentation/widgets/folder_card.dart) | Visual Card | Renders visual details of folder items (color tags, note counts, custom icons). |
| [`lib/features/home/presentation/widgets/note_card.dart`](file:///d:/WebProjects/GentleNotes/lib/features/home/presentation/widgets/note_card.dart) | Visual Card | Renders summaries of individual notes (title, snippet, folder tag, favorite icon). |

---

## 🛠️ Main Scaffolding Configuration

In [`home_screen.dart`](file:///d:/WebProjects/GentleNotes/lib/features/home/presentation/home_screen.dart), the screen structure is encapsulated within a global Custom widget, [`GentleScaffold`](file:///d:/WebProjects/GentleNotes/lib/shared/widgets/gentle_scaffold.dart), which provides:
*   **Title**: `"Gentle Notes"`
*   **FloatingActionButton**: An extended FAB reading `"New Note"`, navigating directly to `/notes/create`.
*   **AppBar Actions**:
    1.  **Import Action** (`IconButton` with `Icons.download_rounded`): Hooks into [`ExportImportService`](file:///d:/WebProjects/GentleNotes/lib/core/services/export_import_service.dart) to trigger manual import, and reactively calls folders/notes controller reloads.
    2.  **Settings Action** (`IconButton` with `Icons.settings`): Deep-links straight to the settings feature `/settings`.
*   **Scaffold Body**: Dynamically points to `HomeLayoutSwitcher` which consumes the layout state to render the selected user interface.
