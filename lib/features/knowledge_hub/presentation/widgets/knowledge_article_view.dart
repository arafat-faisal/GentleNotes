// Full article reader view for the Knowledge Hub.
// Renders the active article's markdown content with a clip-to-note bar.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/knowledge_article.dart';
import '../../../editor/presentation/widgets/markdown_widget.dart';

class KnowledgeArticleView extends StatefulWidget {
  final KnowledgeArticle article;
  final bool isLoading;
  final bool isSaved;
  final VoidCallback onBack;
  final VoidCallback onSaveToggle;
  final VoidCallback onClipSummary;
  final ValueChanged<String> onClipSelection;

  const KnowledgeArticleView({
    super.key,
    required this.article,
    required this.isLoading,
    required this.isSaved,
    required this.onBack,
    required this.onSaveToggle,
    required this.onClipSummary,
    required this.onClipSelection,
  });

  @override
  State<KnowledgeArticleView> createState() => _KnowledgeArticleViewState();
}

class _KnowledgeArticleViewState extends State<KnowledgeArticleView> {
  final _scrollCtrl = ScrollController();
  String? _selectedText;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _launchInBrowser(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: $url')),
          );
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.article.source.accentColor;

    return Column(
      children: [
        _buildHeader(theme, accent),
        Divider(height: 1, color: theme.dividerColor),
        Expanded(child: _buildBody(theme, accent)),
        if (_selectedText != null && _selectedText!.trim().isNotEmpty)
          _buildClipBar(theme, accent),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, Color accent) {
    final hasUrl = widget.article.url != null && widget.article.url!.startsWith('http');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: theme.cardColor,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            onPressed: widget.onBack,
          ),
          Expanded(
            child: Text(
              widget.article.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (hasUrl)
            IconButton(
              icon: const Icon(Icons.language_rounded, size: 18),
              tooltip: 'Open in integrated browser',
              onPressed: () => _launchInBrowser(widget.article.url!),
            ),
          IconButton(
            icon: Icon(
              widget.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              size: 18,
              color: widget.isSaved ? accent : null,
            ),
            onPressed: widget.onSaveToggle,
          ),
          IconButton(
            icon: const Icon(Icons.content_copy_rounded, size: 18),
            tooltip: 'Clip summary to note',
            onPressed: widget.onClipSummary,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme, Color accent) {
    if (widget.isLoading) {
      return Center(child: CircularProgressIndicator(color: accent));
    }

    final hasContent = widget.article.content.isNotEmpty;
    final url = widget.article.url;
    final hasUrl = url != null && url.startsWith('http');

    // If there’s real text content, render markdown.
    if (hasContent) {
      return SelectionArea(
        onSelectionChanged: (selection) {
          setState(() => _selectedText = selection?.plainText);
        },
        child: SingleChildScrollView(
          controller: _scrollCtrl,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildArticleMeta(theme, accent),
              const SizedBox(height: 16),
              Divider(color: theme.dividerColor),
              const SizedBox(height: 8),
              MarkdownWidget(data: widget.article.content, attachments: const []),
            ],
          ),
        ),
      );
    }

    // No inline content — show a rich landing card with the browser button.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildArticleMeta(theme, accent),
          const SizedBox(height: 24),
          if (hasUrl) ...[  
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Column(
                children: [
                  Icon(Icons.language_rounded, size: 40, color: accent),
                  const SizedBox(height: 12),
                  Text(
                    'Tap below to read this article',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    url,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => _launchInBrowser(url),
                    icon: const Icon(Icons.open_in_browser_rounded),
                    label: const Text('Open in Integrated Browser'),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text(
                      'Open in system browser instead',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[  
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.article_outlined, size: 48,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    Text('No content available.',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArticleMeta(ThemeData theme, Color accent) {
    final hasUrl = widget.article.url != null && widget.article.url!.startsWith('http');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.article.imageUrl != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.article.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, st) => const SizedBox.shrink(),
              ),
            ),
          ),
        Text(
          widget.article.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.article.source.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.article.author,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (widget.article.readTime != null) ...[
              const SizedBox(width: 8),
              Text(
                '· ${widget.article.readTime}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
        if (hasUrl) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _launchInBrowser(widget.article.url!),
            icon: const Icon(Icons.language_rounded, size: 14),
            label: const Text('Open Interactive Live Webpage', style: TextStyle(fontSize: 11)),
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: accent),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildClipBar(ThemeData theme, Color accent) {
    final preview = _selectedText!.trim().length > 60
        ? '${_selectedText!.trim().substring(0, 60)}…'
        : _selectedText!.trim();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: accent,
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.format_quote_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '"$preview"',
              style: const TextStyle(color: Colors.white, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => widget.onClipSelection(_selectedText!.trim()),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Clip to Note',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
