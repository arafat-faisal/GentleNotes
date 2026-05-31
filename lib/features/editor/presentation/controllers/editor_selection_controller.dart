import 'editor_core_controller.dart';

class EditorSelectionController {
  final EditorCoreController coreController;

  EditorSelectionController(this.coreController);

  void selectBlock(int index) {
    coreController.updateStateDirectly(
      coreController.state.copyWith(selectedIndex: index),
    );
  }

  void clearSelection() {
    coreController.updateStateDirectly(
      coreController.state.copyWith(selectedIndex: -1),
    );
  }
}
