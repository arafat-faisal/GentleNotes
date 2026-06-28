// Knowledge article data model for the Knowledge Hub feature.
// Represents a single piece of content from any supported source.

import 'package:flutter/material.dart';

enum KnowledgeSource {
  devTo,
  hackerNews,
  arxiv,
  wikipedia,
  github,
  customText,
  customUrl,
  readingPlan;

  String get label {
    switch (this) {
      case KnowledgeSource.devTo:
        return 'Dev.to';
      case KnowledgeSource.hackerNews:
        return 'Hacker News';
      case KnowledgeSource.arxiv:
        return 'arXiv Papers';
      case KnowledgeSource.wikipedia:
        return 'Wikipedia';
      case KnowledgeSource.github:
        return 'GitHub Trending';
      case KnowledgeSource.customText:
        return 'Custom Text';
      case KnowledgeSource.customUrl:
        return 'Custom Link';
      case KnowledgeSource.readingPlan:
        return 'My Reading Plan';
    }
  }

  IconData get icon {
    switch (this) {
      case KnowledgeSource.devTo:
        return Icons.code_rounded;
      case KnowledgeSource.hackerNews:
        return Icons.whatshot_rounded;
      case KnowledgeSource.arxiv:
        return Icons.science_rounded;
      case KnowledgeSource.wikipedia:
        return Icons.language_rounded;
      case KnowledgeSource.github:
        return Icons.folder_special_rounded;
      case KnowledgeSource.customText:
        return Icons.edit_note_rounded;
      case KnowledgeSource.customUrl:
        return Icons.link_rounded;
      case KnowledgeSource.readingPlan:
        return Icons.playlist_add_check_rounded;
    }
  }

  Color get accentColor {
    switch (this) {
      case KnowledgeSource.devTo:
        return const Color(0xFF5856D6);
      case KnowledgeSource.hackerNews:
        return const Color(0xFFFF6600);
      case KnowledgeSource.arxiv:
        return const Color(0xFF1A73E8);
      case KnowledgeSource.wikipedia:
        return const Color(0xFF2D8A6A);
      case KnowledgeSource.github:
        return const Color(0xFF8B5CF6);
      case KnowledgeSource.customText:
        return const Color(0xFFE11D48);
      case KnowledgeSource.customUrl:
        return const Color(0xFFEC4899);
      case KnowledgeSource.readingPlan:
        return const Color(0xFF0EA5E9);
    }
  }
}

class KnowledgeArticle {
  final String id;
  final String title;
  final String subtitle;
  final String author;
  final String content; // markdown body (may be empty until fetched on-demand)
  final String? url;
  final String? imageUrl;
  final String? readTime;
  final KnowledgeSource source;
  final List<String> tags;

  const KnowledgeArticle({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.author,
    required this.content,
    this.url,
    this.imageUrl,
    this.readTime,
    required this.source,
    this.tags = const [],
  });

  KnowledgeArticle copyWith({String? content, String? subtitle}) {
    return KnowledgeArticle(
      id: id,
      title: title,
      subtitle: subtitle ?? this.subtitle,
      author: author,
      content: content ?? this.content,
      url: url,
      imageUrl: imageUrl,
      readTime: readTime,
      source: source,
      tags: tags,
    );
  }
}
