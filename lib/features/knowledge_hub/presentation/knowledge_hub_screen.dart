// Knowledge Hub screen — clean, simple layout.
// List view → Article view as a full-screen push (no nested sub-headers).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/widgets/gentle_scaffold.dart';
import '../../../models/models.dart';
import '../../notes/presentation/controllers/notes_controller.dart';
import '../data/models/knowledge_article.dart';
import 'controllers/knowledge_hub_controller.dart';
import 'widgets/knowledge_article_card.dart';
import 'widgets/knowledge_notes_panel.dart';
import 'widgets/saved_articles_sheet.dart';
import 'widgets/reading_plan_view.dart';
import 'widgets/custom_site_input.dart';

class KnowledgeHubScreen extends ConsumerStatefulWidget {
  const KnowledgeHubScreen({super.key});

  @override
  ConsumerState<KnowledgeHubScreen> createState() => _KnowledgeHubScreenState();
}

class _KnowledgeHubScreenState extends ConsumerState<KnowledgeHubScreen> {
  final _searchCtrl = TextEditingController();
  final _customTextCtrl = TextEditingController();

  final List<String> _devToTags = [
    'programming', 'webdev', 'beginners', 'python',
    'javascript', 'flutter', 'career', 'ai', 'opensource',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _customTextCtrl.dispose();
    super.dispose();
  }

