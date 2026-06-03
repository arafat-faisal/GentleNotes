import 'package:flutter/material.dart';

class ClassicLayoutActions {
  // Can be extended with dialog controllers or share handles if needed.
  static void showSnippetFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
