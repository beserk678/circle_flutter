import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'analytics_service.dart';
import 'error_service.dart';
import 'cache_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  static SyncService get instance => _instance;
  SyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Active sync subscriptions
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, DateTime> _lastSyncTimes = {};
  
  // Sync queues for offline operations
  final Map<String, List<SyncOperation>> _syncQueues = {};
  final Map<String, Timer> _syncTimers = {};
  
  // Connection state
  bool _isOnline = true;
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  
  // Sync configuration
  static const Duration syncInterval = Duration(seconds: 30);
  static const Duration offlineRetryInterval = Duration(minutes: 1);
  static const int maxRetryAttempts = 3;

  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isOnline => _isOnline;

  void initialize() {
    _startConnectionMonitoring();
    _startPeriodicSync();
    _processOfflineQueue();
  }

  // Real-time sync for specific data types
  void syncCircleData(String circleId, Function(Map<String, dynamic>) onUpdate) {
    final subscriptionKey = 'circle_$circleId';
    
    // Cancel existing subscription
    _subscriptions[subscriptionKey]?.cancel();
    
    // Create new subscription
    _subscriptions[subscriptionKey] = _firestore
        .collection('circles')
        .doc(circleId)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              final data = snapshot.data()!;
              data['id'] = snapshot.id;
              onUpdate(data);
              
              // Update cache
              CacheService.instance.cacheCircleData(circleId, data);
              
              _lastSyncTimes[subscriptionKey] = DateTime.now();
            }
          },
          onError: (error) {
            ErrorService.instance.reportError(
              AppError(
                type: ErrorType.network,
                message: 'Circle sync failed',
                context: 'circleId: $circleId, error: $error',
              ),
            );
          },
        );
  }

  void syncFeedPosts(String circleId, Function(List<Map<String, dynamic>>) onUpdate) {
    final subscriptionKey = 'feed_$circleId';
    
    _subscriptions[subscriptionKey]?.cancel();
    
    _subscriptions[subscriptionKey] = _firestore
        .collection('circles')
        .doc(circleId)
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen(
          (snapshot) {
            final posts = snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();
            
            onUpdate(posts);
            
            // Update cache
            CacheService.instance.cacheFeedPosts(circleId, posts);
            
            _lastSyncTimes[subscriptionKey] = DateTime.now();
          },
          onError: (error) {
            ErrorService.instance.reportError(
              AppError(
                type: ErrorType.network,
                message: 'Feed sync failed',
                context: 'circleId: $circleId, error: $error',
              ),
            );
          },
        );
  }

  void syncMessages(String circleId, Function(List<Map<String, dynamic>>) onUpdate) {
    final subscriptionKey = 'messages_$circleId';
    
    _subscriptions[subscriptionKey]?.cancel();
    
    _subscriptions[subscriptionKey] = _firestore
        .collection('circles')
        .doc(circleId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .listen(
          (snapshot) {
            final messages = snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();
            
            onUpdate(messages.reversed.toList()); // Reverse for chronological order
            
            // Update cache
            CacheService.instance.cacheMessages(circleId, messages);
            
            _lastSyncTimes[subscriptionKey] = DateTime.now();
          },
          onError: (error) {
            ErrorService.instance.reportError(
              AppError(
                type: ErrorType.network,
                message: 'Messages sync failed',
                context: 'circleId: $circleId, error: $error',
              ),
            );
          },
        );
  }

  void syncTasks(String circleId, Function(List<Map<String, dynamic>>) onUpdate) {
    final subscriptionKey = 'tasks_$circleId';
    
    _subscriptions[subscriptionKey]?.cancel();
    
    _subscriptions[subscriptionKey] = _firestore
        .collection('circles')
        .doc(circleId)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final tasks = snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();
            
            onUpdate(tasks);
            
            _lastSyncTimes[subscriptionKey] = DateTime.now();
          },
          onError: (error) {
            ErrorService.instance.reportError(
              AppError(
                type: ErrorType.network,
                message: 'Tasks sync failed',
                context: 'circleId: $circleId, error: $error',
              ),
            );
          },
        );
  }

  void syncUserProfile(String userId, Function(Map<String, dynamic>) onUpdate) {
    final subscriptionKey = 'user_$userId';
    
    _subscriptions[subscriptionKey]?.cancel();
    
    _subscriptions[subscriptionKey] = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              final data = snapshot.data()!;
              data['id'] = snapshot.id;
              onUpdate(data);
              
              // Update cache
              CacheService.instance.cacheUserProfile(userId, data);
              
              _lastSyncTimes[subscriptionKey] = DateTime.now();
            }
          },
          onError: (error) {
            ErrorService.instance.reportError(
              AppError(
                type: ErrorType.network,
                message: 'User profile sync failed',
                context: 'userId: $userId, error: $error',
              ),
            );
          },
        );
  }

  // Offline operation queueing
  void queueOperation(SyncOperation operation) {
    final queueKey = operation.collection;
    _syncQueues[queueKey] ??= [];
    _syncQueues[queueKey]!.add(operation);
    
    // Start processing timer if not already running
    if (!_syncTimers.containsKey(queueKey)) {
      _syncTimers[queueKey] = Timer(const Duration(seconds: 5), () {
        _processSyncQueue(queueKey);
      });
    }
    
    // Process immediately if online
    if (_isOnline) {
      _syncTimers[queueKey]?.cancel();
      _processSyncQueue(queueKey);
    }
  }

  Future<void> _processSyncQueue(String queueKey) async {
    final operations = _syncQueues[queueKey];
    if (operations == null || operations.isEmpty) return;
    
    _syncQueues[queueKey] = [];
    _syncTimers.remove(queueKey);
    
    for (final operation in operations) {
      try {
        await _executeOperation(operation);
        
        AnalyticsService.instance.logCustomEvent('sync_operation_success', {
          'type': operation.type.toString(),
          'collection': operation.collection,
        });
      } catch (e) {
        // Re-queue failed operations with retry limit
        if (operation.retryCount < maxRetryAttempts) {
          operation.retryCount++;
          queueOperation(operation);
        } else {
          ErrorService.instance.reportError(
            AppError(
              type: ErrorType.network,
              message: 'Sync operation failed after max retries',
              context: 'operation: ${operation.type}, collection: ${operation.collection}',
            ),
          );
        }
      }
    }
  }

  Future<void> _executeOperation(SyncOperation operation) async {
    final docRef = _firestore.doc(operation.documentPath);
    
    switch (operation.type) {
      case SyncOperationType.create:
        await docRef.set(operation.data!);
        break;
      case SyncOperationType.update:
        await docRef.update(operation.data!);
        break;
      case SyncOperationType.delete:
        await docRef.delete();
        break;
    }
  }

  // Connection monitoring
  void _startConnectionMonitoring() {
    // Monitor Firestore connection state
    _firestore.enableNetwork().then((_) {
      _updateConnectionState(true);
    }).catchError((_) {
      _updateConnectionState(false);
    });
    
    // Periodic connection check
    Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkConnection();
    });
  }

  Future<void> _checkConnection() async {
    try {
      // Try a simple read operation
      await _firestore.collection('_connection_test').limit(1).get();
      _updateConnectionState(true);
    } catch (e) {
      _updateConnectionState(false);
    }
  }

  void _updateConnectionState(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      _connectionController.add(isOnline);
      
      AnalyticsService.instance.logCustomEvent('connection_state_changed', {
        'is_online': isOnline,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      if (isOnline) {
        _processAllQueues();
      }
    }
  }

  void _processAllQueues() {
    for (final queueKey in _syncQueues.keys) {
      _processSyncQueue(queueKey);
    }
  }

  // Periodic sync for data consistency
  void _startPeriodicSync() {
    Timer.periodic(syncInterval, (timer) {
      if (_isOnline) {
        _performPeriodicSync();
      }
    });
  }

  void _performPeriodicSync() {
    // Sync critical data that might have been missed
    final now = DateTime.now();
    
    for (final entry in _lastSyncTimes.entries) {
      final timeSinceLastSync = now.difference(entry.value);
      
      if (timeSinceLastSync > const Duration(minutes: 5)) {
        // Re-establish subscription if it's been too long
        final parts = entry.key.split('_');
        if (parts.length >= 2) {
          final type = parts[0];
          final id = parts.sublist(1).join('_');
          
          // This would trigger re-subscription based on type
          _reestablishSubscription(type, id);
        }
      }
    }
  }

  void _reestablishSubscription(String type, String id) {
    // This would be implemented based on the specific subscription type
    debugPrint('Re-establishing subscription: $type for $id');
  }

  void _processOfflineQueue() {
    Timer.periodic(offlineRetryInterval, (timer) {
      if (_isOnline && _syncQueues.isNotEmpty) {
        _processAllQueues();
      }
    });
  }

  // Subscription management
  void stopSync(String key) {
    _subscriptions[key]?.cancel();
    _subscriptions.remove(key);
    _lastSyncTimes.remove(key);
  }

  void stopAllSync() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _lastSyncTimes.clear();
  }

  // Force sync for specific data
  Future<void> forceSyncCircle(String circleId) async {
    try {
      final doc = await _firestore.collection('circles').doc(circleId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        await CacheService.instance.cacheCircleData(circleId, data);
      }
    } catch (e) {
      ErrorService.instance.reportError(
        AppError(
          type: ErrorType.network,
          message: 'Force sync failed',
          context: 'circleId: $circleId, error: $e',
        ),
      );
    }
  }

  // Sync statistics
  Map<String, dynamic> getSyncStatistics() {
    return {
      'active_subscriptions': _subscriptions.length,
      'queued_operations': _syncQueues.values.fold(0, (total, queue) => total + queue.length),
      'is_online': _isOnline,
      'last_sync_times': _lastSyncTimes.map((key, value) => 
        MapEntry(key, value.millisecondsSinceEpoch)),
    };
  }

  void dispose() {
    stopAllSync();
    
    for (final timer in _syncTimers.values) {
      timer.cancel();
    }
    _syncTimers.clear();
    _syncQueues.clear();
    
    _connectionController.close();
  }
}

// Sync operation model
class SyncOperation {
  final SyncOperationType type;
  final String collection;
  final String documentPath;
  final Map<String, dynamic>? data;
  int retryCount;
  final DateTime timestamp;

  SyncOperation({
    required this.type,
    required this.collection,
    required this.documentPath,
    this.data,
    this.retryCount = 0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

enum SyncOperationType {
  create,
  update,
  delete,
}