import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';
import 'error_service.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  static CacheService get instance => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;
  final Map<String, CacheEntry> _memoryCache = {};
  final Map<String, Timer> _expirationTimers = {};
  
  // Cache configuration
  static const int maxMemoryCacheSize = 100; // Maximum items in memory
  static const int maxDiskCacheSize = 500; // Maximum items on disk
  static const Duration defaultTTL = Duration(hours: 1);
  static const Duration maxTTL = Duration(days: 7);
  
  // Cache statistics
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;

  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _cleanupExpiredEntries();
      _startPeriodicCleanup();
    } catch (e) {
      ErrorService.instance.reportError(
        AppError(
          type: ErrorType.storage,
          message: 'Failed to initialize cache service',
          context: e.toString(),
        ),
      );
    }
  }

  // Memory cache operations
  T? getFromMemory<T>(String key) {
    final entry = _memoryCache[key];
    if (entry == null) return null;
    
    if (entry.isExpired) {
      _removeFromMemory(key);
      return null;
    }
    
    entry.lastAccessed = DateTime.now();
    _hits++;
    return entry.value as T?;
  }

  void setInMemory<T>(String key, T value, {Duration? ttl}) {
    final expiration = DateTime.now().add(ttl ?? defaultTTL);
    
    // Evict oldest entries if cache is full
    if (_memoryCache.length >= maxMemoryCacheSize) {
      _evictLeastRecentlyUsed();
    }
    
    final entry = CacheEntry(
      key: key,
      value: value,
      expiration: expiration,
      lastAccessed: DateTime.now(),
    );
    
    _memoryCache[key] = entry;
    
    // Set expiration timer
    _expirationTimers[key]?.cancel();
    _expirationTimers[key] = Timer(ttl ?? defaultTTL, () {
      _removeFromMemory(key);
    });
  }

  void _removeFromMemory(String key) {
    _memoryCache.remove(key);
    _expirationTimers[key]?.cancel();
    _expirationTimers.remove(key);
  }

  void _evictLeastRecentlyUsed() {
    if (_memoryCache.isEmpty) return;
    
    String? oldestKey;
    DateTime? oldestAccess;
    
    for (final entry in _memoryCache.entries) {
      if (oldestAccess == null || entry.value.lastAccessed.isBefore(oldestAccess)) {
        oldestKey = entry.key;
        oldestAccess = entry.value.lastAccessed;
      }
    }
    
    if (oldestKey != null) {
      _removeFromMemory(oldestKey);
      _evictions++;
    }
  }

  // Disk cache operations
  Future<T?> getFromDisk<T>(String key) async {
    if (_prefs == null) return null;
    
    try {
      final jsonString = _prefs!.getString('cache_$key');
      if (jsonString == null) {
        _misses++;
        return null;
      }
      
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final expiration = DateTime.fromMillisecondsSinceEpoch(data['expiration']);
      
      if (DateTime.now().isAfter(expiration)) {
        await _removeFromDisk(key);
        _misses++;
        return null;
      }
      
      _hits++;
      
      // Update last accessed time
      data['lastAccessed'] = DateTime.now().millisecondsSinceEpoch;
      await _prefs!.setString('cache_$key', jsonEncode(data));
      
      return _deserializeValue<T>(data['value'], data['type']);
    } catch (e) {
      ErrorService.instance.reportError(
        AppError(
          type: ErrorType.storage,
          message: 'Failed to get from disk cache: $key',
          context: e.toString(),
        ),
      );
      return null;
    }
  }

  Future<void> setOnDisk<T>(String key, T value, {Duration? ttl}) async {
    if (_prefs == null) return;
    
    try {
      final expiration = DateTime.now().add(ttl ?? defaultTTL);
      final data = {
        'value': _serializeValue(value),
        'type': T.toString(),
        'expiration': expiration.millisecondsSinceEpoch,
        'lastAccessed': DateTime.now().millisecondsSinceEpoch,
      };
      
      await _prefs!.setString('cache_$key', jsonEncode(data));
      
      // Check if we need to evict old entries
      await _evictOldDiskEntries();
    } catch (e) {
      ErrorService.instance.reportError(
        AppError(
          type: ErrorType.storage,
          message: 'Failed to set disk cache: $key',
          context: e.toString(),
        ),
      );
    }
  }

  Future<void> _removeFromDisk(String key) async {
    if (_prefs == null) return;
    await _prefs!.remove('cache_$key');
  }

  // Combined cache operations (memory + disk)
  Future<T?> get<T>(String key) async {
    // Try memory cache first
    final memoryResult = getFromMemory<T>(key);
    if (memoryResult != null) {
      return memoryResult;
    }
    
    // Try disk cache
    final diskResult = await getFromDisk<T>(key);
    if (diskResult != null) {
      // Promote to memory cache
      setInMemory(key, diskResult);
      return diskResult;
    }
    
    _misses++;
    return null;
  }

  Future<void> set<T>(String key, T value, {Duration? ttl, bool memoryOnly = false}) async {
    // Always set in memory
    setInMemory(key, value, ttl: ttl);
    
    // Set on disk unless memory-only
    if (!memoryOnly) {
      await setOnDisk(key, value, ttl: ttl);
    }
  }

  Future<void> remove(String key) async {
    _removeFromMemory(key);
    await _removeFromDisk(key);
  }

  // Specialized cache methods for common data types
  Future<void> cacheUserProfile(String userId, Map<String, dynamic> profile) async {
    await set('user_profile_$userId', profile, ttl: const Duration(hours: 2));
  }

  Future<Map<String, dynamic>?> getCachedUserProfile(String userId) async {
    return await get<Map<String, dynamic>>('user_profile_$userId');
  }

  Future<void> cacheCircleData(String circleId, Map<String, dynamic> data) async {
    await set('circle_data_$circleId', data, ttl: const Duration(minutes: 30));
  }

  Future<Map<String, dynamic>?> getCachedCircleData(String circleId) async {
    return await get<Map<String, dynamic>>('circle_data_$circleId');
  }

  Future<void> cacheFeedPosts(String circleId, List<Map<String, dynamic>> posts) async {
    await set('feed_posts_$circleId', posts, ttl: const Duration(minutes: 15));
  }

  Future<List<Map<String, dynamic>>?> getCachedFeedPosts(String circleId) async {
    return await get<List<Map<String, dynamic>>>('feed_posts_$circleId');
  }

  Future<void> cacheMessages(String circleId, List<Map<String, dynamic>> messages) async {
    await set('messages_$circleId', messages, ttl: const Duration(minutes: 10), memoryOnly: true);
  }

  Future<List<Map<String, dynamic>>?> getCachedMessages(String circleId) async {
    return await get<List<Map<String, dynamic>>>('messages_$circleId');
  }

  // File cache operations
  Future<void> cacheFile(String key, Uint8List data) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/cache_$key');
      await file.writeAsBytes(data);
      
      // Store metadata
      await set('file_meta_$key', {
        'path': file.path,
        'size': data.length,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      }, ttl: const Duration(hours: 24));
    } catch (e) {
      ErrorService.instance.reportError(
        AppError(
          type: ErrorType.storage,
          message: 'Failed to cache file: $key',
          context: e.toString(),
        ),
      );
    }
  }

  Future<Uint8List?> getCachedFile(String key) async {
    try {
      final metadata = await get<Map<String, dynamic>>('file_meta_$key');
      if (metadata == null) return null;
      
      final file = File(metadata['path']);
      if (!await file.exists()) {
        await remove('file_meta_$key');
        return null;
      }
      
      return await file.readAsBytes();
    } catch (e) {
      ErrorService.instance.reportError(
        AppError(
          type: ErrorType.storage,
          message: 'Failed to get cached file: $key',
          context: e.toString(),
        ),
      );
      return null;
    }
  }

  // Cache invalidation
  Future<void> invalidatePattern(String pattern) async {
    final regex = RegExp(pattern);
    
    // Invalidate memory cache
    final memoryKeysToRemove = _memoryCache.keys.where((key) => regex.hasMatch(key)).toList();
    for (final key in memoryKeysToRemove) {
      _removeFromMemory(key);
    }
    
    // Invalidate disk cache
    if (_prefs != null) {
      final allKeys = _prefs!.getKeys();
      final diskKeysToRemove = allKeys.where((key) => 
        key.startsWith('cache_') && regex.hasMatch(key.substring(6))
      ).toList();
      
      for (final key in diskKeysToRemove) {
        await _prefs!.remove(key);
      }
    }
  }

  Future<void> invalidateUser(String userId) async {
    await invalidatePattern('user_.*_$userId');
  }

  Future<void> invalidateCircle(String circleId) async {
    await invalidatePattern('.*_$circleId');
  }

  // Cache maintenance
  Future<void> _cleanupExpiredEntries() async {
    if (_prefs == null) return;
    
    try {
      final allKeys = _prefs!.getKeys();
      final cacheKeys = allKeys.where((key) => key.startsWith('cache_')).toList();
      
      for (final key in cacheKeys) {
        final jsonString = _prefs!.getString(key);
        if (jsonString != null) {
          final data = jsonDecode(jsonString) as Map<String, dynamic>;
          final expiration = DateTime.fromMillisecondsSinceEpoch(data['expiration']);
          
          if (DateTime.now().isAfter(expiration)) {
            await _prefs!.remove(key);
          }
        }
      }
    } catch (e) {
      ErrorService.instance.reportError(
        AppError(
          type: ErrorType.storage,
          message: 'Failed to cleanup expired cache entries',
          context: e.toString(),
        ),
      );
    }
  }

  Future<void> _evictOldDiskEntries() async {
    if (_prefs == null) return;
    
    try {
      final allKeys = _prefs!.getKeys();
      final cacheKeys = allKeys.where((key) => key.startsWith('cache_')).toList();
      
      if (cacheKeys.length <= maxDiskCacheSize) return;
      
      // Get all entries with their last accessed times
      final entries = <MapEntry<String, DateTime>>[];
      
      for (final key in cacheKeys) {
        final jsonString = _prefs!.getString(key);
        if (jsonString != null) {
          final data = jsonDecode(jsonString) as Map<String, dynamic>;
          final lastAccessed = DateTime.fromMillisecondsSinceEpoch(data['lastAccessed']);
          entries.add(MapEntry(key, lastAccessed));
        }
      }
      
      // Sort by last accessed time (oldest first)
      entries.sort((a, b) => a.value.compareTo(b.value));
      
      // Remove oldest entries
      final entriesToRemove = entries.take(cacheKeys.length - maxDiskCacheSize);
      for (final entry in entriesToRemove) {
        await _prefs!.remove(entry.key);
        _evictions++;
      }
    } catch (e) {
      ErrorService.instance.reportError(
        AppError(
          type: ErrorType.storage,
          message: 'Failed to evict old disk cache entries',
          context: e.toString(),
        ),
      );
    }
  }

  void _startPeriodicCleanup() {
    Timer.periodic(const Duration(hours: 1), (timer) {
      _cleanupExpiredEntries();
      _reportCacheStatistics();
    });
  }

  void _reportCacheStatistics() {
    final hitRate = _hits + _misses > 0 ? _hits / (_hits + _misses) : 0.0;
    
    AnalyticsService.instance.logCustomEvent('cache_statistics', {
      'memory_cache_size': _memoryCache.length,
      'hits': _hits,
      'misses': _misses,
      'evictions': _evictions,
      'hit_rate': hitRate,
    });
  }

  // Serialization helpers
  dynamic _serializeValue<T>(T value) {
    if (value is String || value is num || value is bool) {
      return value;
    } else if (value is List || value is Map) {
      return value;
    } else {
      return value.toString();
    }
  }

  T? _deserializeValue<T>(dynamic value, String type) {
    try {
      if (type.contains('List<Map<String, dynamic>>')) {
        return (value as List).cast<Map<String, dynamic>>() as T;
      } else if (type.contains('Map<String, dynamic>')) {
        return (value as Map<String, dynamic>) as T;
      } else if (type.contains('List')) {
        return (value as List) as T;
      } else {
        return value as T;
      }
    } catch (e) {
      return null;
    }
  }

  // Cache statistics
  CacheStatistics get statistics => CacheStatistics(
    memorySize: _memoryCache.length,
    hits: _hits,
    misses: _misses,
    evictions: _evictions,
    hitRate: _hits + _misses > 0 ? _hits / (_hits + _misses) : 0.0,
  );

  // Clear all cache
  Future<void> clearAll() async {
    // Clear memory cache
    for (final timer in _expirationTimers.values) {
      timer.cancel();
    }
    _memoryCache.clear();
    _expirationTimers.clear();
    
    // Clear disk cache
    if (_prefs != null) {
      final allKeys = _prefs!.getKeys();
      final cacheKeys = allKeys.where((key) => key.startsWith('cache_')).toList();
      for (final key in cacheKeys) {
        await _prefs!.remove(key);
      }
    }
    
    // Clear file cache
    try {
      final directory = await getTemporaryDirectory();
      final files = directory.listSync().where((file) => 
        file.path.contains('cache_')
      ).toList();
      
      for (final file in files) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Failed to clear file cache: $e');
    }
  }

  void dispose() {
    for (final timer in _expirationTimers.values) {
      timer.cancel();
    }
    _expirationTimers.clear();
    _memoryCache.clear();
  }
}

class CacheEntry {
  final String key;
  final dynamic value;
  final DateTime expiration;
  DateTime lastAccessed;
  
  CacheEntry({
    required this.key,
    required this.value,
    required this.expiration,
    required this.lastAccessed,
  });
  
  bool get isExpired => DateTime.now().isAfter(expiration);
}

class CacheStatistics {
  final int memorySize;
  final int hits;
  final int misses;
  final int evictions;
  final double hitRate;
  
  CacheStatistics({
    required this.memorySize,
    required this.hits,
    required this.misses,
    required this.evictions,
    required this.hitRate,
  });
}