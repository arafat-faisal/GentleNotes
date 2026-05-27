import 'dart:html' as html;
import 'dart:async';
import 'package:flutter/material.dart';

StreamSubscription? _pasteSubscription;

void setupClipboardPasteListener(
  BuildContext context,
  FocusNode focusNode,
  void Function(String dataUrl, String fileName) onImagePasted,
  void Function(String plainText, String? htmlText) onTextPasted,
) {
  _pasteSubscription?.cancel();
  _pasteSubscription = html.document.onPaste.listen((html.ClipboardEvent event) {
    if (!focusNode.hasFocus) return;

    final clipboardData = event.clipboardData;
    if (clipboardData == null) return;

    final items = clipboardData.items;
    bool hasImage = false;
    if (items != null) {
      final len = items.length ?? 0;
      for (var i = 0; i < len; i++) {
        final item = items[i];
        if (item.type?.contains("image") == true) {
          hasImage = true;
          final blob = item.getAsFile();
          if (blob != null) {
            final reader = html.FileReader();
            reader.onLoadEnd.listen((e) {
              final String? result = reader.result as String?;
              if (result != null) {
                final fileExtension = item.type?.split('/').last ?? 'png';
                final fileName = 'clipboard_img_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
                onImagePasted(result, fileName);
              }
            });
            reader.readAsDataUrl(blob);
          }
          break;
        }
      }
    }

    if (!hasImage) {
      final plainText = clipboardData.getData('text/plain');
      final htmlText = clipboardData.getData('text/html');
      if (plainText.isNotEmpty || htmlText.isNotEmpty) {
        event.preventDefault();
        onTextPasted(plainText, htmlText.isNotEmpty ? htmlText : null);
      }
    }
  });
}

void disposeClipboardPasteListener() {
  _pasteSubscription?.cancel();
  _pasteSubscription = null;
}
