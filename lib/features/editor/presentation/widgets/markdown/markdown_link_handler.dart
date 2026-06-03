import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../../../../../../models/models.dart';
import '../inline_audio_player.dart';

class MarkdownLinkHandler {
  static InlineSpan buildAudioOrLinkSpan({
    required BuildContext context,
    required String label,
    required String url,
    required TextStyle baseStyle,
    required List<AttachmentModel> attachments,
  }) {
    if (url.startsWith('audio://')) {
      final attachmentId = url.replaceFirst('audio://', '');
      final attachment = attachments.cast<AttachmentModel?>().firstWhere(
            (a) => a?.id == attachmentId,
            orElse: () => null,
          );
      if (attachment != null) {
        return WidgetSpan(
          child: InlineAudioPlayer(
            filePath: attachment.pathOrUrl,
            name: attachment.name,
          ),
        );
      } else {
        return TextSpan(
          text: label,
          style: baseStyle.copyWith(color: Colors.red, decoration: TextDecoration.lineThrough),
        );
      }
    } else {
      return TextSpan(
        text: label,
        style: baseStyle.copyWith(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening Link: $url'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 1),
              ),
            );
          },
      );
    }
  }
}