  void _showSavedSheet(KnowledgeHubState hubState, KnowledgeHubController ctrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SavedArticlesSheet(
        savedArticles: hubState.savedArticles,
        onOpen: (a) {
          Navigator.of(context).pop();
          ctrl.openArticle(a);
        },
        onRemove: (a) {
          ctrl.toggleSaveArticle(a);
          Navigator.of(context).pop();
          _showSavedSheet(hubState, ctrl);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hubState = ref.watch(knowledgeHubProvider);
    final allNotes = ref.watch(notesProvider);
    final ctrl = ref.read(knowledgeHubProvider.notifier);
    ctrl.initSelectedNote(allNotes);

    final screenW = MediaQuery.of(context).size.width;
    final isDesktop = screenW > 1000;

    // When an article is selected on mobile → push the detail page.
    if (!isDesktop && hubState.activeArticle != null) {
      return _ArticleDetailPage(
        article: hubState.activeArticle!,
        isLoading: hubState.isLoadingArticle,
        isSaved: ctrl.isArticleSaved(hubState.activeArticle!.id),
        notes: allNotes,
        selectedNote: hubState.selectedNote,
        isSavingNote: hubState.isSavingNote,
        onBack: ctrl.closeArticle,
        onSaveToggle: () => ctrl.toggleSaveArticle(hubState.activeArticle!),
        onCreateNote: () => ctrl.createNote(hubState.activeArticle?.title),
        onSelectNote: (n) { if (n != null) ctrl.selectNote(n); },
        onNoteChanged: (title, body) {
          final note = hubState.selectedNote;
          if (note != null) ctrl.saveNote(note, title, body);
        },
        onOpenSourceUrl: ctrl.openUrl,
        onClipSummary: () {
          final article = hubState.activeArticle;
          final note = hubState.selectedNote;
          if (article == null || note == null) return;
          final text = '## From: ${article.title}\n\n'
              '**Source:** ${article.source.label} · ${article.author}\n\n'
              '${article.subtitle}\n\n---\n\n';
          ctrl.saveNote(note, note.title, '${note.plainText}\n$text');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Summary clipped ✓'), duration: Duration(seconds: 1)));
        },
      );
    }

    return GentleScaffold(
      title: 'Knowledge Hub',
      showBackButton: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.bookmark_border_rounded),
          tooltip: 'Saved (${hubState.savedArticles.length})',
          onPressed: () => _showSavedSheet(hubState, ctrl),
        ),
      ],
      body: isDesktop
          ? _buildDesktopLayout(hubState, allNotes, ctrl)
          : _buildMobileList(hubState, ctrl),
    );
  }

  // ── Desktop: side-by-side layout ────────────────────────────────────────

  Widget _buildDesktopLayout(
      KnowledgeHubState hubState, List<NoteModel> allNotes, KnowledgeHubController ctrl) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildSourceTabs(hubState, ctrl),
              Expanded(
                child: hubState.activeArticle != null
                    ? _DesktopArticleBody(
                        article: hubState.activeArticle!,
                        isLoading: hubState.isLoadingArticle,
                        isSaved: ctrl.isArticleSaved(hubState.activeArticle!.id),
                        onBack: ctrl.closeArticle,
                        onSaveToggle: () => ctrl.toggleSaveArticle(hubState.activeArticle!),
                      )
                    : _buildArticleList(hubState, ctrl),
              ),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: theme.dividerColor),
        Expanded(
          flex: 2,
          child: KnowledgeNotesPanel(
            notes: allNotes,
            selectedNote: hubState.selectedNote,
            isSaving: hubState.isSavingNote,
            onCreateNote: () => ctrl.createNote(hubState.activeArticle?.title),
            onSelectNote: (n) { if (n != null) ctrl.selectNote(n); },
            onNoteChanged: (title, body) {
              final note = hubState.selectedNote;
              if (note != null) ctrl.saveNote(note, title, body);
            },
            activeArticle: hubState.activeArticle,
            onOpenSourceUrl: ctrl.openUrl,
          ),
        ),
      ],
    );
  }

  // ── Mobile: source tabs + article list ────────────────────────────────

  Widget _buildMobileList(KnowledgeHubState hubState, KnowledgeHubController ctrl) {
    return Column(
      children: [
        _buildSourceTabs(hubState, ctrl),
        Expanded(child: _buildArticleList(hubState, ctrl)),
      ],
    );
  }

  // ── Source tab bar ─────────────────────────────────────────────────────

  Widget _buildSourceTabs(KnowledgeHubState state, KnowledgeHubController ctrl) {
    final theme = Theme.of(context);
    final sources = [
      KnowledgeSource.devTo,
      KnowledgeSource.hackerNews,
      KnowledgeSource.arxiv,
      KnowledgeSource.wikipedia,
      KnowledgeSource.github,
      KnowledgeSource.customUrl,
      KnowledgeSource.readingPlan,
      KnowledgeSource.customText,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: sources.map((s) {
              final isActive = state.activeSource == s;
              final accent = s.accentColor;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => ctrl.switchSource(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? accent : theme.dividerColor,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(s.icon, size: 13,
                            color: isActive ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                        const SizedBox(width: 5),
                        Text(
                          s.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Search bar for arxiv/wikipedia
        if (state.activeSource == KnowledgeSource.arxiv ||
            state.activeSource == KnowledgeSource.wikipedia)
          _buildSearchBar(ctrl),
        // Tag chips for DevTo
        if (state.activeSource == KnowledgeSource.devTo)
          _buildDevToTagChips(state, ctrl),
        Divider(height: 1, color: theme.dividerColor),
      ],
    );
  }

  Widget _buildSearchBar(KnowledgeHubController ctrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search…',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                isDense: true,
              ),
              onSubmitted: (q) => ctrl.fetchCurrentSource(searchQuery: q),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => ctrl.fetchCurrentSource(searchQuery: _searchCtrl.text),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Go', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildDevToTagChips(KnowledgeHubState state, KnowledgeHubController ctrl) {
    final accent = KnowledgeSource.devTo.accentColor;
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: _devToTags.map((tag) {
          final isActive = state.devToTag == tag;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => ctrl.switchDevToTag(tag),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive ? accent.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isActive ? accent : Theme.of(context).dividerColor),
                ),
                child: Text(
                  '#$tag',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? accent : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Article list ───────────────────────────────────────────────────────

  Widget _buildArticleList(KnowledgeHubState state, KnowledgeHubController ctrl) {
    final theme = Theme.of(context);

    if (state.activeSource == KnowledgeSource.customText) {
      return _buildCustomTextInput(ctrl);
    }
    if (state.activeSource == KnowledgeSource.customUrl) {
      if (state.customSiteActiveUrl != null) {
        return _buildCustomSiteFeedView(state, ctrl);
      }
      return CustomSiteInput(
        savedWebsites: state.savedWebsites,
        controller: ctrl,
        onOpenUrl: ctrl.openUrl,
      );
    }
    if (state.activeSource == KnowledgeSource.readingPlan) {
      return ReadingPlanView(
        readingPlan: state.readingPlan,
        controller: ctrl,
        onOpenUrl: ctrl.openUrl,
      );
    }

    if (state.isLoadingList) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: state.activeSource.accentColor),
            const SizedBox(height: 12),
            Text('Loading ${state.activeSource.label}…',
                style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }

    if (state.listError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 40),
              const SizedBox(height: 12),
              Text(state.listError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: ctrl.fetchCurrentSource,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.articles.isEmpty) {
      return const Center(child: Text('No results found.'));
    }

    return RefreshIndicator(
      onRefresh: ctrl.fetchCurrentSource,
      color: state.activeSource.accentColor,
      child: ListView.builder(
        itemCount: state.articles.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (_, i) => KnowledgeArticleCard(
          article: state.articles[i],
          isSaved: ctrl.isArticleSaved(state.articles[i].id),
          onTap: () => ctrl.openArticle(state.articles[i]),
          onSaveToggle: () => ctrl.toggleSaveArticle(state.articles[i]),
        ),
      ),
    );
  }

  Widget _buildCustomSiteFeedView(KnowledgeHubState state, KnowledgeHubController ctrl) {
    final theme = Theme.of(context);
    final accent = KnowledgeSource.customUrl.accentColor;

    if (state.isLoadingList) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: accent),
            const SizedBox(height: 12),
            Text('Scanning feed & articles…', style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }

    if (state.listError != null) {
      return Column(
        children: [
          _buildFeedHeader(state, ctrl),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 40, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text(state.listError!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: ctrl.fetchCurrentSource,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildFeedHeader(state, ctrl),
        Expanded(
          child: state.articles.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.dynamic_feed_rounded, size: 40,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        const Text(
                          'No articles found on this homepage.\nTry opening the site directly in the browser.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: ctrl.fetchCurrentSource,
                  color: accent,
                  child: ListView.builder(
                    itemCount: state.articles.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (_, i) => KnowledgeArticleCard(
                      article: state.articles[i],
                      isSaved: ctrl.isArticleSaved(state.articles[i].id),
                      onTap: () => ctrl.openArticle(state.articles[i]),
                      onSaveToggle: () => ctrl.toggleSaveArticle(state.articles[i]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFeedHeader(KnowledgeHubState state, KnowledgeHubController ctrl) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF161422) : const Color(0xFFF3F1FA),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            onPressed: ctrl.clearCustomSite,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.customSiteActiveTitle ?? 'Web Feed',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  state.customSiteActiveUrl ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded, size: 18),
            onPressed: () => ctrl.openUrl(state.customSiteActiveUrl!),
            tooltip: 'Open landing page directly',
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTextInput(KnowledgeHubController ctrl) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_rounded, size: 18),
              const SizedBox(width: 8),
              Text('Custom Text Reader',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  if (_customTextCtrl.text.trim().isNotEmpty) {
                    ctrl.openCustomText(_customTextCtrl.text.trim());
                  }
                },
                icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                label: const Text('Read', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _customTextCtrl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: 'Paste article text, newsletter excerpts…',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-screen article detail page (mobile only — replaces the hub list)
// ─────────────────────────────────────────────────────────────────────────────

class _ArticleDetailPage extends StatefulWidget {
  final KnowledgeArticle article;
  final bool isLoading;
  final bool isSaved;
  final List<NoteModel> notes;
  final NoteModel? selectedNote;
  final bool isSavingNote;
  final VoidCallback onBack;
  final VoidCallback onSaveToggle;
  final VoidCallback onCreateNote;
  final ValueChanged<NoteModel?> onSelectNote;
  final void Function(String title, String body) onNoteChanged;
  final ValueChanged<String> onOpenSourceUrl;
  final VoidCallback onClipSummary;

  const _ArticleDetailPage({
    required this.article,
    required this.isLoading,
    required this.isSaved,
    required this.notes,
    required this.selectedNote,
    required this.isSavingNote,
    required this.onBack,
    required this.onSaveToggle,
    required this.onCreateNote,
    required this.onSelectNote,
    required this.onNoteChanged,
    required this.onOpenSourceUrl,
    required this.onClipSummary,
  });

  @override
  State<_ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<_ArticleDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  String? _selectedText;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _openBrowser() async {
    final url = widget.article.url;
    if (url == null) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
    } catch (_) {
      try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open: $url')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.article.source.accentColor;
    final hasUrl = widget.article.url?.startsWith('http') == true;
    final hasContent = widget.article.content.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onBack,
        ),
        title: Text(
          widget.article.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (hasUrl)
            IconButton(
              icon: Icon(Icons.open_in_browser_rounded, color: accent),
              tooltip: 'Open in browser',
              onPressed: _openBrowser,
            ),
          IconButton(
            icon: Icon(
              widget.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: widget.isSaved ? accent : null,
            ),
            onPressed: widget.onSaveToggle,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Article'),
            Tab(text: 'Notes'),
          ],
          indicatorColor: accent,
          labelColor: accent,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabCtrl,
          children: [
            // ── Tab 1: Article content ──────────────────────────────────────
            _buildArticleTab(theme, accent, hasUrl, hasContent),
            // ── Tab 2: Notes ────────────────────────────────────────────────
            KnowledgeNotesPanel(
              notes: widget.notes,
              selectedNote: widget.selectedNote,
              isSaving: widget.isSavingNote,
              onCreateNote: widget.onCreateNote,
              onSelectNote: widget.onSelectNote,
              onNoteChanged: widget.onNoteChanged,
              activeArticle: widget.article,
              onOpenSourceUrl: widget.onOpenSourceUrl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleTab(ThemeData theme, Color accent, bool hasUrl, bool hasContent) {
    if (widget.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: accent, strokeWidth: 2.5),
            const SizedBox(height: 16),
            Text('Loading article…', style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          if (widget.article.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.article.imageUrl!,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, s) => const SizedBox.shrink(),
                ),
              ),
            ),

          // Title
          Text(
            widget.article.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 10),

          // Meta row
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(widget.article.source.label,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accent)),
              ),
              if (widget.article.author.isNotEmpty)
                Text(widget.article.author,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    )),
              if (widget.article.readTime != null)
                Text('· ${widget.article.readTime}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    )),
            ],
          ),

          if (widget.article.subtitle.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              widget.article.subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 16),

          // Browser button — always visible if there's a URL
          if (hasUrl)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openBrowser,
                icon: const Icon(Icons.open_in_browser_rounded),
                label: const Text('Open in Browser'),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

          // If there's also inline content (e.g. Dev.to markdown), show it below
          if (hasContent) ...[
            const SizedBox(height: 20),
            Divider(color: theme.dividerColor),
            const SizedBox(height: 8),
            SelectionArea(
              onSelectionChanged: (sel) => setState(() => _selectedText = sel?.plainText),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Build simple text-based markdown rendering
                  ...widget.article.content
                      .split('\n')
                      .map((line) => _renderLine(theme, line)),
                ],
              ),
            ),
            if (_selectedText != null && _selectedText!.trim().isNotEmpty)
              _buildClipBar(theme, accent),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Light markdown line renderer — no external package needed for simple content
  Widget _renderLine(ThemeData theme, String line) {
    if (line.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 6),
        child: Text(line.substring(2),
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      );
    }
    if (line.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 4),
        child: Text(line.substring(3),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      );
    }
    if (line.startsWith('### ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(line.substring(4),
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
      );
    }
    if (line.startsWith('> ')) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 3)),
          color: theme.colorScheme.primary.withValues(alpha: 0.05),
        ),
        child: Text(line.substring(2),
            style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic, height: 1.5)),
      );
    }
    if (line.startsWith('---')) {
      return Divider(height: 24, color: theme.dividerColor);
    }
    if (line.isEmpty) {
      return const SizedBox(height: 6);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        line.replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'\1')
            .replaceAll(RegExp(r'\*(.+?)\*'), r'\1')
            .replaceAll(RegExp(r'`(.+?)`'), r'\1'),
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
      ),
    );
  }

  Widget _buildClipBar(ThemeData theme, Color accent) {
    final preview = _selectedText!.trim().length > 60
        ? '${_selectedText!.trim().substring(0, 60)}…'
        : _selectedText!.trim();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          const Icon(Icons.format_quote_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text('"$preview"',
                style: const TextStyle(color: Colors.white, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              // Switch to notes tab and add clipped text
              _tabCtrl.animateTo(1);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Switched to Notes tab — paste or use the note editor.'),
                    duration: Duration(seconds: 2)));
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('→ Notes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop-only article body (used inside the side-by-side layout)
// ─────────────────────────────────────────────────────────────────────────────

class _DesktopArticleBody extends StatefulWidget {
  final KnowledgeArticle article;
  final bool isLoading;
  final bool isSaved;
  final VoidCallback onBack;
  final VoidCallback onSaveToggle;

  const _DesktopArticleBody({
    required this.article,
    required this.isLoading,
    required this.isSaved,
    required this.onBack,
    required this.onSaveToggle,
  });

  @override
  State<_DesktopArticleBody> createState() => _DesktopArticleBodyState();
}

class _DesktopArticleBodyState extends State<_DesktopArticleBody> {
  Future<void> _openBrowser() async {
    final url = widget.article.url;
    if (url == null) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
    } catch (_) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.article.source.accentColor;
    final hasUrl = widget.article.url?.startsWith('http') == true;
    final hasContent = widget.article.content.isNotEmpty;

    if (widget.isLoading) {
      return Center(child: CircularProgressIndicator(color: accent));
    }

    return Column(
      children: [
        // Sub-header with back
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: theme.cardColor,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                onPressed: widget.onBack,
              ),
              Expanded(
                child: Text(widget.article.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
              ),
              if (hasUrl)
                IconButton(
                  icon: Icon(Icons.open_in_browser_rounded, color: accent, size: 20),
                  onPressed: _openBrowser,
                ),
              IconButton(
                icon: Icon(
                  widget.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  size: 20,
                  color: widget.isSaved ? accent : null,
                ),
                onPressed: widget.onSaveToggle,
              ),
            ],
          ),
        ),
        Divider(height: 1, color: theme.dividerColor),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasUrl)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _openBrowser,
                        icon: const Icon(Icons.open_in_browser_rounded),
                        label: const Text('Open in Browser'),
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                if (hasContent)
                  Text(widget.article.content,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6))
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        widget.article.subtitle.isNotEmpty
                            ? widget.article.subtitle
                            : 'Open in browser to read this article.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
