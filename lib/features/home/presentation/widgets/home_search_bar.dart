import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../notes/presentation/controllers/notes_controller.dart';

class HomeSearchBar extends ConsumerStatefulWidget {
  const HomeSearchBar({super.key});

  @override
  ConsumerState<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends ConsumerState<HomeSearchBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Synchronize initial text with current provider query (e.g. on navigation back)
    _searchController.text = ref.read(searchQueryProvider);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notes = ref.watch(notesProvider);

    // Get unique tags across all notes
    final allTags = notes.expand((n) => n.tags).toSet().toList();
    final activeTag = ref.watch(selectedTagFilterProvider);

    return Column(
      children: [
        TextField(
          controller: _searchController,
          onChanged: (val) {
            ref.read(searchQueryProvider.notifier).state = val;
          },
          decoration: InputDecoration(
            hintText: 'Search notes by title, body, or tags...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  )
                : null,
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 12),
        if (allTags.isNotEmpty)
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: allTags.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isAll = activeTag == null;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('All Tags'),
                      selected: isAll,
                      onSelected: (_) {
                        ref.read(selectedTagFilterProvider.notifier).state = null;
                      },
                    ),
                  );
                }
                final tag = allTags[index - 1];
                final isSelected = activeTag == tag;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('#$tag'),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(selectedTagFilterProvider.notifier).state = isSelected ? null : tag;
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
