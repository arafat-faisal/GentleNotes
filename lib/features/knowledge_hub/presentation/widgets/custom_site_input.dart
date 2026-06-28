// Custom Site Input widget for pasting any custom URL to read or bookmark.
// Simplified: simple dialog to add bookmarked sites, and clicking opens immediately.

import 'package:flutter/material.dart';
import '../controllers/knowledge_hub_controller.dart';

class CustomSiteInput extends StatefulWidget {
  final List<Map<String, String>> savedWebsites;
  final KnowledgeHubController controller;
  final ValueChanged<String> onOpenUrl;

  const CustomSiteInput({
    super.key,
    required this.savedWebsites,
    required this.controller,
    required this.onOpenUrl,
  });

  @override
  State<CustomSiteInput> createState() => _CustomSiteInputState();
}

class _CustomSiteInputState extends State<CustomSiteInput> {
  final _urlCtrl = TextEditingController();

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  bool isHomepageUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      if (path.isEmpty || path == '/') return true;
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.length <= 1) {
        final first = segments.first;
        if (!first.contains('.') && first.length < 15) return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void _loadUrl() {
    var url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    if (isHomepageUrl(url)) {
      widget.controller.selectCustomSite(url, 'Web Feed');
    } else {
      widget.onOpenUrl(url);
    }
  }

  void _showAddBookmarkDialog() {
    final nameCtrl = TextEditingController();
    final linkCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Saved Website'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name (e.g., TechCrunch)',
                hintText: 'Enter site name',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: linkCtrl,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://example.com',
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              var url = linkCtrl.text.trim();
              if (url.isEmpty) return;
              if (!url.startsWith('http://') && !url.startsWith('https://')) {
                url = 'https://$url';
              }
              widget.controller.bookmarkSite(name.isEmpty ? 'Web Source' : name, url);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Website saved ✓'), duration: Duration(seconds: 1)),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Row 1: Direct URL Link input ──
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlCtrl,
                  decoration: InputDecoration(
                    hintText: 'Enter URL directly…',
                    prefixIcon: const Icon(Icons.link_rounded, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _loadUrl(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _loadUrl,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Open'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Row 2: Saved Websites Header & Add button ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SAVED WEBSITES',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              TextButton.icon(
                onPressed: _showAddBookmarkDialog,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Site', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Saved site cards list ──
          Expanded(
            child: widget.savedWebsites.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bookmark_border_rounded, size: 40,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text(
                            'No saved websites yet.\nTap "Add Site" to bookmark your favorite resources.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.savedWebsites.length,
                    itemBuilder: (ctx, i) {
                      final item = widget.savedWebsites[i];
                      final title = item['title'] ?? 'Custom Web Resource';
                      final url = item['url'] ?? '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF13111C) : const Color(0xFFFAF9FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          title: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          subtitle: Text(
                            url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          onTap: () => widget.controller.selectCustomSite(url, title), // Clicking the card directly opens feed!
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                            onPressed: () => widget.controller.removeBookmark(url),
                            visualDensity: VisualDensity.compact,
                          ),
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
