import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/editor_mode.dart';

class EditorModeController extends StateNotifier<EditorViewMode> {
  EditorModeController() : super(EditorViewMode.advanced);

  void setMode(EditorViewMode mode) {
    state = mode;
  }

  void toggleMode() {
    state = state == EditorViewMode.basic ? EditorViewMode.advanced : EditorViewMode.basic;
  }
}

final editorModeProvider = StateNotifierProvider<EditorModeController, EditorViewMode>((ref) {
  return EditorModeController();
});
