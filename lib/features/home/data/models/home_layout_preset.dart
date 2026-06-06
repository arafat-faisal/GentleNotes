import 'package:flutter/material.dart';

enum HomeLayoutPreset {
  dashboard,
  minimalFeed,
  focus,
  magazine,
  notebook,
  calendar,
  compact;

  String get displayName {
    switch (this) {
      case HomeLayoutPreset.dashboard:
        return 'Dashboard';
      case HomeLayoutPreset.minimalFeed:
        return 'Minimal Feed';
      case HomeLayoutPreset.focus:
        return 'Focus';
      case HomeLayoutPreset.magazine:
        return 'Magazine';
      case HomeLayoutPreset.notebook:
        return 'Notebook';
      case HomeLayoutPreset.calendar:
        return 'Calendar';
      case HomeLayoutPreset.compact:
        return 'Compact';
    }
  }

  String get description {
    switch (this) {
      case HomeLayoutPreset.dashboard:
        return 'Complete workspace with quick actions, folders, stats, and notes.';
      case HomeLayoutPreset.minimalFeed:
        return 'Clean layout with search, greeting, and a modern feed of notes.';
      case HomeLayoutPreset.focus:
        return 'Welcome message, curated quotes, and only pinned notes.';
      case HomeLayoutPreset.magazine:
        return 'Hero cover note card header with a visual grid of notes below.';
      case HomeLayoutPreset.notebook:
        return 'Folder-first layout. Tap folder cards to view notes inline.';
      case HomeLayoutPreset.calendar:
        return 'Weekly scrollable calendar with timeline notes of selected date.';
      case HomeLayoutPreset.compact:
        return 'Spreadsheet-like density maximizing notes on a single screen.';
    }
  }

  IconData get icon {
    switch (this) {
      case HomeLayoutPreset.dashboard:
        return Icons.dashboard_outlined;
      case HomeLayoutPreset.minimalFeed:
        return Icons.feed_outlined;
      case HomeLayoutPreset.focus:
        return Icons.center_focus_strong_outlined;
      case HomeLayoutPreset.magazine:
        return Icons.photo_filter_rounded;
      case HomeLayoutPreset.notebook:
        return Icons.folder_open_outlined;
      case HomeLayoutPreset.calendar:
        return Icons.calendar_month_outlined;
      case HomeLayoutPreset.compact:
        return Icons.view_headline_rounded;
    }
  }
}
