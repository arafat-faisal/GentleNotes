import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/widgets/gentle_scaffold.dart';
import '../../../models/models.dart';
import '../data/templates_repository.dart';
import '../../../core/services/export_import_service.dart';


class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key});

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templates = ref.watch(templatesProvider);

    // Get list of categories
    final categories = ['All', ...templates.map((t) => t.category).toSet()];

    // Filtered templates
    final filteredTemplates = _selectedCategory == 'All'
        ? templates
        : templates.where((t) => t.category == _selectedCategory).toList();

    return GentleScaffold(
      title: 'Note Templates',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTemplateDialog(context),
        icon: const Icon(Icons.add_task),
        label: const Text('Add Template'),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.download),
          tooltip: 'Import Template JSON',
          onPressed: () => _handleImportTemplate(context),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Introductory Info Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 0,
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Structured Learning Logs',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Quickly boot up study notes, meeting notes, or hackathon plans using structured forms.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Category Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Templates Grid
          Expanded(
            child: filteredTemplates.isEmpty
                ? const Center(
                    child: Text('No templates in this category.'),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.6,
                    ),
                    itemCount: filteredTemplates.length,
                    itemBuilder: (context, index) {
                      final template = filteredTemplates[index];
                      return _buildTemplateCard(context, template);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, NoteTemplateModel template) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    template.category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Actions (Share/Export / Delete for custom)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share, size: 16),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () => _handleShareTemplate(template),
                      tooltip: 'Share template',
                    ),
                    if (!template.isBuiltIn) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        onPressed: () => _handleDeleteTemplate(context, template),
                        tooltip: 'Delete custom template',
                      ),
                    ],
                  ],
                ),
              ],
            ),
            
            // Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  template.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),

            // Footer Action Button
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/notes/create?templateId=${template.id}');
                },
                icon: const Icon(Icons.create_outlined, size: 16),
                label: const Text('Use Template', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                  foregroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ACTIONS ---

  Future<void> _handleShareTemplate(NoteTemplateModel template) async {
    await ExportImportService().shareTemplate(template);
  }

  void _handleDeleteTemplate(BuildContext context, NoteTemplateModel template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Custom Template?'),
        content: Text('Are you sure you want to delete the custom template "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(templatesProvider.notifier).deleteTemplate(template.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImportTemplate(BuildContext context) async {
    final success = await ExportImportService().pickAndImportFile();
    if (!mounted) return;
    if (success) {
      ref.read(templatesProvider.notifier).loadTemplates();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template imported successfully!'), backgroundColor: Color(0xFF10B981)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import failed or cancelled.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showAddTemplateDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final categoryController = TextEditingController();
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final tagsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Note Template'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Template Name', hintText: 'e.g. Weekly Review'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Short Description', hintText: 'What is it used for?'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category', hintText: 'e.g. Planning, Engineering'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Default Title Format', hintText: 'e.g. Review - [Date]'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contentController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Default Content Structure (Markdown)', hintText: '# Review Points\n- Successes\n- Blocks'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: tagsController,
                  decoration: const InputDecoration(labelText: 'Default Tags (comma separated)', hintText: 'weekly, summary'),
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
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final tags = tagsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                final custom = NoteTemplateModel(
                  id: const Uuid().v4(),
                  name: name,
                  description: descController.text.trim(),
                  category: categoryController.text.trim().isEmpty ? 'Custom' : categoryController.text.trim(),
                  defaultTitle: titleController.text.trim(),
                  defaultContent: contentController.text,
                  defaultTags: tags,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  isBuiltIn: false,
                );

                ref.read(templatesProvider.notifier).addTemplate(custom);
                Navigator.pop(context);
              },
              child: const Text('Save Template'),
            ),
          ],
        );
      },
    );
  }
}
