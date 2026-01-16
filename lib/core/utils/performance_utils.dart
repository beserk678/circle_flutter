import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Debouncer for search and input fields
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void cancel() {
    _timer?.cancel();
  }
}

/// Throttler for limiting function calls
class Throttler {
  final int milliseconds;
  bool _isReady = true;
  Timer? _timer;

  Throttler({required this.milliseconds});

  void run(VoidCallback action) {
    if (_isReady) {
      _isReady = false;
      action();
      _timer = Timer(Duration(milliseconds: milliseconds), () {
        _isReady = true;
      });
    }
  }

  void cancel() {
    _timer?.cancel();
  }
}

/// Memory-efficient image cache manager
class ImageCacheManager {
  static const int _maxCacheSize = 100;
  static final Map<String, ImageProvider> _cache = {};

  static ImageProvider getImage(String url) {
    if (_cache.containsKey(url)) {
      return _cache[url]!;
    }

    if (_cache.length >= _maxCacheSize) {
      // Remove oldest entry
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }

    final imageProvider = NetworkImage(url);
    _cache[url] = imageProvider;
    return imageProvider;
  }

  static void clearCache() {
    _cache.clear();
  }

  static void removeFromCache(String url) {
    _cache.remove(url);
  }
}

/// Performance monitoring utilities
class PerformanceMonitor {
  static final Map<String, Stopwatch> _stopwatches = {};

  static void startTimer(String name) {
    _stopwatches[name] = Stopwatch()..start();
  }

  static void endTimer(String name) {
    final stopwatch = _stopwatches[name];
    if (stopwatch != null) {
      stopwatch.stop();
      if (kDebugMode) {
        print('Performance: $name took ${stopwatch.elapsedMilliseconds}ms');
      }
      _stopwatches.remove(name);
    }
  }

  static void logMemoryUsage(String context) {
    if (kDebugMode) {
      // This would require additional platform-specific implementation
      print('Memory check: $context');
    }
  }
}

/// Lazy loading controller for lists
class LazyLoadController {
  final ScrollController scrollController = ScrollController();
  final VoidCallback onLoadMore;
  final double threshold;
  bool _isLoading = false;

  LazyLoadController({required this.onLoadMore, this.threshold = 200.0}) {
    scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_isLoading) return;

    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.position.pixels;

    if (maxScroll - currentScroll <= threshold) {
      _isLoading = true;
      onLoadMore();
      // Reset loading state after a delay
      Timer(const Duration(milliseconds: 500), () {
        _isLoading = false;
      });
    }
  }

  void dispose() {
    scrollController.dispose();
  }
}

/// Optimized list builder for large datasets
class OptimizedListView extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const OptimizedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Simple item builder without keep alive logic for now
        return itemBuilder(context, index);
      },
      // Optimize for performance
      cacheExtent: 250.0,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      addSemanticIndexes: true,
    );
  }
}

/// Mixin for automatic keep alive
mixin AutomaticKeepAliveClientMixin<T extends StatefulWidget> on State<T> {
  bool get wantKeepAlive;

  @override
  Widget build(BuildContext context) {
    if (wantKeepAlive) {
      return AutomaticKeepAlive(child: buildChild(context));
    }
    return buildChild(context);
  }

  Widget buildChild(BuildContext context);
}

/// Efficient state management for large lists
class ListStateManager<T> {
  final List<T> _items = [];
  final Set<int> _selectedIndices = {};
  final StreamController<List<T>> _itemsController =
      StreamController.broadcast();
  final StreamController<Set<int>> _selectionController =
      StreamController.broadcast();

  List<T> get items => List.unmodifiable(_items);
  Set<int> get selectedIndices => Set.unmodifiable(_selectedIndices);
  Stream<List<T>> get itemsStream => _itemsController.stream;
  Stream<Set<int>> get selectionStream => _selectionController.stream;

  void addItem(T item) {
    _items.add(item);
    _itemsController.add(_items);
  }

  void addItems(List<T> items) {
    _items.addAll(items);
    _itemsController.add(_items);
  }

  void removeItem(T item) {
    final index = _items.indexOf(item);
    if (index != -1) {
      _items.removeAt(index);
      _selectedIndices.remove(index);
      // Adjust selected indices
      final newSelection = <int>{};
      for (final selectedIndex in _selectedIndices) {
        if (selectedIndex > index) {
          newSelection.add(selectedIndex - 1);
        } else {
          newSelection.add(selectedIndex);
        }
      }
      _selectedIndices.clear();
      _selectedIndices.addAll(newSelection);

      _itemsController.add(_items);
      _selectionController.add(_selectedIndices);
    }
  }

  void updateItem(int index, T item) {
    if (index >= 0 && index < _items.length) {
      _items[index] = item;
      _itemsController.add(_items);
    }
  }

  void selectItem(int index) {
    if (index >= 0 && index < _items.length) {
      _selectedIndices.add(index);
      _selectionController.add(_selectedIndices);
    }
  }

  void deselectItem(int index) {
    _selectedIndices.remove(index);
    _selectionController.add(_selectedIndices);
  }

  void clearSelection() {
    _selectedIndices.clear();
    _selectionController.add(_selectedIndices);
  }

  void clear() {
    _items.clear();
    _selectedIndices.clear();
    _itemsController.add(_items);
    _selectionController.add(_selectedIndices);
  }

  void dispose() {
    _itemsController.close();
    _selectionController.close();
  }
}

/// Batch operation manager for Firestore
class BatchOperationManager {
  final List<Future<void> Function()> _operations = [];
  final int batchSize;

  BatchOperationManager({this.batchSize = 10});

  void addOperation(Future<void> Function() operation) {
    _operations.add(operation);
  }

  Future<void> executeBatch() async {
    for (int i = 0; i < _operations.length; i += batchSize) {
      final batch = _operations.skip(i).take(batchSize);
      await Future.wait(batch.map((op) => op()));

      // Add small delay between batches to prevent overwhelming the server
      if (i + batchSize < _operations.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    _operations.clear();
  }
}

/// Connection state manager
class ConnectionStateManager {
  static final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  static bool _isConnected = true;

  static Stream<bool> get connectionStream => _connectionController.stream;
  static bool get isConnected => _isConnected;

  static void updateConnectionState(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _connectionController.add(isConnected);
    }
  }

  static void dispose() {
    _connectionController.close();
  }
}

/// Efficient text formatting utilities
class TextUtils {
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  static String formatNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) return '${(number / 1000).toStringAsFixed(1)}K';
    return '${(number / 1000000).toStringAsFixed(1)}M';
  }
}
