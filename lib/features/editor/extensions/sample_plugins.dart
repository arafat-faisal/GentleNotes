import 'package:flutter/material.dart';
import '../domain/entities/block_entity.dart';
import '../domain/entities/block_type.dart';
import 'block_plugin_interface.dart';
import 'plugin_registry.dart';

class TextBlockPlugin implements BlockPlugin {
  @override
  BlockType get type => BlockType.text;

  @override
  String get displayName => 'Text Block';

  @override
  IconData get icon => Icons.notes;

  @override
  Widget buildWidget({
    required BlockEntity block,
    required FocusNode focusNode,
    required ValueChanged<String> onChanged,
    required VoidCallback onSubmitted,
    VoidCallback? onDelete,
  }) {
    return TextField(
      focusNode: focusNode,
      controller: TextEditingController(text: block.content),
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted(),
      decoration: const InputDecoration(
        hintText: 'Type something...',
        border: InputBorder.none,
      ),
    );
  }
}

/// Helper method to initialize and register default block plugins.
void registerDefaultPlugins() {
  final registry = PluginRegistry();
  registry.register(TextBlockPlugin());
}
