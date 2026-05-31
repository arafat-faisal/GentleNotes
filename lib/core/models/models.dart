/// Barrel export for all shared data models.
///
/// Import this file anywhere you need access to domain-level models.
/// This avoids deep import paths scattered throughout the codebase.
///
/// Usage:
/// ```dart
/// import 'package:gentle_notes/core/models/models.dart';
/// ```
library models;

export '../../../models/models.dart'; // Enums
export '../../features/folders/data/models/folder_model.dart';
export '../../features/notes/data/models/attachment_model.dart';
export '../../features/notes/data/models/note_model.dart';
export '../../features/templates/data/models/note_template_model.dart';
export '../../features/settings/data/models/app_settings_model.dart';
export '../../features/settings/data/models/user_profile.dart';
