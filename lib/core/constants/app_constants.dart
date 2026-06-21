/// Application-wide constants.
///
/// All magic strings, numeric limits, and shared configuration values live
/// here so they are easy to find, update, and test in one place.
library;

class AppConstants {
  AppConstants._(); // Prevent instantiation

  // ── App Identity ────────────────────────────────────────────────────────────
  static const String appName = 'Gentle Notes';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // ── Hive Box Names ──────────────────────────────────────────────────────────
  // Versioned so we can migrate safely in the future.
  static const String foldersBox = 'gentle_folders_box_v1';
  static const String notesBox = 'gentle_notes_box_v1';
  static const String templatesBox = 'gentle_templates_box_v1';
  static const String settingsBox = 'gentle_settings_box_v1';
  static const String plannerBox = 'gentle_planner_box_v1';
  static const String pdfAnnotationsBox = 'gentle_pdf_annotations_box_v1';
  static const String pdfBookmarksBox = 'gentle_pdf_bookmarks_box_v1';
  static const String goalsBox = 'gentle_goals_box_v1';

  // ── SharedPreferences Keys ──────────────────────────────────────────────────
  static const String prefThemeMode = 'themeMode';
  static const String prefAccentColor = 'accentColorHex';
  static const String prefLayoutMode = 'layoutMode';
  static const String prefEditorMode = 'editorMode';
  static const String prefDefaultNoteType = 'defaultNoteType';
  static const String prefAutoSave = 'autoSaveEnabled';
  static const String prefCodeTheme = 'activeCodeTheme';
  static const String prefUserRole = 'userRole';
  static const String prefEditorLayout = 'editorLayout';
  static const String prefThemePreset = 'themePreset';
  static const String prefUserMode = 'userMode';
  static const String prefIsAdvancedMode = 'isAdvancedMode';
  static const String prefCustomEnabledLayouts = 'customEnabledLayouts';
  static const String prefCustomEnabledThemes = 'customEnabledThemes';
  static const String prefCustomEnabledTools = 'customEnabledTools';
  static const String prefEditorFontFamily = 'editorFontFamily';
  static const String prefEditorFontSize = 'editorFontSize';
  static const String prefEditorLineHeight = 'editorLineHeight';
  static const String prefHomeLayout = 'homeLayout';
  static const String prefHasSeededV1 = 'has_seeded_v1';
  static const String prefHasSeededV2 = 'has_seeded_v2';

  // ── Seeded Folder IDs ───────────────────────────────────────────────────────
  static const String folderAiMl = 'f-aiml';
  static const String folderHackathons = 'f-hackathons';
  static const String folderDatathons = 'f-datathons';
  static const String folderProjects = 'f-projects';
  static const String folderLanguage = 'f-language';
  static const String folderPersonal = 'f-personal';

  // ── Seeded Note IDs ─────────────────────────────────────────────────────────
  static const String noteStressTest = 'n-stress-test';

  // ── Default Accent Colors ───────────────────────────────────────────────────
  static const String defaultAccentHex = '#6366F1'; // Soft indigo
  static const String defaultCodeTheme = 'vs-dark';

  // ── UI Limits ───────────────────────────────────────────────────────────────
  static const int recentNotesLimit = 5;
  static const int maxTagLength = 30;
  static const int maxTitleLength = 200;
  static const double sidebarWidth = 260.0;
  static const double mobileBreakpoint = 768.0;

  // ── Routes ──────────────────────────────────────────────────────────────────
  static const String routeSplash = '/';
  static const String routeOnboarding = '/onboarding';
  static const String routeHome = '/home';
  static const String routeFolderDetail = '/folders/:id';
  static const String routeNoteCreate = '/notes/create';
  static const String routeNoteEdit = '/notes/edit/:id';
  static const String routeTemplates = '/templates';
  static const String routeSettings = '/settings';
  static const String routeAbout = '/about';
  static const String routeCalendar = '/calendar';

  // ── Planner Routes ───────────────────────────────────────────────────────────
  static const String routePlanner = '/planner';
  static const String routePlannerCreate = '/planner/create';
  static const String routePlannerEdit = '/planner/edit/:id';
  static const String routePlannerItem = '/planner/item/:id';

  // ── Notification Channel IDs ─────────────────────────────────────────────────
  static const String notifChannelPlanner = 'gentle_planner_reminders';
}
