import 'package:flutter/material.dart';

void setupClipboardPasteListener(
  BuildContext context,
  FocusNode focusNode,
  void Function(String dataUrl, String fileName) onImagePasted,
  void Function(String plainText, String? htmlText) onTextPasted,
) {
  // No-op on native platforms
}

void disposeClipboardPasteListener() {
  // No-op on native platforms
}
