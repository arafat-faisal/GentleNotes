/// Re-export shim for backward compatibility.
///
/// All existing screens that import this file will continue to work.
/// New code should import from the canonical controller location:
/// `features/folders/presentation/controllers/folders_controller.dart`
library folders_repository_shim;

export '../presentation/controllers/folders_controller.dart';
