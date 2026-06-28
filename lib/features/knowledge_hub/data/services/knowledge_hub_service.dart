// KnowledgeHubService: fetches articles from all supported knowledge sources.
// Pure network/parsing logic — no UI, no state management.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/knowledge_article.dart';

class KnowledgeHubService {
  static String stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<p[^>]*>'), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#x27;', "'")
        .trim();
  }

  Future<List<KnowledgeArticle>> fetchDevTo(String tag) async {
    final resp = await http.get(
      Uri.parse('https://dev.to/api/articles?tag=$tag&per_page=20&state=rising'),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      },
    );
    if (resp.statusCode != 200) throw Exception('Dev.to error ${resp.statusCode}');
    final List data = json.decode(resp.body);
    return data.map((item) {
      final mins = item['reading_time_minutes'] ?? 0;
      return KnowledgeArticle(
        id: item['id'].toString(),
        title: item['title'] ?? 'Untitled',
        subtitle: item['description'] ?? '',
        author: item['user']?['name'] ?? 'Unknown',
        content: '',
        url: item['url'],
        imageUrl: item['cover_image'] ?? item['social_image'],
        readTime: mins > 0 ? '$mins min read' : null,
        source: KnowledgeSource.devTo,
        tags: List<String>.from(item['tag_list'] ?? []),
      );
    }).toList();
  }

  Future<String> fetchDevToBody(String articleId) async {
    final resp = await http.get(
      Uri.parse('https://dev.to/api/articles/$articleId'),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      },
    );
    if (resp.statusCode != 200) throw Exception('Dev.to body error');
    final data = json.decode(resp.body);
    return data['body_markdown'] ?? data['description'] ?? '';
  }

  Future<List<KnowledgeArticle>> fetchHackerNews() async {
    final topResp = await http.get(
      Uri.parse('https://hacker-news.firebaseio.com/v0/topstories.json'),
    );
    if (topResp.statusCode != 200) throw Exception('HN error');
    final List<dynamic> ids = json.decode(topResp.body);
    final futures = ids.take(20).map((id) =>
        http.get(Uri.parse('https://hacker-news.firebaseio.com/v0/item/$id.json')));
    final responses = await Future.wait(futures);

    final articles = <KnowledgeArticle>[];
    for (final r in responses) {
      if (r.statusCode != 200) continue;
      final item = json.decode(r.body);
      if (item == null || item['type'] != 'story') continue;
      articles.add(KnowledgeArticle(
        id: item['id'].toString(),
        title: item['title'] ?? 'No title',
        subtitle: '${item['score'] ?? 0} points · ${item['descendants'] ?? 0} comments',
        author: item['by'] ?? 'unknown',
        content: item['text'] != null
            ? stripHtml(item['text'])
            : '> *No article body. Open in browser to read.*\n\n[Read on Hacker News](${item['url'] ?? '#'})',
        url: item['url'],
        source: KnowledgeSource.hackerNews,
      ));
    }
    return articles;
  }

  Future<List<KnowledgeArticle>> fetchArxiv(String query, {int maxResults = 8}) async {
    final q = Uri.encodeQueryComponent(query);
    final resp = await http.get(Uri.parse(
        'https://export.arxiv.org/api/query?search_query=all:$q&max_results=$maxResults&sortBy=submittedDate&sortOrder=descending'));
    if (resp.statusCode != 200) throw Exception('arXiv error');

    final entryRx = RegExp(r'<entry>([\s\S]*?)</entry>');
    final titleRx = RegExp(r'<title>([\s\S]*?)</title>');
    final summaryRx = RegExp(r'<summary>([\s\S]*?)</summary>');
    final authorRx = RegExp(r'<name>([\s\S]*?)</name>');
    final idRx = RegExp(r'<id>([\s\S]*?)</id>');
    final categoryRx = RegExp(r'term="([^"]+)"');

    final papers = <KnowledgeArticle>[];
    for (final m in entryRx.allMatches(resp.body)) {
      final e = m.group(1) ?? '';
      final title = titleRx.firstMatch(e)?.group(1)?.trim().replaceAll('\n', ' ') ?? '';
      final summary = summaryRx.firstMatch(e)?.group(1)?.trim() ?? '';
      final author = authorRx.firstMatch(e)?.group(1)?.trim() ?? 'Unknown';
      final url = idRx.firstMatch(e)?.group(1)?.trim() ?? '';
      final categories = categoryRx.allMatches(e).map((c) => c.group(1)!).take(3).toList();

      papers.add(KnowledgeArticle(
        id: url,
        title: title,
        subtitle: 'by $author',
        author: author,
        content: '# $title\n\n**Authors:** $author\n\n**Categories:** ${categories.join(', ')}\n\n## Abstract\n\n$summary\n\n---\n\n*[Read full paper on arXiv]($url)*',
        url: url,
        source: KnowledgeSource.arxiv,
        tags: categories,
      ));
    }
    return papers;
  }

  Future<List<KnowledgeArticle>> searchWikipedia(String query) async {
    final q = Uri.encodeQueryComponent(query);
    final resp = await http.get(Uri.parse(
        'https://en.wikipedia.org/w/api.php?action=opensearch&search=$q&limit=12&format=json'));
    if (resp.statusCode != 200) throw Exception('Wikipedia search error');
    final data = json.decode(resp.body) as List;
    final titles = List<String>.from(data[1]);
    final descriptions = List<String>.from(data[2]);
    final urls = List<String>.from(data[3]);

    return List.generate(titles.length, (i) => KnowledgeArticle(
      id: titles[i],
      title: titles[i],
      subtitle: descriptions[i].isEmpty ? 'Wikipedia article' : descriptions[i],
      author: 'Wikipedia',
      content: '',
      url: urls[i],
      source: KnowledgeSource.wikipedia,
    ));
  }

  Future<String> fetchWikipediaBody(String title) async {
    final encoded = Uri.encodeComponent(title.replaceAll(' ', '_'));
    final resp = await http.get(
        Uri.parse('https://en.wikipedia.org/api/rest_v1/page/summary/$encoded'));
    if (resp.statusCode != 200) throw Exception('Wikipedia body error');
    final data = json.decode(resp.body);
    final extract = data['extract'] ?? '';
    final thumbnail = data['thumbnail']?['source'];
    final wikiUrl = data['content_urls']?['desktop']?['page'] ?? '';
    final imgSection = thumbnail != null ? '![$title]($thumbnail)\n\n' : '';
    return '# $title\n\n$imgSection$extract\n\n---\n\n*[Read full article on Wikipedia]($wikiUrl)*';
  }

  Future<List<KnowledgeArticle>> fetchGitHubTrending() async {
    final since = DateTime.now().subtract(const Duration(days: 7));
    final dateStr =
        '${since.year}-${since.month.toString().padLeft(2, '0')}-${since.day.toString().padLeft(2, '0')}';
    final resp = await http.get(
      Uri.parse(
          'https://api.github.com/search/repositories?q=created:>$dateStr&sort=stars&order=desc&per_page=20'),
      headers: {'Accept': 'application/vnd.github.v3+json'},
    );
    if (resp.statusCode != 200) throw Exception('GitHub error');
    final List items = json.decode(resp.body)['items'] ?? [];
    return items.map<KnowledgeArticle>((item) {
      return KnowledgeArticle(
        id: item['id'].toString(),
        title: item['full_name'] ?? '',
        subtitle: item['description'] ?? 'No description',
        author: item['owner']?['login'] ?? 'unknown',
        content: '# ${item['full_name']}\n\n${item['description'] ?? ''}\n\n'
            '| Metric | Value |\n|---|---|\n'
            '| ⭐ Stars | ${item['stargazers_count']} |\n'
            '| 🍴 Forks | ${item['forks_count']} |\n'
            '| 📝 Language | ${item['language'] ?? 'N/A'} |\n'
            '| 📅 Created | ${item['created_at']?.substring(0, 10) ?? ''} |\n\n'
            '---\n\n*[View on GitHub](${item['html_url']})*',
        url: item['html_url'],
        source: KnowledgeSource.github,
        tags: [if (item['language'] != null) item['language'], 'open-source'],
      );
    }).toList();
  }

  Future<KnowledgeArticle> fetchCustomUrlContent(String url) async {
    final uri = Uri.parse(url);
    final headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    };
    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Server returned status ${resp.statusCode}');
    }
    final html = resp.body;
    
    // Attempt to extract title
    final titleRx = RegExp(r'<title>([\s\S]*?)</title>', caseSensitive: false);
    final titleMatch = titleRx.firstMatch(html);
    var title = titleMatch?.group(1)?.trim() ?? 'Custom Article';
    title = stripHtml(title);

    // Robust Universal Content Extraction (Readability-like)
    // 1. Remove non-content structural zones first
    var cleanHtml = html
        .replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<header[\s\S]*?</header>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<footer[\s\S]*?</footer>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<nav[\s\S]*?</nav>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<aside[\s\S]*?</aside>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<form[\s\S]*?</form>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<!--[\s\S]*?-->'), ''); // comments

    // 2. Identify candidate text block elements (p, div, article, section)
    final blockRx = RegExp(r'<(p|div|article|section)[^>]*>([\s\S]*?)</\1>', caseSensitive: false);
    final matches = blockRx.allMatches(cleanHtml);
    final candidateBlocks = <String>[];

    for (final match in matches) {
      final blockContent = match.group(2) ?? '';
      final textOnly = stripHtml(blockContent).trim();
      
      if (textOnly.length < 40) continue; // Skip short snippets/decorations

      // Calculate link density (characters in <a> tags vs overall text)
      final linkRx = RegExp(r'<a[^>]*>([\s\S]*?)</a>', caseSensitive: false);
      final linkMatches = linkRx.allMatches(blockContent);
      var linkCharCount = 0;
      for (final lm in linkMatches) {
        linkCharCount += stripHtml(lm.group(1) ?? '').trim().length;
      }

      final density = textOnly.isEmpty ? 0.0 : linkCharCount / textOnly.length;
      if (density > 0.4) continue; // Skip navigation blocks/footers

      candidateBlocks.add(textOnly);
    }

    // 3. Fallback: if block analysis returned too little content, use the whole body stripped
    String resultText;
    if (candidateBlocks.length < 3) {
      final bodyRx = RegExp(r'<body[^>]*>([\s\S]*?)</body>', caseSensitive: false);
      final bodyMatch = bodyRx.firstMatch(cleanHtml);
      final bodyContent = bodyMatch?.group(1) ?? cleanHtml;
      resultText = stripHtml(bodyContent)
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    } else {
      resultText = candidateBlocks.join('\n\n');
    }

    if (resultText.length > 12000) {
      resultText = '${resultText.substring(0, 12000)}\n\n*... [Content Truncated for space] ...*';
    }

    return KnowledgeArticle(
      id: url,
      title: title,
      subtitle: url,
      author: uri.host,
      content: '## $title\n\n**Source URL:** [$url]($url)\n\n---\n\n$resultText',
      url: url,
      source: KnowledgeSource.customUrl,
    );
  }

  Future<List<KnowledgeArticle>> fetchCustomSiteArticles(String siteUrl) async {
    final uri = Uri.parse(siteUrl);
    final baseUrl = '${uri.scheme}://${uri.host}';
    final headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    };

    // 1. Try to find the RSS/Atom feed URL
    String? feedUrl;
    try {
      final mainResp = await http.get(uri, headers: headers);
      if (mainResp.statusCode == 200) {
        final html = mainResp.body;
        // Search for <link rel="alternate" type="application/rss+xml" href="...">
        // or application/atom+xml
        final feedLinkRx = RegExp(
          r'<link[^>]+type="application\/(rss\+xml|atom\+xml)"[^>]+href="([^"]+)"',
          caseSensitive: false,
        );
        final match = feedLinkRx.firstMatch(html);
        if (match != null) {
          var href = match.group(2)!;
          if (href.startsWith('/')) {
            feedUrl = '$baseUrl$href';
          } else if (!href.startsWith('http')) {
            feedUrl = '$siteUrl/$href';
          } else {
            feedUrl = href;
          }
        }
      }
    } catch (_) {}

    final candidateUrls = <String>[];
    if (feedUrl != null) candidateUrls.add(feedUrl);
    candidateUrls.addAll([
      '$siteUrl/feed',
      '$siteUrl/rss',
      '$siteUrl/rss.xml',
      '$siteUrl/feed.xml',
      '$siteUrl/index.xml',
      '$baseUrl/feed',
      '$baseUrl/rss',
    ]);

    // Try each feed URL
    for (final url in candidateUrls) {
      try {
        final resp = await http.get(Uri.parse(url), headers: headers);
        if (resp.statusCode == 200 &&
            (resp.body.contains('<rss') ||
                resp.body.contains('<feed') ||
                resp.body.contains('<channel>'))) {
          final articles = _parseXmlFeed(resp.body, siteUrl);
          if (articles.isNotEmpty) return articles;
        }
      } catch (_) {}
    }

    // 2. HTML parsing fallback (Smart link extraction)
    try {
      final mainResp = await http.get(uri, headers: headers);
      if (mainResp.statusCode == 200) {
        return _parseHtmlLinks(mainResp.body, siteUrl, uri.host);
      }
    } catch (_) {}

    return [];
  }

  List<KnowledgeArticle> _parseXmlFeed(String xml, String originalUrl) {
    final list = <KnowledgeArticle>[];
    // Check if RSS channel items
    final itemRx = RegExp(r'<item>([\s\S]*?)</item>', caseSensitive: false);
    final entryRx = RegExp(r'<entry>([\s\S]*?)</entry>', caseSensitive: false);

    final titleRx = RegExp(r'<title[^>]*>([\s\S]*?)</title>', caseSensitive: false);
    final linkRx = RegExp(r'<link[^>]*>([\s\S]*?)</link>', caseSensitive: false);
    final descRx = RegExp(r'<description[^>]*>([\s\S]*?)</description>', caseSensitive: false);
    final summaryRx = RegExp(r'<summary[^>]*>([\s\S]*?)</summary>', caseSensitive: false);
    final creatorRx = RegExp(r'<dc:creator[^>]*>([\s\S]*?)</dc:creator>', caseSensitive: false);
    final authorNameRx = RegExp(r'<name[^>]*>([\s\S]*?)</name>', caseSensitive: false);

    // RSS parsing
    if (xml.contains('<item>')) {
      final matches = itemRx.allMatches(xml);
      for (final m in matches) {
        final item = m.group(1) ?? '';
        var title = titleRx.firstMatch(item)?.group(1) ?? 'Untitled';
        title = stripXmlCdata(stripHtml(title));

        var link = linkRx.firstMatch(item)?.group(1)?.trim() ?? '';
        link = stripXmlCdata(link);

        var desc = descRx.firstMatch(item)?.group(1) ?? '';
        desc = stripXmlCdata(stripHtml(desc));
        if (desc.length > 200) desc = '${desc.substring(0, 197)}…';

        var author = creatorRx.firstMatch(item)?.group(1) ?? 'Unknown';
        author = stripXmlCdata(stripHtml(author));

        if (link.isNotEmpty) {
          list.add(KnowledgeArticle(
            id: link,
            title: title,
            subtitle: desc,
            author: author,
            content: '',
            url: link,
            source: KnowledgeSource.customUrl,
          ));
        }
      }
    } 
    // Atom parsing
    else if (xml.contains('<entry>')) {
      final matches = entryRx.allMatches(xml);
      for (final m in matches) {
        final entry = m.group(1) ?? '';
        var title = titleRx.firstMatch(entry)?.group(1) ?? 'Untitled';
        title = stripXmlCdata(stripHtml(title));

        // In Atom, <link href="..." /> is standard
        final atomLinkRx = RegExp(r'<link[^>]+href="([^"]+)"', caseSensitive: false);
        var link = atomLinkRx.firstMatch(entry)?.group(1) ?? '';
        if (link.isEmpty) {
          link = linkRx.firstMatch(entry)?.group(1)?.trim() ?? '';
        }
        link = stripXmlCdata(link);

        var summary = summaryRx.firstMatch(entry)?.group(1) ??
            descRx.firstMatch(entry)?.group(1) ?? '';
        summary = stripXmlCdata(stripHtml(summary));
        if (summary.length > 200) summary = '${summary.substring(0, 197)}…';

        var author = authorNameRx.firstMatch(entry)?.group(1) ?? 'Unknown';
        author = stripXmlCdata(stripHtml(author));

        if (link.isNotEmpty) {
          list.add(KnowledgeArticle(
            id: link,
            title: title,
            subtitle: summary,
            author: author,
            content: '',
            url: link,
            source: KnowledgeSource.customUrl,
          ));
        }
      }
    }

    return list;
  }

  List<KnowledgeArticle> _parseHtmlLinks(String html, String siteUrl, String host) {
    final list = <KnowledgeArticle>[];
    // Find all links: <a href="LINK">TEXT</a>
    final anchorRx = RegExp(r'<a[^>]+href="([^"]+)"[^>]*>([\s\S]*?)</a>', caseSensitive: false);
    final matches = anchorRx.allMatches(html);

    for (final m in matches) {
      var href = m.group(1)!.trim();
      var text = stripHtml(m.group(2)!).trim();

      // Clean anchor text
      text = text.replaceAll(RegExp(r'\s+'), ' ');
      if (text.length < 25 || text.length > 150) continue; // Typical headline ranges
      if (href.startsWith('#') || href.startsWith('javascript:')) continue;

      // Handle relative paths
      if (href.startsWith('/')) {
        href = 'https://$host$href';
      } else if (!href.startsWith('http')) {
        href = '$siteUrl/$href';
      }

      // Skip non-article pages typically found on homepages
      final lowercaseHref = href.toLowerCase();
      if (lowercaseHref.contains('/login') ||
          lowercaseHref.contains('/register') ||
          lowercaseHref.contains('/about') ||
          lowercaseHref.contains('/contact') ||
          lowercaseHref.contains('/privacy') ||
          lowercaseHref.contains('/terms') ||
          lowercaseHref.contains('/search') ||
          lowercaseHref == siteUrl.toLowerCase()) {
        continue;
      }

      if (!list.any((a) => a.url == href)) {
        list.add(KnowledgeArticle(
          id: href,
          title: text,
          subtitle: href,
          author: host,
          content: '',
          url: href,
          source: KnowledgeSource.customUrl,
        ));
      }
    }
    return list;
  }

  String stripXmlCdata(String val) {
    if (val.startsWith('<![CDATA[') && val.endsWith(']]>')) {
      return val.substring(9, val.length - 3).trim();
    }
    return val;
  }
}

