# GentleNotes Home Page Audit: UI & Visual Layouts

The layout system of the GentleNotes Home page is dynamic, responsive, and highly customizable. Rather than locking users into a single view, the page adapts to **7 distinct visual presets** dictated by the `HomeLayoutPreset` enum. The active layout is reactively swapped at runtime by `HomeLayoutSwitcher`.

---

## 🗺️ Layout Preset Analysis

Below is an architectural audit of each layout:

### 1. Dashboard Layout (`home_dashboard_layout.dart`)
*   **Visual Metaphor**: A comprehensive landing hub that organizes all elements of a user's productivity stream into clean, sectioned groups.
*   **Widget Structure**: Built inside a `CustomScrollView` using slivers to maintain smooth inertial scrolling behavior.
    1.  **Search & Tags** (`SliverToBoxAdapter` containing `HomeSearchBar`): Standard search field with tag chips.
    2.  **Stats Summary** (`SliverToBoxAdapter` containing `StatsSummaryGrid`): Summary cards displaying notes, folders, templates, and favorites counts.
    3.  **Quick Actions** (`SliverToBoxAdapter` containing `QuickActionsBar`): Horizontal sliding card containing actions for creating folders, manual backups/imports, calendar view, etc.
    4.  **Folders Grid/List** (`FolderListGrid` inside `SliverPadding`): Automatically displays either a grid or a list based on user settings, complete with a toggle button in the header.
    5.  **Notes Feed** (`NoteListView` inside `SliverPadding`): Shows chronologically ordered note cards.
*   **Aesthetic & Styling**: Medium density, standard card margins, high contrast headers, and subtle outline borders.

---

### 2. Focus Layout (`home_focus_layout.dart`)
*   **Visual Metaphor**: A minimalist workspace focused solely on active tasks and personal motivation, eliminating secondary stats, folders, and feeds.
*   **Widget Structure**:
    1.  **Header & Quote Banner**: Displays a productivity quote card loaded from a list using a stable rotation formula (`DateTime.now().day % quotes.length`).
    2.  **Search Bar**: Minimal search field.
    3.  **Pinned Tasks**: Aggregates only pinned notes (`filteredNotes.where((n) => n.isPinned).toList()`).
*   **Aesthetic & Styling**: Large typography, soft primary-colored background tints, generous line heights, and ample empty spacing (focus-inducing). Shows a custom illustration and text when no notes are pinned.

---

### 3. Notebook Shelves Layout (`home_notebook_layout.dart`)
*   **Visual Metaphor**: A physical study shelf displaying notebooks lined up side-by-side.
*   **Widget Structure**:
    1.  **Banner Header**: Prominent Outlined/Outfit title ("Notebook Shelves").
    2.  **Horizontal Folder Carousel**: A horizontal `ListView.builder` rendering each folder as a custom "Notebook Tab" with color-coded borders and folder-specific icons.
    3.  **Foldered Note Feed**: Filters recent notes in real-time based on the selected folder.
*   **Aesthetic & Styling**: Card tabs with dynamic border coloring (`2.0` width when active) and subtle background color opacity overlays based on the folder's primary theme color.

---

### 4. Magazine Layout (`home_magazine_layout.dart`)
*   **Visual Metaphor**: An editorial magazine homepage featuring a high-impact cover story followed by secondary article grids.
*   **Widget Structure**:
    1.  **Hero Cover Card**: The most recently updated note is displayed as a large, stylized hero card.
        *   Uses a `LinearGradient` blending the note's custom color code (`colorHex`) into the system surface card background.
        *   Renders tags as pill containers with transparent borders.
        *   Displays up to 4 lines of preview text.
    2.  **Editorial Grid**: All other notes are rendered inside a two-column or three-column `SliverGrid` using a high-aspect ratio card.
*   **Aesthetic & Styling**: Asymmetrical layouts, large font metrics, dynamic gradients, editorial visual weights, and high shadow elevations.

---

### 5. Calendar Layout (`home_calendar_layout.dart`)
*   **Visual Metaphor**: An organizer-style chronological agenda planner.
*   **Widget Structure**:
    1.  **Date Picker Carousel**: A horizontal sliding row of 7 cards representing the last 7 days.
        *   Includes an "All Days" reset button.
        *   Highlights the selected day and features a subtle marker for "Today".
    2.  **Timeline Feed**: Displays notes modified on the selected date. Uses a custom timeline track (vertical divider lines connected to primary color circular bullets).
*   **Aesthetic & Styling**: High-contrast active date badges, empty-state event illustrations, and strict vertical alignment.

---

### 6. Compact Layout (`home_compact_layout.dart`)
*   **Visual Metaphor**: High-density spreadsheet or file-explorer style listing for power users.
*   **Widget Structure**:
    1.  **Dense Search**: Small search text box (height restricted to `40`).
    2.  **Mini Folder Chips**: Renders folder circles inside tiny `ActionChip` wrappers.
    3.  **Compact Rows**: Replaces cards with simple single-row entries containing:
        *   Note type icon.
        *   Folder color circle.
        *   Title (truncated).
        *   Status icons (pin/favorite).
        *   Formatted short date (MM/dd).
*   **Aesthetic & Styling**: Small fonts (`13px`), zero elevation, extremely tight padding, and thin divider lines. Shows maximum information in minimum screen space.

---

### 7. Minimal Feed Layout (`home_minimal_feed_layout.dart`)
*   **Visual Metaphor**: A clean, single vertical stream reminiscent of microblogging or journaling apps.
*   **Widget Structure**:
    1.  **Search Bar**: Standard search input.
    2.  **Vertical Note Feed**: Continuous feed of note cards without folders, quick actions, or statistics.
*   **Aesthetic & Styling**: Standard margins, unified cards, and distraction-free listing.

---

## 🎨 Theme & Typography Integration

*   **Google Fonts**: Main titles use the **Outfit** typeface (with heavy/bold font weights) to deliver a modern, premium feel. Content text utilizes the **Inter** font family for maximum legibility.
*   **Dynamic Transparency**: Layouts rely heavily on Flutter's `.withValues(alpha: ...)` or `.withOpacity` methods to tint containers based on active primary theme colors.
*   **Dark Mode Support**: Renders cards using `theme.cardColor` or `theme.colorScheme.surface` with contrast borders (`outlineVariant` or custom divider colors) to maintain structural boundaries in low-light environments.
