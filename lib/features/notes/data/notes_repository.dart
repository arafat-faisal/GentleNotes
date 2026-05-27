/// Re-export shim for backward compatibility.
///
/// All existing screens that import this file will continue to work.
/// New code should import from the canonical controller location:
/// `features/notes/presentation/controllers/notes_controller.dart`
library notes_repository_shim;

export '../presentation/controllers/notes_controller.dart';
