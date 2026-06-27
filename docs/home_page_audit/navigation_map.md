# GentleNotes Home Page Audit: Navigation & Connection Map

The Home Screen is the traffic controller of GentleNotes. It functions as the root routing hub, launching editors, detail portals, and configuring platform-wide navigation layouts.

---

## 🧭 GoRouter Configuration & Path Mapping

All route bindings are configured centrally inside [`router.dart`](file:///d:/WebProjects/GentleNotes/lib/app/router.dart). The Home Screen links directly or indirectly to the following routes:

| Route Path | Screen Widget Class | Navigation Trigger Source | Navigation Method |
| :--- | :--- | :--- | :--- |
| `/home` | `HomeScreen` | Root Redirect / Navigation chrome | `context.go('/home')` |
| `/notes/create` | `EditorScreen(noteId: null)` | Extended FAB ("New Note") | `context.push('/notes/create')` |
| `/notes/edit/:id` | `EditorScreen(noteId: id)` | Tapping any `NoteCard` | `context.push('/notes/edit/:id')` |
| `/folders/:id` | `FolderDetailScreen` | Tapping `FolderCard` or Sidebar Folder List | `context.go('/folders/:id')` |
| `/templates` | `TemplatesScreen` | Quick Actions Bar / Mobile Bottom Nav / Sidebar | `context.go('/templates')` |
| `/goals` | `GoalsDashboardScreen` | Mobile Bottom Nav / Sidebar | `context.go('/goals')` |
| `/planner` | `PlannerScreen` | Mobile Bottom Nav / Sidebar | `context.go('/planner')` |
| `/calendar` | `CalendarScreen` | Quick Actions Bar | `context.go('/calendar')` |
| `/settings` | `SettingsScreen` | AppBar settings cog / Bottom Nav / Sidebar | `context.go('/settings')` |
| `/about` | `AboutScreen` | Sidebar (Desktop) | `context.go('/about')` |
| `/pdf-reader` | `PdfReaderWorkspaceScreen` | Platform-level share deep link receiver | `router.push('/pdf-reader?path=...')` |

---

## 🏛️ Persistent Scaffold Chrome (`GentleScaffold`)

Individual page views inside GentleNotes do not define their own top headers or navigation layouts. Instead, pages are wrapped in a generic custom widget: [`GentleScaffold`](file:///d:/WebProjects/GentleNotes/lib/shared/widgets/gentle_scaffold.dart). This scaffold dynamically determines the client device's form factor via `ResponsiveHelper` and swaps UI paradigms.

### 📱 1. Mobile & Portrait Layout (Bottom Navigation)
*   **Bottom Navigation Bar**: Automatically highlights the active icon by matching the prefix of `GoRouterState.of(context).uri.path`.
*   **Tapping triggers** call `context.go(...)` for instant page swaps:
    *   **Index 0 (Home)**: `/home`
    *   **Index 1 (Templates)**: `/templates`
    *   **Index 2 (Goals)**: `/goals`
    *   **Index 3 (Planner)**: `/planner`
    *   **Index 4 (Settings)**: `/settings`

### 💻 2. Tablet & Desktop/Web Layout (Left Sidebar)
When screen width exceeds mobile thresholds (greater than `600px`), `GentleScaffold` hides the bottom bar and injects a permanent left sidebar (`_buildSidebar`):
*   **Brand Header**: Renders the GentleNotes logo and app version badge.
*   **User Badge**: Displays a local workspace indicator reading the active user profile role.
*   **Navigation Options**: A list of high-contrast icons linking to Dashboard, Templates, Goals, Planner, Settings, and About sections.
*   **Hierarchical Folders Drawer**: Loads the `foldersProvider` list dynamically. It renders each user folder as a list row complete with a circle indicator matching the folder's theme color, linking directly to `/folders/:folderId`.

---

## 🔗 Platform Native Sharing (Deep Link Handler)

The GoRouter initialisation inside `router.dart` sets up a global `MethodChannel` to intercept external file sharing actions from Android/iOS.
*   **Channel**: `'com.gentlegraph.gentlenotes/pdf_share'`
*   **Method**: `onPdfShared`
*   **Action**: When a PDF file is shared with GentleNotes from another application (e.g., File Manager, Google Drive), the method handler catches the file path, encodes it, and pushes the `/pdf-reader?path={filePath}` route directly onto the GoRouter stack. This bypasses the Home Screen, taking the user directly into the document viewer space.
