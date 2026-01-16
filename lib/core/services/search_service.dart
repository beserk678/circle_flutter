import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'cache_service.dart';
import 'analytics_service.dart';
import 'error_service.dart';

class SearchService {
  static final SearchService _instance = SearchService._internal();
  static SearchService get instance => _instance;
  SearchService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search configuration
  static const int maxSearchResults = 50;
  static const int searchCacheTimeout = 300; // 5 minutes
  static const int minQueryLength = 2;

  // Search history and suggestions
  final Map<String, List<String>> _searchHistory = {};
  final Map<String, int> _searchFrequency = {};

  void initialize() {
    _startSearchAnalytics();
  }

  // Universal search across all content types
  Future<UniversalSearchResult> universalSearch(
    String query, {
    String? circleId,
    List<SearchType>? types,
    int limit = 20,
  }) async {
    if (query.length < minQueryLength) {
      return UniversalSearchResult.empty();
    }

    // Check cache first
    final cacheKey =
        'search_${query}_${circleId ?? 'all'}_${types?.join(',') ?? 'all'}';
    final cached = await CacheService.instance.get<Map<String, dynamic>>(
      cacheKey,
    );
    if (cached != null) {
      return UniversalSearchResult.fromMap(cached);
    }

    try {
      final results = UniversalSearchResult();
      final searchTypes = types ?? SearchType.values;

      // Record search analytics
      _recordSearch(query, circleId);

      // Perform parallel searches
      final futures = <Future>[];

      if (searchTypes.contains(SearchType.posts)) {
        futures.add(
          _searchPosts(query, circleId, limit).then((posts) {
            results.posts = posts;
          }),
        );
      }

      if (searchTypes.contains(SearchType.users)) {
        futures.add(
          _searchUsers(query, limit).then((users) {
            results.users = users;
          }),
        );
      }

      if (searchTypes.contains(SearchType.tasks)) {
        futures.add(
          _searchTasks(query, circleId, limit).then((tasks) {
            results.tasks = tasks;
          }),
        );
      }

      await Future.wait(futures);

      // Cache results
      await CacheService.instance.set(
        cacheKey,
        results.toMap(),
        ttl: const Duration(seconds: searchCacheTimeout),
      );

      return results;
    } catch (e) {
      ErrorService.instance.reportError(
        AppError(
          type: ErrorType.network,
          message: 'Universal search failed',
          context: 'query: $query, error: $e',
        ),
      );
      return UniversalSearchResult.empty();
    }
  }

