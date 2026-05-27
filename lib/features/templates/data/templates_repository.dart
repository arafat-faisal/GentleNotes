/// Re-export shim for backward compatibility.
///
/// All existing screens that import this file will continue to work.
/// New code should import from the canonical controller location:
/// `features/templates/presentation/controllers/templates_controller.dart`
library templates_repository_shim;

export '../presentation/controllers/templates_controller.dart';
