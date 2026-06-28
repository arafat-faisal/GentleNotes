// Reading Plan View widget for the Knowledge Hub.
// Displays must-read and optional articles checklist with editing utilities.

import 'package:flutter/material.dart';
import '../../data/models/knowledge_article.dart';
import '../controllers/knowledge_hub_controller.dart';

class ReadingPlanView extends StatelessWidget {
  final List<Map<String, dynamic>> readingPlan;
  final KnowledgeHubController controller;
  final ValueChanged<String> onOpenUrl;

  const ReadingPlanView({
    super.key,
    required this.readingPlan,
    required this.controller,
    required this.onOpenUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mustRead = readingPlan.where((item) => item['isMustRead'] == true).toList();
    final optional = readingPlan.where((item) => item['isMustRead'] != true).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, theme),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (mustRead.isNotEmpty) ...[
                    _buildSectionHeader(theme, 'MUST READ FOR TODAY', Icons.star_rounded, const Color(0xFF0EA5E9)),
                    const SizedBox(height: 8),
                    ...mustRead.map((item) => _buildPlanItemCard(context, theme, item)),
                    const SizedBox(height: 16),
                  ],
                  if (optional.isNotEmpty) ...[
                    _buildSectionHeader(theme, 'OPTIONAL READINGS', Icons.bookmarks_rounded, theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    ...optional.map((item) => _buildPlanItemCard(context, theme, item)),
                  ],
                  if (mustRead.isEmpty && optional.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(
                          'Your reading plan is empty.\nTap "Manage" to add your favorite websites.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Reading Plan',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            Text(
              'Reset daily checklist tracker',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: () => _showManagePlanDialog(context),
          icon: const Icon(Icons.settings_rounded, size: 14),
          label: const Text('Manage', style: TextStyle(fontSize: 12)),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanItemCard(BuildContext context, ThemeData theme, Map<String, dynamic> item) {
    final isDark = theme.brightness == Brightness.dark;
    final isRead = item['isReadToday'] ?? false;
    final title = item['title'] ?? 'Untitled';
    final url = item['url'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13111C) : const Color(0xFFFAF9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : theme.dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Checkbox(
          value: isRead,
          activeColor: const Color(0xFF10B981),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          onChanged: (_) => controller.toggleReadingPlanItemRead(item['id']),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            decoration: isRead ? TextDecoration.lineThrough : null,
            color: isRead ? theme.colorScheme.onSurface.withValues(alpha: 0.4) : null,
          ),
        ),
        subtitle: Text(
          url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.primary),
        onTap: () {
          // Open in reader
          if (url.startsWith('hn://')) {
            controller.switchSource(KnowledgeSource.hackerNews);
          } else if (url.startsWith('devto://')) {
            controller.switchSource(KnowledgeSource.devTo);
          } else if (url.startsWith('arxiv://')) {
            controller.switchSource(KnowledgeSource.arxiv);
          } else if (url.startsWith('github://')) {
            controller.switchSource(KnowledgeSource.github);
          } else {
            onOpenUrl(url);
          }
        },
      ),
    );
  }

  void _showManagePlanDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return _ManagePlanSheet(controller: controller, readingPlan: readingPlan);
      },
    );
  }
}

class _ManagePlanSheet extends StatefulWidget {
  final KnowledgeHubController controller;
  final List<Map<String, dynamic>> readingPlan;

  const _ManagePlanSheet({
    required this.controller,
    required this.readingPlan,
  });

  @override
  State<_ManagePlanSheet> createState() => _ManagePlanSheetState();
}

class _ManagePlanSheetState extends State<_ManagePlanSheet> {
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  bool _isMustRead = false;
  String? _editingId;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  void _resetInput() {
    setState(() {
      _titleCtrl.clear();
      _urlCtrl.clear();
      _isMustRead = false;
      _editingId = null;
    });
  }

  void _saveItem() {
    final title = _titleCtrl.text.trim();
    final url = _urlCtrl.text.trim();
    if (title.isEmpty || url.isEmpty) return;

    if (_editingId != null) {
      widget.controller.updateReadingPlanItem(_editingId!, title, url, _isMustRead);
    } else {
      widget.controller.addReadingPlanItem(title, url, _isMustRead);
    }
    _resetInput();
  }

  void _startEdit(Map<String, dynamic> item) {
    setState(() {
      _editingId = item['id'];
      _titleCtrl.text = item['title'] ?? '';
      _urlCtrl.text = item['url'] ?? '';
      _isMustRead = item['isMustRead'] ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text(
            _editingId != null ? 'Edit Reading Item' : 'Add Reading Plan Item',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Website Title', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _urlCtrl,
            decoration: const InputDecoration(
              labelText: 'Website URL (or devto://feed, hn://top)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            title: const Text('Priority MUST READ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: const Text('Highlights at top of checklist'),
            value: _isMustRead,
            onChanged: (val) => setState(() => _isMustRead = val),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_editingId != null)
                TextButton(
                  onPressed: _resetInput,
                  child: const Text('Cancel Edit'),
                ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _saveItem,
                child: Text(_editingId != null ? 'Save Changes' : 'Add to Plan'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 6),
          const Text('CURRENT PLAN ITEMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.readingPlan.length,
              itemBuilder: (ctx, i) {
                final item = widget.readingPlan[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(
                    '${item['isMustRead'] == true ? '⭐ Must Read · ' : ''}${item['url']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        onPressed: () => _startEdit(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever_rounded, size: 16, color: Colors.red),
                        onPressed: () => widget.controller.removeReadingPlanItem(item['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