  // Search posts
  Future<List<SearchResult>> _searchPosts(
    String query,
    String? circleId,
    int limit,
  ) async {
    try {
      Query postsQuery = _firestore.collectionGroup('posts');

      if (circleId != null) {
        postsQuery = _firestore
            .collection('circles')
            .doc(circleId)
            .collection('posts');
      }

      final searchTerms = _generateSearchTerms(query);
      final results =
          await postsQuery
              .where('searchTerms', arrayContainsAny: searchTerms)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      return results.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SearchResult(
          id: doc.id,
          type: SearchType.posts,
          title: _truncateText(data['text'] ?? '', 100),
          content: data['text'] ?? '',
          relevanceScore: _calculateRelevance(query, data['text'] ?? ''),
          timestamp:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          metadata: {
            'authorId': data['authorId'],
            'authorName': data['authorName'],
            'circleId': data['circleId'],
          },
        );
      }).toList();
    } catch (e) {
      debugPrint('Error searching posts: $e');
      return [];
    }
  }

  // Search users
  Future<List<SearchResult>> _searchUsers(String query, int limit) async {
    try {
      final searchTerms = _generateSearchTerms(query);
      final results =
          await _firestore
              .collection('users')
              .where('searchTerms', arrayContainsAny: searchTerms)
              .limit(limit)
              .get();

      return results.docs.map((doc) {
        final data = doc.data();
        return SearchResult(
          id: doc.id,
          type: SearchType.users,
          title: data['displayName'] ?? '',
          content: data['bio'] ?? '',
          relevanceScore: _calculateRelevance(
            query,
            '${data['displayName']} ${data['bio']}',
          ),
          timestamp:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          metadata: {'email': data['email'], 'photoURL': data['photoURL']},
        );
      }).toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  // Search tasks
  Future<List<SearchResult>> _searchTasks(
    String query,
    String? circleId,
    int limit,
  ) async {
    try {
      Query tasksQuery = _firestore.collectionGroup('tasks');

      if (circleId != null) {
        tasksQuery = _firestore
            .collection('circles')
            .doc(circleId)
            .collection('tasks');
      }

      final searchTerms = _generateSearchTerms(query);
      final results =
          await tasksQuery
              .where('searchTerms', arrayContainsAny: searchTerms)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      return results.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SearchResult(
          id: doc.id,
          type: SearchType.tasks,
          title: data['title'] ?? '',
          content: data['description'] ?? '',
          relevanceScore: _calculateRelevance(
            query,
            '${data['title']} ${data['description']}',
          ),
          timestamp:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          metadata: {
            'status': data['status'],
            'priority': data['priority'],
            'assignedTo': data['assignedTo'],
          },
        );
      }).toList();
    } catch (e) {
      debugPrint('Error searching tasks: $e');
      return [];
    }
  }

  // Generate search terms for indexing
  List<String> _generateSearchTerms(String text) {
    final terms = <String>{};
    final words = text.toLowerCase().split(RegExp(r'\s+'));

    for (final word in words) {
      if (word.length >= 2) {
        terms.add(word);

        // Add partial matches
        for (int i = 2; i <= word.length; i++) {
          terms.add(word.substring(0, i));
        }
      }
    }

    return terms.toList();
  }

  // Calculate relevance score
  double _calculateRelevance(String query, String content) {
    if (content.isEmpty) return 0.0;

    final queryLower = query.toLowerCase();
    final contentLower = content.toLowerCase();

    double score = 0.0;

    // Exact match bonus
    if (contentLower.contains(queryLower)) {
      score += 10.0;
    }

    // Word match scoring
    final queryWords = queryLower.split(RegExp(r'\s+'));
    final contentWords = contentLower.split(RegExp(r'\s+'));

    for (final queryWord in queryWords) {
      for (final contentWord in contentWords) {
        if (contentWord.contains(queryWord)) {
          score += queryWord.length / contentWord.length * 5.0;
        }
      }
    }

    return score;
  }

  // Search suggestions
  List<String> getSearchSuggestions(String query, {int limit = 5}) {
    if (query.length < minQueryLength) return [];

    final suggestions = <String>[];
    final queryLower = query.toLowerCase();

    // Get from search history
    for (final entry in _searchFrequency.entries) {
      if (entry.key.toLowerCase().startsWith(queryLower) &&
          entry.key != query) {
        suggestions.add(entry.key);
      }
    }

    // Sort by frequency
    suggestions.sort(
      (a, b) => (_searchFrequency[b] ?? 0).compareTo(_searchFrequency[a] ?? 0),
    );

    return suggestions.take(limit).toList();
  }

  // Search history management
  void _recordSearch(String query, String? circleId) {
    // Update search frequency
    _searchFrequency[query] = (_searchFrequency[query] ?? 0) + 1;

    // Update search history
    final key = circleId ?? 'global';
    _searchHistory[key] ??= [];
    _searchHistory[key]!.remove(query); // Remove if exists
    _searchHistory[key]!.insert(0, query); // Add to front

    // Limit history size
    if (_searchHistory[key]!.length > 20) {
      _searchHistory[key] = _searchHistory[key]!.take(20).toList();
    }

    // Analytics
    AnalyticsService.instance.logCustomEvent('search_performed', {
      'query_length': query.length,
      'circle_id': circleId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  List<String> getSearchHistory({String? circleId, int limit = 10}) {
    final key = circleId ?? 'global';
    return _searchHistory[key]?.take(limit).toList() ?? [];
  }

  void clearSearchHistory({String? circleId}) {
    if (circleId != null) {
      _searchHistory.remove(circleId);
    } else {
      _searchHistory.clear();
      _searchFrequency.clear();
    }
  }

  // Utility methods
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  void _startSearchAnalytics() {
    Timer.periodic(const Duration(hours: 1), (timer) {
      _reportSearchAnalytics();
    });
  }

  void _reportSearchAnalytics() {
    AnalyticsService.instance.logCustomEvent('search_analytics', {
      'total_searches': _searchFrequency.values.fold(0, (a, b) => a + b),
      'unique_queries': _searchFrequency.length,
      'top_queries': _getTopQueries(5),
    });
  }

  List<String> _getTopQueries(int limit) {
    final entries = _searchFrequency.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).map((e) => e.key).toList();
  }

  void dispose() {
    _searchHistory.clear();
    _searchFrequency.clear();
  }
}

// Search models
class UniversalSearchResult {
  List<SearchResult> posts = [];
  List<SearchResult> users = [];
  List<SearchResult> tasks = [];
  List<SearchResult> files = [];
  List<SearchResult> messages = [];
  List<SearchResult> circles = [];

  UniversalSearchResult();

  UniversalSearchResult.empty();

  bool get isEmpty =>
      posts.isEmpty &&
      users.isEmpty &&
      tasks.isEmpty &&
      files.isEmpty &&
      messages.isEmpty &&
      circles.isEmpty;

  int get totalResults =>
      posts.length +
      users.length +
      tasks.length +
      files.length +
      messages.length +
      circles.length;

  Map<String, dynamic> toMap() {
    return {
      'posts': posts.map((r) => r.toMap()).toList(),
      'users': users.map((r) => r.toMap()).toList(),
      'tasks': tasks.map((r) => r.toMap()).toList(),
      'files': files.map((r) => r.toMap()).toList(),
      'messages': messages.map((r) => r.toMap()).toList(),
      'circles': circles.map((r) => r.toMap()).toList(),
    };
  }

  factory UniversalSearchResult.fromMap(Map<String, dynamic> map) {
    final result = UniversalSearchResult();
    result.posts =
        (map['posts'] as List? ?? [])
            .map((item) => SearchResult.fromMap(item))
            .toList();
    result.users =
        (map['users'] as List? ?? [])
            .map((item) => SearchResult.fromMap(item))
            .toList();
    result.tasks =
        (map['tasks'] as List? ?? [])
            .map((item) => SearchResult.fromMap(item))
            .toList();
    result.files =
        (map['files'] as List? ?? [])
            .map((item) => SearchResult.fromMap(item))
            .toList();
    result.messages =
        (map['messages'] as List? ?? [])
            .map((item) => SearchResult.fromMap(item))
            .toList();
    result.circles =
        (map['circles'] as List? ?? [])
            .map((item) => SearchResult.fromMap(item))
            .toList();
    return result;
  }
}

class SearchResult {
  final String id;
  final SearchType type;
  final String title;
  final String content;
  final double relevanceScore;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  SearchResult({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.relevanceScore,
    required this.timestamp,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString(),
      'title': title,
      'content': content,
      'relevanceScore': relevanceScore,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  factory SearchResult.fromMap(Map<String, dynamic> map) {
    return SearchResult(
      id: map['id'] ?? '',
      type: SearchType.values.firstWhere(
        (t) => t.toString() == map['type'],
        orElse: () => SearchType.posts,
      ),
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      relevanceScore: (map['relevanceScore'] ?? 0.0).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}

enum SearchType { posts, users, tasks, files, messages, circles }
