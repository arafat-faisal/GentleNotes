import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/icon_helper.dart';
import '../../../../models/models.dart';
import '../../../folders/presentation/controllers/folders_controller.dart';

class FolderFormDialog extends ConsumerWidget {
  final FolderModel? existingFolder;
  final String? preselectedParentId;
  const FolderFormDialog({super.key, this.existingFolder, this.preselectedParentId});

  static void show(BuildContext context, {FolderModel? existingFolder, String? preselectedParentId}) {
    showDialog(
      context: context,
      builder: (context) => FolderFormDialog(
        existingFolder: existingFolder,
        preselectedParentId: preselectedParentId,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEdit = existingFolder != null;
    final nameController = TextEditingController(text: existingFolder?.name ?? '');

    final colors = [
      '#6366F1', // Indigo
      '#10B981', // Emerald
      '#3B82F6', // Blue
      '#F43F5E', // Rose
      '#F59E0B', // Amber
      '#8B5CF6', // Purple
      '#EC4899', // Pink
      '#F97316', // Orange
    ];

    final icons = IconHelper.getAvailableIconNames();

    return StatefulBuilder(
      builder: (context, setStateDialog) {
        return _DialogContent(
          isEdit: isEdit,
          nameController: nameController,
          colors: colors,
          icons: icons,
          existingFolder: existingFolder,
          preselectedParentId: preselectedParentId,
          ref: ref,
        );
      },
    );
  }
}

class _DialogContent extends StatefulWidget {
  final bool isEdit;
  final TextEditingController nameController;
  final List<String> colors;
  final List<String> icons;
  final FolderModel? existingFolder;
  final String? preselectedParentId;
  final WidgetRef ref;

  const _DialogContent({
    required this.isEdit,
    required this.nameController,
    required this.colors,
    required this.icons,
    required this.existingFolder,
    this.preselectedParentId,
    required this.ref,
  });

  @override
  State<_DialogContent> createState() => _DialogContentState();
}

class _DialogContentState extends State<_DialogContent> {
  late String _selectedColor;
  late String _selectedIcon;
  String? _selectedParentId;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.existingFolder?.colorHex ?? widget.colors.first;
    _selectedIcon = widget.existingFolder?.iconName ?? widget.icons.first;
    _selectedParentId = widget.existingFolder?.parentFolderId ?? widget.preselectedParentId;
  }

  bool _isDescendant(String descendantId, String possibleAncestorId, List<FolderModel> folders) {
    FolderModel? findFolder(String id) {
      for (var f in folders) {
        if (f.id == id) return f;
      }
      return null;
    }

    var current = findFolder(descendantId);
    while (current != null && current.parentFolderId != null) {
      if (current.parentFolderId == possibleAncestorId) {
        return true;
      }
      current = findFolder(current.parentFolderId!);
    }
    return false;
  }

  String _getFolderPath(FolderModel folder, List<FolderModel> folders) {
    FolderModel? findFolder(String id) {
      for (var f in folders) {
        if (f.id == id) return f;
      }
      return null;
    }

    final parts = <String>[folder.name];
    var current = folder;
    while (current.parentFolderId != null) {
      final parent = findFolder(current.parentFolderId!);
      if (parent == null) break;
      parts.insert(0, parent.name);
      current = parent;
    }
    return parts.join(' > ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final folders = widget.ref.watch(foldersProvider);

    final eligibleFolders = folders.where((f) {
      if (widget.existingFolder != null) {
        if (f.id == widget.existingFolder!.id) return false;
        if (_isDescendant(f.id, widget.existingFolder!.id, folders)) return false;
      }
      return true;
    }).toList();

    // Ensure selected parent ID is valid
    if (_selectedParentId != null && !eligibleFolders.any((f) => f.id == _selectedParentId)) {
      _selectedParentId = null;
    }

    return AlertDialog(
      title: Text(widget.isEdit ? 'Edit Folder' : 'New Folder'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: widget.nameController,
              decoration: const InputDecoration(
                labelText: 'Folder Name',
                hintText: 'e.g., Deep Learning Study',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 18),

            Text('Parent Folder', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _selectedParentId,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('None (Root Folder)'),
                ),
                ...eligibleFolders.map((f) {
                  return DropdownMenuItem<String?>(
                    value: f.id,
                    child: Text(
                      _getFolderPath(f, folders),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedParentId = val;
                });
              },
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              isExpanded: true,
            ),
            const SizedBox(height: 18),

            Text('Select Color', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              width: 300,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.colors.length,
                itemBuilder: (context, index) {
                  final colorHex = widget.colors[index];
                  final isSelected = _selectedColor == colorHex;
                  final color = Color(int.parse('FF${colorHex.replaceAll('#', '')}', radix: 16));
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = colorHex;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: theme.colorScheme.onSurface, width: 2.5)
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            Text('Select Icon', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.icons.map((iconName) {
                final isSelected = _selectedIcon == iconName;
                final iconData = IconHelper.getIcon(iconName);
                final color = Color(int.parse('FF${_selectedColor.replaceAll('#', '')}', radix: 16));
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = iconName;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.15) : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected ? Border.all(color: color, width: 1.5) : null,
                    ),
                    child: Icon(
                      iconData,
                      color: isSelected ? color : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 22,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = widget.nameController.text.trim();
            if (name.isEmpty) return;

            if (widget.isEdit && widget.existingFolder != null) {
              final updated = widget.existingFolder!.copyWith(
                name: name,
                parentFolderId: _selectedParentId,
                clearParentFolder: _selectedParentId == null,
                colorHex: _selectedColor,
                iconName: _selectedIcon,
                updatedAt: DateTime.now(),
              );
              widget.ref.read(foldersProvider.notifier).updateFolder(updated);
            } else {
              final newFolder = FolderModel(
                id: const Uuid().v4(),
                name: name,
                parentFolderId: _selectedParentId,
                colorHex: _selectedColor,
                iconName: _selectedIcon,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                sortOrder: widget.ref.read(foldersProvider).length + 1,
              );
              widget.ref.read(foldersProvider.notifier).addFolder(newFolder);
            }
            Navigator.pop(context);
          },
          child: Text(widget.isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
