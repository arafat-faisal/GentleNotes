// Riverpod controller for Knowledge Hub feature state.
// Manages source selection, article lists, loading states, saved articles,
// reading plan, bookmarks, and reading history. No UI code.

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../models/models.dart';
import '../../../notes/presentation/controllers/notes_controller.dart';
import '../../data/models/knowledge_article.dart';
import '../../data/services/knowledge_hub_service.dart';
import '../../data/services/knowledge_hub_storage.dart';

class KnowledgeHubState {
  final KnowledgeSource activeSource;
  final List<KnowledgeArticle> articles;
  final KnowledgeArticle? activeArticle;
  final bool isLoadingList;
  final bool isLoadingArticle;
  final String? listError;
  final List<KnowledgeArticle> savedArticles;
  final List<KnowledgeArticle> readingHistory;
  final String devToTag;
  final bool isSavingNote;
  final NoteModel? selectedNote;

  // Bookmarks & Plan
  final List<Map<String, String>> savedWebsites;
  final List<Map<String, dynamic>> readingPlan;

  // Selected Custom Site URL and Title (to load feed articles inside Knowledge Hub)
  final String? customSiteActiveUrl;
  final String? customSiteActiveTitle;

  const KnowledgeHubState({
    this.activeSource = KnowledgeSource.devTo,
    this.articles = const [],
    this.activeArticle,
    this.isLoadingList = false,
    this.isLoadingArticle = false,
    this.listError,
    this.savedArticles = const [],
    this.readingHistory = const [],
    this.devToTag = 'programming',
    this.isSavingNote = false,
    this.selectedNote,
    this.savedWebsites = const [],
    this.readingPlan = const [],
    this.customSiteActiveUrl,
    this.customSiteActiveTitle,
  });

  KnowledgeHubState copyWith({
    KnowledgeSource? activeSource,
    List<KnowledgeArticle>? articles,
    KnowledgeArticle? activeArticle,
    bool clearActiveArticle = false,
    bool? isLoadingList,
    bool? isLoadingArticle,
    String? listError,
    bool clearListError = false,
    List<KnowledgeArticle>? savedArticles,
    List<KnowledgeArticle>? readingHistory,
    String? devToTag,
    bool? isSavingNote,
    NoteModel? selectedNote,
    bool clearSelectedNote = false,
    List<Map<String, String>>? savedWebsites,
    List<Map<String, dynamic>>? readingPlan,
    String? customSiteActiveUrl,
    bool clearCustomSiteActiveUrl = false,
    String? customSiteActiveTitle,
    bool clearCustomSiteActiveTitle = false,
  }) {
    return KnowledgeHubState(
      activeSource: activeSource ?? this.activeSource,
      articles: articles ?? this.articles,
      activeArticle: clearActiveArticle ? null : (activeArticle ?? this.activeArticle),
      isLoadingList: isLoadingList ?? this.isLoadingList,
      isLoadingArticle: isLoadingArticle ?? this.isLoadingArticle,
      listError: clearListError ? null : (listError ?? this.listError),
      savedArticles: savedArticles ?? this.savedArticles,
      readingHistory: readingHistory ?? this.readingHistory,
      devToTag: devToTag ?? this.devToTag,
      isSavingNote: isSavingNote ?? this.isSavingNote,
      selectedNote: clearSelectedNote ? null : (selectedNote ?? this.selectedNote),
      savedWebsites: savedWebsites ?? this.savedWebsites,
      readingPlan: readingPlan ?? this.readingPlan,
      customSiteActiveUrl: clearCustomSiteActiveUrl ? null : (customSiteActiveUrl ?? this.customSiteActiveUrl),
      customSiteActiveTitle: clearCustomSiteActiveTitle ? null : (customSiteActiveTitle ?? this.customSiteActiveTitle),
    );
  }
}

class KnowledgeHubController extends StateNotifier<KnowledgeHubState> {
  final KnowledgeHubService _service;
  final KnowledgeHubStorage _storage;
  final Ref _ref;

  KnowledgeHubController(this._ref)
      : _service = KnowledgeHubService(),
        _storage = KnowledgeHubStorage(),
        super(const KnowledgeHubState()) {
    _loadPersistedData();
    fetchCurrentSource();
  }

  void _loadPersistedData() {
    final websites = _storage.getSavedSites();
    final plan = _storage.getReadingPlan();
    state = state.copyWith(savedWebsites: websites, readingPlan: plan);
  }

