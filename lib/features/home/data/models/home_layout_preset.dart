import 'package:flutter/material.dart';

/// Preset modes for organizing components on the home page screen.
enum HomeLayoutPreset {
  minimal,
  bentoGrid;

  /// Human-readable name.
  String get displayName {
    switch (this) {
      case HomeLayoutPreset.minimal:
        return 'Minimal';
      case HomeLayoutPreset.bentoGrid:
        return 'Bento Grid';
    }
  }

  /// Brief description of layout presentation traits.
  String get description {
    switch (this) {
      case HomeLayoutPreset.minimal:
        return 'Progressive disclosure layout showing only notes with an expandable Omni-bar.';
      case HomeLayoutPreset.bentoGrid:
        return 'Tactile, editorial dashboard organizing notes, stats, and calendar modules.';
    }
  }

  /// Material icon representing layout design.
  IconData get icon {
    switch (this) {
      case HomeLayoutPreset.minimal:
        return Icons.feed_outlined;
      case HomeLayoutPreset.bentoGrid:
        return Icons.dashboard_outlined;
    }
  }
}
