/// Application feature configuration and extension points.
///
/// This file acts as a single place to toggle features on/off and to hold
/// placeholder configuration for planned features (cloud sync, AI, etc.).
/// In a production app, values here would be populated from a remote config
/// service (Firebase Remote Config, LaunchDarkly, etc.).
library app_config;

class AppConfig {
  AppConfig._(); // Prevent instantiation

  // ── Feature Flags ───────────────────────────────────────────────────────────

  /// Enable or disable the drawing canvas feature.
  static const bool enableDrawingCanvas = true;

  /// Enable or disable the calendar/reminders feature.
  static const bool enableCalendar = true;

  /// Enable or disable the PDF export feature.
  static const bool enablePdfExport = true;

  /// Enable or disable audio recording for voice notes.
  static const bool enableVoiceNotes = true;

  // ── AI Feature Extension Point ──────────────────────────────────────────────
  // These flags are intentionally `false` until the AI module is implemented.

  /// Master switch for all AI-powered features.
  static const bool enableAiFeatures = false;

  /// Enable AI-powered note summarization.
  static const bool enableAiSummarize = false;

  /// Enable AI-powered tag suggestions.
  static const bool enableAiTagSuggestion = false;

  /// Enable AI-powered semantic search across notes.
  static const bool enableAiSemanticSearch = false;

  // ── Cloud Sync Extension Point ──────────────────────────────────────────────
  // Cloud sync is offline-first by design. These flags gate sync logic.

  /// Master switch for cloud synchronization.
  static const bool enableCloudSync = false;

  /// The cloud sync provider to use (e.g., 'firebase', 'supabase').
  /// Only relevant when [enableCloudSync] is true.
  static const String cloudSyncProvider = 'firebase';

  // ── Attachment Extension Points ─────────────────────────────────────────────

  /// Allow image attachments on notes.
  static const bool enableImageAttachments = true;

  /// Allow audio file attachments on notes.
  static const bool enableAudioAttachments = true;

  /// Allow arbitrary file attachments on notes.
  static const bool enableFileAttachments = false;

  // ── Development ─────────────────────────────────────────────────────────────

  /// Show debug overlay with performance metrics.
  static const bool showDebugBanner = false;
}