  Future<void> fetchCurrentSource({String? searchQuery}) async {
    state = state.copyWith(
      isLoadingList: true,
      articles: [],
      clearListError: true,
      clearActiveArticle: true,
    );
    try {
      final List<KnowledgeArticle> articles;
      switch (state.activeSource) {
        case KnowledgeSource.devTo:
          articles = await _service.fetchDevTo(state.devToTag);
          break;
        case KnowledgeSource.hackerNews:
          articles = await _service.fetchHackerNews();
          break;
        case KnowledgeSource.arxiv:
          articles = await _service.fetchArxiv(
              searchQuery?.isNotEmpty == true ? searchQuery! : 'machine learning');
          break;
        case KnowledgeSource.wikipedia:
          articles = await _service.searchWikipedia(
              searchQuery?.isNotEmpty == true ? searchQuery! : 'Computer science');
          break;
        case KnowledgeSource.github:
          articles = await _service.fetchGitHubTrending();
          break;
        case KnowledgeSource.customUrl:
          if (state.customSiteActiveUrl != null) {
            articles = await _service.fetchCustomSiteArticles(state.customSiteActiveUrl!);
          } else {
            articles = [];
          }
          break;
        case KnowledgeSource.customText:
        case KnowledgeSource.readingPlan:
          articles = [];
          break;
      }
      state = state.copyWith(articles: articles, isLoadingList: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingList: false,
        listError: 'Failed to load content. Check your connection.',
      );
    }
  }

  void switchSource(KnowledgeSource source) {
    state = state.copyWith(
      activeSource: source,
      articles: [],
      clearActiveArticle: true,
      clearListError: true,
      clearCustomSiteActiveUrl: source != KnowledgeSource.customUrl,
      clearCustomSiteActiveTitle: source != KnowledgeSource.customUrl,
    );
    fetchCurrentSource();
  }

  void selectCustomSite(String url, String title) {
    state = state.copyWith(
      customSiteActiveUrl: url,
      customSiteActiveTitle: title,
      clearActiveArticle: true,
    );
    fetchCurrentSource();
  }

  void clearCustomSite() {
    state = state.copyWith(
      clearCustomSiteActiveUrl: true,
      clearCustomSiteActiveTitle: true,
      clearActiveArticle: true,
      articles: [],
    );
  }

  void switchDevToTag(String tag) {
    state = state.copyWith(devToTag: tag, articles: []);
    _service.fetchDevTo(tag).then((articles) {
      state = state.copyWith(articles: articles, isLoadingList: false);
    }).catchError((_) {
      state = state.copyWith(
          isLoadingList: false, listError: 'Failed to load Dev.to articles.');
    });
  }

  Future<void> openArticle(KnowledgeArticle article) async {
    final history = [
      article,
      ...state.readingHistory.where((a) => a.id != article.id),
    ];

    // For sources with inline content already, show immediately.
    if (article.content.isNotEmpty) {
      state = state.copyWith(
          activeArticle: article, isLoadingArticle: false, readingHistory: history);
      return;
    }

    // Only fetch via API for sources that have a reliable server-side API.
    // For all external URL sources (HN, GitHub, custom links), show article
    // metadata immediately and let the user open in the integrated browser.
    if (article.source == KnowledgeSource.devTo ||
        article.source == KnowledgeSource.wikipedia) {
      state = state.copyWith(
          activeArticle: article, isLoadingArticle: true, readingHistory: history);
      try {
        final String body;
        if (article.source == KnowledgeSource.devTo) {
          body = await _service.fetchDevToBody(article.id);
        } else {
          body = await _service.fetchWikipediaBody(article.title);
        }
        state = state.copyWith(
          activeArticle: article.copyWith(content: body),
          isLoadingArticle: false,
        );
      } catch (e) {
        // Even on failure, show the article card so the browser button is visible.
        state = state.copyWith(
          isLoadingArticle: false,
          activeArticle: article,
        );
      }
    } else {
      // For HackerNews, GitHub, CustomUrl, ReadingPlan — show metadata immediately.
      // The article view will show the browser launch button.
      state = state.copyWith(
          activeArticle: article, isLoadingArticle: false, readingHistory: history);
    }
  }

  Future<void> openUrl(String url) async {
    state = state.copyWith(
      isLoadingArticle: true,
      activeArticle: KnowledgeArticle(
        id: url,
        title: 'Loading website…',
        subtitle: url,
        author: '',
        content: '',
        url: url,
        source: KnowledgeSource.customUrl,
      ),
    );

    try {
      final article = await _service.fetchCustomUrlContent(url);
      state = state.copyWith(
        activeArticle: article,
        isLoadingArticle: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingArticle: false,
        activeArticle: KnowledgeArticle(
          id: url,
          title: 'Load Failed',
          subtitle: url,
          author: '',
          content: '### Failed to load website directly.\n\n'
              'Due to browser CORS limits or site security configurations, direct page scraping might be blocked.\n\n'
              '**Suggestions:**\n'
              '- Tap the open-in-new-window button to read it in your browser.\n'
              '- Copy/paste the text manually into the **Custom Text** reader.\n\n'
              '*Source URL: $url*',
          url: url,
          source: KnowledgeSource.customUrl,
        ),
      );
    }
  }

  void openCustomText(String text) {
    final article = KnowledgeArticle(
      id: const Uuid().v4(),
      title: 'Custom Content',
      subtitle: '',
      author: 'You',
      content: text,
      source: KnowledgeSource.customText,
    );
    state = state.copyWith(activeArticle: article);
  }

