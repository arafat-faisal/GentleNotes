import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class HorizontalRuleEmbedBuilder extends EmbedBuilder {
  final String _key;

  HorizontalRuleEmbedBuilder({this._key = 'horizontal-rule'});

  @override
  String get key => _key;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      child: Divider(
        color: isDark ? const Color(0xFF252234) : const Color(0xFFE9E6F5),
        thickness: 1.5,
      ),
    );
  }
}
