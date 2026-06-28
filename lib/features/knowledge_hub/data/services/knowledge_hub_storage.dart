// Local storage helper for persisting Knowledge Hub user configurations
// (Bookmarked sites and Daily Reading Plan) inside the Hive settings box.

import 'dart:convert';
import 'package:hive/hive.dart';

class KnowledgeHubStorage {
  static const String _savedSitesKey = 'knowledge_hub_saved_sites_v1';
  static const String _readingPlanKey = 'knowledge_hub_reading_plan_v1';
  static const String _settingsBoxName = 'gentle_settings_box_v1';

  Box get _box => Hive.box(_settingsBoxName);

  // ── Bookmarked Websites ───────────────────────────────────────────────────

  List<Map<String, String>> getSavedSites() {
    try {
      final raw = _box.get(_savedSitesKey);
      if (raw == null) return [];
      final List decoded = json.decode(raw);
      return decoded.map<Map<String, String>>((item) {
        return {
          'title': (item['title'] ?? '').toString(),
          'url': (item['url'] ?? '').toString(),
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSites(List<Map<String, String>> sites) async {
    await _box.put(_savedSitesKey, json.encode(sites));
  }

  // ── Daily Reading Plan ─────────────────────────────────────────────────────

  List<Map<String, dynamic>> getReadingPlan() {
    try {
      final raw = _box.get(_readingPlanKey);
      if (raw == null) {
        return _seedDefaultReadingPlan();
      }
      final List decoded = json.decode(raw);
      final list = decoded.map<Map<String, dynamic>>((item) {
        return Map<String, dynamic>.from(item);
      }).toList();

      // Check daily reset
      final todayStr = _getTodayKey();
      var changed = false;
      for (var i = 0; i < list.length; i++) {
        if (list[i]['lastReadDate'] != todayStr) {
          list[i]['isReadToday'] = false;
          list[i]['lastReadDate'] = todayStr;
          changed = true;
        }
      }
      if (changed) {
        saveReadingPlan(list);
      }
      return list;
    } catch (_) {
      return _seedDefaultReadingPlan();
    }
  }

  Future<void> saveReadingPlan(List<Map<String, dynamic>> plan) async {
    await _box.put(_readingPlanKey, json.encode(plan));
  }

  // Helper date key YYYY-MM-DD
  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>> _seedDefaultReadingPlan() {
    final today = _getTodayKey();
    final defaultPlan = [
      {
        'id': 'p1',
        'title': 'Hacker News Top Stories',
        'url': 'hn://top',
        'isMustRead': true,
        'isReadToday': false,
        'lastReadDate': today,
      },
      {
        'id': 'p2',
        'title': 'Dev.to Tech Feed',
        'url': 'devto://feed',
        'isMustRead': true,
        'isReadToday': false,
        'lastReadDate': today,
      },
      {
        'id': 'p3',
        'title': 'arXiv Machine Learning Papers',
        'url': 'arxiv://machine-learning',
        'isMustRead': false,
        'isReadToday': false,
        'lastReadDate': today,
      },
      {
        'id': 'p4',
        'title': 'GitHub Hot Repositories',
        'url': 'github://trending',
        'isMustRead': false,
        'isReadToday': false,
        'lastReadDate': today,
      },
    ];
    saveReadingPlan(defaultPlan);
    return defaultPlan;
  }
}
