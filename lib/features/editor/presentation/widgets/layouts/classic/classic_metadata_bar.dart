import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../models/models.dart';
import '../../../../../folders/presentation/controllers/folders_controller.dart';

class ClassicMetadataBar extends ConsumerWidget {
  final String? selectedFolderId;
  final ValueChanged<String?> onFolderChanged;
  final NoteType noteType;
  final ValueChanged<NoteType> onNoteTypeChanged;
  final String colorHex;
  final ValueChanged<String> onColorChanged;
  final bool readOnly;

  const ClassicMetadataBar({
    super.key,
    required this.selectedFolderId,
    required this.onFolderChanged,
    required this.noteType,
    required this.onNoteTypeChanged,
    required this.colorHex,
    required this.onColorChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final folders = ref.watch(foldersProvider);

    final colors = [
      '#FFFFFF',
      '#FEE2E2',
      '#FEF3C7',
      '#ECFDF5',
      '#E0F2FE',
      '#F3E8FF',
      '#FDF4FF',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: selectedFolderId,
                  hint: const Row(
                    children: [
                      Icon(Icons.folder_outlined, size: 18),
                      SizedBox(width: 6),
                      Text('Select Folder', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Row(
                        children: [
                          Icon(Icons.folder_off_outlined, size: 16),
                          SizedBox(width: 6),
                          Text('No Folder', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    ...folders.map((f) => DropdownMenuItem<String?>(
                          value: f.id,
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: f.color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text(f.name, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        )),
                  ],
                  onChanged: readOnly ? null : onFolderChanged,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<NoteType>(
                  value: noteType,
                  items: NoteType.values
                      .map((t) => DropdownMenuItem<NoteType>(
                            value: t,
                            child: Row(
                              children: [
                                Icon(t.icon, size: 16, color: theme.colorScheme.primary),
                                const SizedBox(width: 6),
                                Text(t.displayName, style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: readOnly
                      ? null
                      : (val) {
                          if (val != null) {
                            onNoteTypeChanged(val);
                          }
                        },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: colors.map((colHex) {
                  final isSelected = colorHex == colHex;
                  final color = colHex == '#FFFFFF'
                      ? Colors.grey.shade300
                      : Color(int.parse('FF${colHex.replaceAll('#', '')}', radix: 16));
                  return GestureDetector(
                    onTap: readOnly ? null : () => onColorChanged(colHex),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: colHex == '#FFFFFF' ? Colors.white : color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? theme.colorScheme.onSurface : Colors.grey.shade400,
                          width: isSelected ? 1.5 : 0.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