  void closeArticle() {
    state = state.copyWith(clearActiveArticle: true);
  }

  void toggleSaveArticle(KnowledgeArticle article) {
    final saved = List<KnowledgeArticle>.from(state.savedArticles);
    final idx = saved.indexWhere((a) => a.id == article.id);
    if (idx >= 0) {
      saved.removeAt(idx);
    } else {
      saved.insert(0, article);
    }
    state = state.copyWith(savedArticles: saved);
  }

  bool isArticleSaved(String id) => state.savedArticles.any((a) => a.id == id);

  // ── Bookmarks ─────────────────────────────────────────────────────────────

  Future<void> bookmarkSite(String title, String url) async {
    final current = List<Map<String, String>>.from(state.savedWebsites);
    if (current.any((w) => w['url'] == url)) return;
    current.add({'title': title, 'url': url});
    await _storage.saveSites(current);
    state = state.copyWith(savedWebsites: current);
  }

  Future<void> removeBookmark(String url) async {
    final current = List<Map<String, String>>.from(state.savedWebsites)
      ..removeWhere((w) => w['url'] == url);
    await _storage.saveSites(current);
    state = state.copyWith(savedWebsites: current);
  }

  // ── Reading Plan ──────────────────────────────────────────────────────────

  Future<void> addReadingPlanItem(String title, String url, bool isMustRead) async {
    final current = List<Map<String, dynamic>>.from(state.readingPlan);
    final todayStr = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    current.add({
      'id': const Uuid().v4(),
      'title': title,
      'url': url,
      'isMustRead': isMustRead,
      'isReadToday': false,
      'lastReadDate': todayStr,
    });
    await _storage.saveReadingPlan(current);
    state = state.copyWith(readingPlan: current);
  }

  Future<void> removeReadingPlanItem(String id) async {
    final current = List<Map<String, dynamic>>.from(state.readingPlan)
      ..removeWhere((item) => item['id'] == id);
    await _storage.saveReadingPlan(current);
    state = state.copyWith(readingPlan: current);
  }

  Future<void> toggleReadingPlanItemRead(String id) async {
    final current = state.readingPlan.map((item) {
      if (item['id'] == id) {
        final Map<String, dynamic> updated = Map<String, dynamic>.from(item);
        updated['isReadToday'] = !(updated['isReadToday'] ?? false);
        return updated;
      }
      return item;
    }).toList();
    await _storage.saveReadingPlan(current);
    state = state.copyWith(readingPlan: current);
  }

  Future<void> updateReadingPlanItem(
      String id, String title, String url, bool isMustRead) async {
    final current = state.readingPlan.map((item) {
      if (item['id'] == id) {
        final Map<String, dynamic> updated = Map<String, dynamic>.from(item);
        updated['title'] = title;
        updated['url'] = url;
        updated['isMustRead'] = isMustRead;
        return updated;
      }
      return item;
    }).toList();
    await _storage.saveReadingPlan(current);
    state = state.copyWith(readingPlan: current);
  }

  // ── Note operations ──────────────────────────────────────────────────────

  void selectNote(NoteModel note) {
    state = state.copyWith(selectedNote: note);
  }

  Future<void> createNote(String? suggestedTitle) async {
    final id = const Uuid().v4();
    final title = suggestedTitle ?? 'Hub Note';
    final note = NoteModel(
      id: id,
      title: title,
      content: '{"ops":[{"insert":"\\n"}]}',
      noteType: NoteType.mixed,
      tags: ['KnowledgeHub'],
      attachments: [],
      isPinned: false,
      isFavorite: false,
      colorHex: '#FFFFFF',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _ref.read(notesProvider.notifier).addNote(note);
    await Future.delayed(const Duration(milliseconds: 100));
    final list = _ref.read(notesProvider);
    final saved = list.firstWhere((n) => n.id == id, orElse: () => note);
    state = state.copyWith(selectedNote: saved);
  }

  Future<void> saveNote(NoteModel note, String title, String body) async {
    state = state.copyWith(isSavingNote: true);
    // If body is already a Quill delta JSON object (sent from QuillEditor), store as-is.
    // Otherwise wrap plain text into a minimal Quill delta (legacy path).
    final content = body.trimLeft().startsWith('{')
        ? body
        : json.encode({'ops': [{'insert': '${body.trim()}\n'}]});
    final updated = note.copyWith(
      title: title.trim().isEmpty ? note.title : title.trim(),
      content: content,
      updatedAt: DateTime.now(),
    );
    await _ref.read(notesProvider.notifier).updateNote(updated);
    state = state.copyWith(selectedNote: updated, isSavingNote: false);
  }


  void initSelectedNote(List<NoteModel> notes) {
    if (state.selectedNote == null && notes.isNotEmpty) {
      state = state.copyWith(selectedNote: notes.first);
    }
  }
}

final knowledgeHubProvider =
    StateNotifierProvider<KnowledgeHubController, KnowledgeHubState>((ref) {
  return KnowledgeHubController(ref);
});
