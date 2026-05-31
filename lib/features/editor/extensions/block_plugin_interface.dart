import 'package:flutter/material.dart';
import '../domain/entities/block_entity.dart';
import '../domain/entities/block_type.dart';

abstract class BlockPlugin {
  BlockType get type;
  String get displayName;
  IconData get icon;

  Widget buildWidget({
    required BlockEntity block,
    required FocusNode focusNode,
    required ValueChanged<String> onChanged,
    required VoidCallback onSubmitted,
    VoidCallback? onDelete,
  });
}
