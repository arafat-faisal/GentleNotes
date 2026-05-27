/// Re-export shim for backward compatibility.
///
/// All existing screens that import this file will continue to work.
/// New code should import from the canonical controller location:
/// `features/settings/presentation/controllers/settings_controller.dart`
library settings_repository_shim;

export '../presentation/controllers/settings_controller.dart';
