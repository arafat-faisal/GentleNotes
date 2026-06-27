# GentleNotes Home Page Audit: AI Enhancement Blueprints

This document outlines structural features, design improvements, and architectural refactoring patterns for the incoming AI research agent. These suggestions focus on leveling up the Home Screen's UX, state efficiency, and visual flair.

---

## 🚀 Recommended Enhancements

### 1. Interactive Stats Cards (Quick Filters)
*   **The Idea**: Currently, [`StatsSummaryGrid`](file:///d:/WebProjects/GentleNotes/lib/features/home/presentation/widgets/stats_summary_grid.dart) renders static read-only numbers. Tapping them should apply filters.
*   **Aesthetic Blueprint**: Wrap each stat card in an `InkWell`. When selected, apply a subtle color fill or glow border to indicate an active state.
*   **AI Implementation Guide**:
    *   Tapping the **Favorites** card should toggle the `filterFavoriteProvider` state.
    *   Tapping the **Notes** card should reset all active filter states (search query, tags, folders) back to default.
    *   Tapping **Folders** could trigger an anchor-scroll directly down to the folder section on the Dashboard layout.

---

### 2. Gesture Swipe Quick-Actions on Note Cards
*   **The Idea**: Users currently must open the full editor workspace to pin, delete, or favorite notes. Implementing swipable cards speeds up cataloging.
*   **Aesthetic Blueprint**: Wrap note cards in a `Dismissible` widget.
    *   **Swipe Right (Pin/Unpin)**: Shows a teal background with an animated `Icons.push_pin_rounded` slide-in icon.
    *   **Swipe Left (Archive/Delete)**: Shows a soft red background with a sliding trash icon.
*   **AI Implementation Guide**:
    *   Implement inside [`note_card.dart`](file:///d:/WebProjects/GentleNotes/lib/features/home/presentation/widgets/note_card.dart) or [`_buildCompactItem` in compact layout](file:///d:/WebProjects/GentleNotes/lib/features/home/presentation/widgets/layouts/home_compact_layout.dart#L125).
    *   Hook actions directly into the notifier: `ref.read(notesProvider.notifier).updateNote(...)` or delete commands.

---

### 3. Drag-and-Drop Categorization
*   **The Idea**: Allow notes to be easily filed under folders by dragging their visual card representation over target folder chips or tabs.
*   **Aesthetic Blueprint**: Use Flutter's native `Draggable<NoteModel>` and `DragTarget<FolderModel>` classes. When dragging, show a scaled-down semi-transparent preview of the note card. If hovering over a folder card, trigger a pulse/glow animation.
*   **AI Implementation Guide**:
    *   Wrap [`NoteCard`](file:///d:/WebProjects/GentleNotes/lib/features/home/presentation/widgets/note_card.dart) in `Draggable`.
    *   Wrap folder tabs inside [`home_notebook_layout.dart`](file:///d:/WebProjects/GentleNotes/lib/features/home/presentation/widgets/layouts/home_notebook_layout.dart#L192) or [`folder_card.dart`](file:///d:/WebProjects/GentleNotes/lib/features/home/presentation/widgets/folder_card.dart) in `DragTarget`.
    *   On acceptance, update the database: `ref.read(notesProvider.notifier).updateNote(draggedNote.copyWith(folderId: targetFolder.id))`.

---

### 4. Bulk Multi-Select & Batch Editing
*   **The Idea**: Support long-pressing note cards on the home page to enter a batch operation mode (enabling bulk deletion, tag assignment, or moves).
*   **Aesthetic Blueprint**:
    *   Show circular checkboxes beside each note card.
    *   Replace the main page AppBar with a contextual batch bar displaying the active selection count (e.g., "3 Selected") and action buttons.
*   **AI Implementation Guide**:
    *   Create a local `selectedNoteIdsProvider` (`StateProvider<List<String>>`).
    *   Tapping note cards when this list is not empty toggles inclusion in the selection list.
    *   Provide batch utility actions in `NotesController` (e.g. `deleteMultipleNotes`, `moveNotesToFolder`).

---

### 5. Tokenized Relevance Search Index
*   **The Idea**: The search logic in [`filteredNotesProvider`](file:///d:/WebProjects/GentleNotes/lib/features/notes/presentation/controllers/notes_controller.dart#L140-L171) is a basic case-insensitive substring search. A tokenized search ranker will perform significantly better.
*   **AI Implementation Guide**:
    *   Split the search query into keyword tokens.
    *   Calculate a score for each note:
        *   Title match: **+10 points** per keyword token.
        *   Tag match: **+5 points** per keyword token.
        *   Body PlainText match: **+2 points** per keyword token.
    *   Sort the returned list in descending order of matching score relevance.

---

### 6. Interactive Visual Polish (Micro-Animations)
*   **The Idea**: Elevate the visual feel of the dashboard presets to deliver a premium user experience.
*   **Aesthetic Blueprint**:
    *   **Hero Transitions**: Use Flutter's `Hero` widget when transitioning from a note card on the home screen to the editor workspace, morphing the card boundaries smoothly.
    *   **Animated Shimmer Loaders**: If storage operations are taking time, replace static empty states with animated gradient shimmer blocks representing note and folder lines.
    *   **Layout Swapping Transitions**: Wrap `HomeLayoutSwitcher` return statements inside an `AnimatedSwitcher` containing a slide-and-fade or scaling transition curve to make preset changes feel fluid.
