import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../folders/presentation/controllers/folders_controller.dart';
import '../../../../notes/presentation/controllers/notes_controller.dart';
import '../note_card.dart';

class HomeCalendarLayout extends ConsumerStatefulWidget {
  const HomeCalendarLayout({super.key});

  @override
  ConsumerState<HomeCalendarLayout> createState() => _HomeCalendarLayoutState();
}

class _HomeCalendarLayoutState extends ConsumerState<HomeCalendarLayout> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Default select today
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final folders = ref.watch(foldersProvider);
    final filteredNotes = ref.watch(filteredNotesProvider);

    // Calculate last 7 days
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dates = List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      return DateTime(date.year, date.month, date.day);
    });

    final displayNotes = _selectedDate == null
        ? filteredNotes
        : filteredNotes.where((n) {
            final u = n.updatedAt;
            return u.year == _selectedDate!.year &&
                u.month == _selectedDate!.month &&
                u.day == _selectedDate!.day;
          }).toList();

    return CustomScrollView(
      slivers: [
        // Title Banner
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Planner',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review and schedule your notes chronologically.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Horizontal 7-Day Date Picker
        SliverToBoxAdapter(
          child: SizedBox(
            height: 105,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: dates.length + 1,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = _selectedDate == null;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('All Days', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedDate = null),
                    ),
                  );
                }

                final date = dates[index - 1];
                final isSelected = _selectedDate != null &&
                    _selectedDate!.year == date.year &&
                    _selectedDate!.month == date.month &&
                    _selectedDate!.day == date.day;

                final dayName = DateFormat('E').format(date); // Mon, Tue, etc.
                final dayNum = DateFormat('d').format(date); // 12, 13, etc.
                final isToday = date.year == today.year && date.month == today.month && date.day == today.day;

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 58,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isToday
                              ? theme.colorScheme.primary.withValues(alpha: 0.08)
                              : theme.colorScheme.surface),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : (isToday
                                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                                : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dayNum,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Timeline Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate == null
                      ? 'Full Timeline'
                      : 'Updated on ${DateFormat('EEEE, MMM d').format(_selectedDate!)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ),
                if (_selectedDate != null)
                  TextButton(
                    onPressed: () => setState(() => _selectedDate = null),
                    child: const Text('View All'),
                  ),
              ],
            ),
          ),
        ),

        // Timeline Note List
        if (displayNotes.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No Notes on this Day',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap other calendar dates or click "View All" to browse notes.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final note = displayNotes[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left-side time timeline indicator
                        Column(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(top: 24),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 2,
                              height: 100, // estimated line height spacing
                              color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        // Note Card content
                        Expanded(
                          child: NoteCard(
                            note: note,
                            folders: folders,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount: displayNotes.length,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}
