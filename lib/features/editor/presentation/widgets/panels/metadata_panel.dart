import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../models/models.dart';
import '../../../../folders/data/folders_repository.dart';

class MetadataPanel extends ConsumerWidget {
  final String? selectedFolderId;
  final ValueChanged<String?> onFolderChanged;
  final NoteType noteType;
  final ValueChanged<NoteType> onNoteTypeChanged;
  final bool isPinned;
  final ValueChanged<bool> onPinChanged;
  final bool isFavorite;
  final ValueChanged<bool> onFavoriteChanged;
  final String colorHex;
  final ValueChanged<String> onColorChanged;
  final TextEditingController tagController;

  const MetadataPanel({
    super.key,
    required this.selectedFolderId,
    required this.onFolderChanged,
    required this.noteType,
    required this.onNoteTypeChanged,
    required this.isPinned,
    required this.onPinChanged,
    required this.isFavorite,
    required this.onFavoriteChanged,
    required this.colorHex,
    required this.onColorChanged,
    required this.tagController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final folders = ref.watch(foldersProvider);

    final colors = [
      '#FFFFFF',
      '#FEE2E2', // Soft Red
      '#FEF3C7', // Soft Amber
      '#ECFDF5', // Soft Green
      '#E0F2FE', // Soft Blue
      '#F3E8FF', // Soft Purple
      '#FDF4FF', // Soft Pink
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row for Pin / Favorite toggles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Note Properties',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: isPinned ? theme.colorScheme.primary : theme.hintColor,
                    ),
                    onPressed: () => onPinChanged(!isPinned),
                    tooltip: 'Pin Note',
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : theme.hintColor,
                    ),
                    onPressed: () => onFavoriteChanged(!isFavorite),
                    tooltip: 'Favorite Note',
                  ),
                ],
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),

          // Folder Selection
          Text(
            'Folder',
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.dividerColor,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: selectedFolderId,
                hint: const Row(
                  children: [
                    Icon(Icons.folder_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Select Folder', style: TextStyle(fontSize: 13)),
                  ],
                ),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Row(
                      children: [
                        Icon(Icons.folder_off_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('No Folder', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  ...folders.map((f) => DropdownMenuItem<String?>(
                        value: f.id,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: f.color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text(f.name, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      )),
                ],
                onChanged: onFolderChanged,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Note Type Selection
          Text(
            'Note Type',
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.dividerColor,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<NoteType>(
                value: noteType,
                isExpanded: true,
                items: NoteType.values
                    .map((t) => DropdownMenuItem<NoteType>(
                          value: t,
                          child: Row(
                            children: [
                              Icon(t.icon, size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(t.displayName, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) onNoteTypeChanged(val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Note Background Accent Color Picker
          Text(
            'Accent Background',
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: colors.map((hex) {
                final isSelected = colorHex.toUpperCase() == hex.toUpperCase();
                final colorVal = hex == '#FFFFFF'
                    ? theme.scaffoldBackgroundColor
                    : Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () => onColorChanged(hex),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colorVal,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.dividerColor,
                          width: isSelected ? 2.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Tags Editor
          Text(
            'Tags (comma separated)',
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: tagController,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'e.g. work, ideas, urgent',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor.withValues(alpha: 0.5),
              ),
              prefixIcon: const Icon(Icons.local_offer_outlined, size: 16),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: theme.dividerColor,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: theme.dividerColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }
}
