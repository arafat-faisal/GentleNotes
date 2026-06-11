import 'package:flutter/material.dart';
import 'layout_previews/shared_preview_helpers.dart';

class HomePreviewDashboard extends StatelessWidget {
  final bool isDark;
  const HomePreviewDashboard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF13111C) : const Color(0xFFFAF9FF);
    final card = isDark ? const Color(0xFF1E1B2C) : Colors.white;
    final line = isDark ? const Color(0xFF2E2845) : const Color(0xFFE8E4F5);
    final textMuted = isDark ? const Color(0xFF4A4370) : const Color(0xFFD1CBE8);
    final textMain = isDark ? const Color(0xFFCCC7E0) : const Color(0xFF3D3557);

    return Container(
      color: bg,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Pill
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: line),
            ),
          ),
          const SizedBox(height: 6),
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              4,
              (i) => Container(
                width: 24,
                height: 16,
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: line),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Folders Header
          previewLine(textMain, 0.4),
          const SizedBox(height: 4),
          // Folders
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 50,
                height: 20,
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: line),
                ),
              ),
              Container(
                width: 50,
                height: 20,
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: line),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Recent Notes Header
          previewLine(textMain, 0.5),
          const SizedBox(height: 4),
          // Note list
          Expanded(
            child: ListView.builder(
              itemCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, i) => Container(
                height: 20,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: line),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    previewLine(textMain, 0.8),
                    const SizedBox(height: 2),
                    previewLine(textMuted, 0.5),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomePreviewMinimalFeed extends StatelessWidget {
  final bool isDark;
  const HomePreviewMinimalFeed({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isDark ? const Color(0xFF13111C) : const Color(0xFFFAF9FF);
    final card = isDark ? const Color(0xFF1E1B2C) : Colors.white;
    final line = isDark ? const Color(0xFF2E2845) : const Color(0xFFE8E4F5);
    final textMuted = isDark ? const Color(0xFF4A4370) : const Color(0xFFD1CBE8);
    final textMain = isDark ? const Color(0xFFCCC7E0) : const Color(0xFF3D3557);

    return Container(
      color: bg,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting lines
          previewLine(theme.colorScheme.primary, 0.6),
          const SizedBox(height: 4),
          previewLine(textMuted, 0.8),
          const SizedBox(height: 8),
          // Search Pill
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: line),
            ),
          ),
          const SizedBox(height: 10),
          // Feed list
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, i) => Container(
                height: 24,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: line),
                ),
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    previewLine(textMain, 0.7),
                    const SizedBox(height: 2),
                    previewLine(textMuted, 0.5),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomePreviewFocus extends StatelessWidget {
  final bool isDark;
  const HomePreviewFocus({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isDark ? const Color(0xFF13111C) : const Color(0xFFFAF9FF);
    final card = isDark ? const Color(0xFF1E1B2C) : Colors.white;
    final line = isDark ? const Color(0xFF2E2845) : const Color(0xFFE8E4F5);
    final textMuted = isDark ? const Color(0xFF4A4370) : const Color(0xFFD1CBE8);
    final textMain = isDark ? const Color(0xFFCCC7E0) : const Color(0xFF3D3557);
    final accent = theme.colorScheme.primary;

    return Container(
      color: bg,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          previewLine(accent, 0.5),
          const SizedBox(height: 6),
          // Quote Card Box
          Container(
            height: 28,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Icon(Icons.format_quote_rounded, size: 10, color: accent),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      previewLine(textMain, 0.9),
                      const SizedBox(height: 2),
                      previewLine(textMuted, 0.7),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Search
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: line),
            ),
          ),
          const SizedBox(height: 8),
          // Pinned label
          previewLine(textMuted, 0.4),
          const SizedBox(height: 4),
          // One focused pinned card
          Container(
            height: 26,
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: line),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Icon(Icons.push_pin, size: 8, color: theme.colorScheme.secondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      previewLine(textMain, 0.8),
                      const SizedBox(height: 2),
                      previewLine(textMuted, 0.6),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomePreviewMagazine extends StatelessWidget {
  final bool isDark;
  const HomePreviewMagazine({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isDark ? const Color(0xFF13111C) : const Color(0xFFFAF9FF);
    final card = isDark ? const Color(0xFF1E1B2C) : Colors.white;
    final line = isDark ? const Color(0xFF2E2845) : const Color(0xFFE8E4F5);
    final textMuted = isDark ? const Color(0xFF4A4370) : const Color(0xFFD1CBE8);
    final textMain = isDark ? const Color(0xFFCCC7E0) : const Color(0xFF3D3557);
    final accent = theme.colorScheme.primary;

    return Container(
      color: bg,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: line),
            ),
          ),
          const SizedBox(height: 6),
          // Magazine Hero Card
          Container(
            height: 45,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent.withValues(alpha: 0.2), card],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: line),
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                previewLine(textMain, 0.8),
                const SizedBox(height: 3),
                previewLine(textMuted, 0.9),
                const SizedBox(height: 3),
                previewLine(textMuted, 0.5),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Magazine grid
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: line),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      previewLine(textMain, 0.8),
                      const SizedBox(height: 2),
                      previewLine(textMuted, 0.5),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: line),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      previewLine(textMain, 0.7),
                      const SizedBox(height: 2),
                      previewLine(textMuted, 0.4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HomePreviewNotebook extends StatelessWidget {
  final bool isDark;
  const HomePreviewNotebook({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isDark ? const Color(0xFF13111C) : const Color(0xFFFAF9FF);
    final card = isDark ? const Color(0xFF1E1B2C) : Colors.white;
    final line = isDark ? const Color(0xFF2E2845) : const Color(0xFFE8E4F5);
    final textMuted = isDark ? const Color(0xFF4A4370) : const Color(0xFFD1CBE8);
    final textMain = isDark ? const Color(0xFFCCC7E0) : const Color(0xFF3D3557);
    final accent = theme.colorScheme.primary;

    return Container(
      color: bg,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          previewLine(textMain, 0.5),
          const SizedBox(height: 6),
          // Horizontal shelf capsules
          Row(
            children: [
              Container(
                width: 32,
                height: 14,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accent),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 32,
                height: 14,
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: line),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 32,
                height: 14,
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: line),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // List notes of category
          previewLine(textMuted, 0.3),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              itemCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, i) => Container(
                height: 20,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: line),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    previewLine(textMain, 0.7),
                    const SizedBox(height: 2),
                    previewLine(textMuted, 0.5),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomePreviewCalendar extends StatelessWidget {
  final bool isDark;
  const HomePreviewCalendar({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isDark ? const Color(0xFF13111C) : const Color(0xFFFAF9FF);
    final card = isDark ? const Color(0xFF1E1B2C) : Colors.white;
    final line = isDark ? const Color(0xFF2E2845) : const Color(0xFFE8E4F5);
    final textMuted = isDark ? const Color(0xFF4A4370) : const Color(0xFFD1CBE8);
    final textMain = isDark ? const Color(0xFFCCC7E0) : const Color(0xFF3D3557);
    final accent = theme.colorScheme.primary;

    return Container(
      color: bg,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          previewLine(textMain, 0.4),
          const SizedBox(height: 6),
          // Horizontal calendar stripe
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              5,
              (i) => Container(
                width: 18,
                height: 22,
                decoration: BoxDecoration(
                  color: i == 2 ? accent : card,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: i == 2 ? accent : line),
                ),
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == 2 ? Colors.white : textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Timeline list of notes
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line
                Column(
                  children: [
                    Container(width: 4, height: 4, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                    Container(width: 1, height: 32, color: accent.withValues(alpha: 0.3)),
                  ],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: line),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        previewLine(textMain, 0.7),
                        const SizedBox(height: 2),
                        previewLine(textMuted, 0.4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomePreviewCompact extends StatelessWidget {
  final bool isDark;
  const HomePreviewCompact({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isDark ? const Color(0xFF13111C) : const Color(0xFFFAF9FF);
    final card = isDark ? const Color(0xFF1E1B2C) : Colors.white;
    final line = isDark ? const Color(0xFF2E2845) : const Color(0xFFE8E4F5);
    final textMuted = isDark ? const Color(0xFF4A4370) : const Color(0xFFD1CBE8);
    final textMain = isDark ? const Color(0xFFCCC7E0) : const Color(0xFF3D3557);

    return Container(
      color: bg,
      padding: const EdgeInsets.all(6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Small search bar
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: line),
            ),
          ),
          const SizedBox(height: 4),
          // Small tags
          Row(
            children: List.generate(
              4,
              (i) => Container(
                width: 18,
                height: 8,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: line),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Dense rows
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, i) => Container(
                height: 12,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: line, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 4, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Expanded(child: previewLine(textMain, 0.7)),
                    const SizedBox(width: 4),
                    previewLine(textMuted, 0.15),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
