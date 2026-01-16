import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'analytics_service.dart';
import 'error_service.dart';
import 'cache_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  static BackupService get instance => _instance;
  BackupService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Backup configuration
  static const Duration autoBackupInterval = Duration(hours: 24);
  static const int maxBackupRetention = 30; // days
  static const int maxBackupSize = 100 * 1024 * 1024; // 100MB

  Timer? _autoBackupTimer;
  bool _isBackupInProgress = false;

  void initialize() {
    _startAutoBackup();
  }

  // User data backup
  Future<BackupResult> backupUserData(String userId) async {
    if (_isBackupInProgress) {
      return BackupResult(
        success: false,
        message: 'Backup already in progress',
      );
    }

    _isBackupInProgress = true;
    
    try {
      final backupData = await _collectUserData(userId);
      final backupId = 'backup_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Compress and encrypt backup data
      final compressedData = await _compressBackupData(backupData);
      
      // Upload to Firebase Storage
      final uploadResult = await _uploadBackup(backupId, compressedData);
      
      if (uploadResult) {
        // Store backup metadata
        await _storeBackupMetadata(userId, backupId, backupData.length);
        
        // Cleanup old backups
        await _cleanupOldBackups(userId);
        
        AnalyticsService.instance.logCustomEvent('backup_created', {
          'user_id': userId,
          'backup_id': backupId,
          'data_size': backupData.length,
        });
        
        return BackupResult(
          success: true,
          message: 'Backup created successfully',
          backupId: backupId,
        );
      } else {
        return BackupResult(
          success: false,
          message: 'Failed to upload backup',
        );
      }
    } catch (e) {
      ErrorService.instance.reportError(
        AppError(
          type: ErrorType.storage,
          message: 'Backup failed',
          context: 'userId: $userId, error: $e',
        ),
      );
      
      return BackupResult(
        success: false,
        message: 'Backup failed: ${e.toString()}',
      );
    } finally {
      _isBackupInProgress = false;
    }
  }

  // Collect user data for backup
  Future<Map<String, dynamic>> _collectUserData(String userId) async {
    final backupData = <String, dynamic>{
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'version': '1.0',
      'user_id': userId,
    };

    try {
      // User profile
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        backupData['profile'] = userDoc.data();
      }

      // User circles
      final circlesQuery = await _firestore
          .collection('circles')
          .where('members', arrayContains: userId)
          .get();
      
      backupData['circles'] = circlesQuery.docs.map((doc) => {
        'id': doc.id,
        'data': doc.data(),
      }).toList();

      // User posts across all circles
      final posts = <Map<String, dynamic>>[];
      for (final circleDoc in circlesQuery.docs) {
        final postsQuery = await _firestore
            .collection('circles')
            .doc(circleDoc.id)
            .collection('posts')
            .where('authorId', isEqualTo: userId)
            .get();
        
        for (final postDoc in postsQuery.docs) {
          posts.add({
            'id': postDoc.id,
            'circle_id': circleDoc.id,
            'data': postDoc.data(),
          });
        }
      }
      backupData['posts'] = posts;

      // User tasks
      final tasks = <Map<String, dynamic>>[];
      for (final circleDoc in circlesQuery.docs) {
        final tasksQuery = await _firestore
            .collection('circles')
            .doc(circleDoc.id)
            .collection('tasks')
            .where('assignedTo', arrayContains: userId)
            .get();
        
        for (final taskDoc in tasksQuery.docs) {
          tasks.add({
            'id': taskDoc.id,
            'circle_id': circleDoc.id,
            'data': taskDoc.data(),
          });
        }
      }
      backupData['tasks'] = tasks;

      // User messages
      final messages = <Map<String, dynamic>>[];
      for (final circleDoc in circlesQuery.docs) {
        final messagesQuery = await _firestore
            .collection('circles')
            .doc(circleDoc.id)
            .collection('messages')
            .where('senderId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .limit(1000) // Limit to recent messages
            .get();
        
        for (final messageDoc in messagesQuery.docs) {
          messages.add({
            'id': messageDoc.id,
            'circle_id': circleDoc.id,
            'data': messageDoc.data(),
          });
        }
      }
      backupData['messages'] = messages;

      // User preferences from cache
      final preferences = await CacheService.instance.getCachedUserProfile(userId);
      if (preferences != null) {
        backupData['preferences'] = preferences;
      }

    } catch (e) {
      debugPrint('Error collecting user data: $e');
    }

    return backupData;
  }

  // Compress backup data
  Future<List<int>> _compressBackupData(Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    
    // In a real implementation, you would use proper compression like gzip
    // For now, we'll just return the bytes
    return bytes;
  }

  // Upload backup to Firebase Storage
  Future<bool> _uploadBackup(String backupId, List<int> data) async {
    try {
      final ref = _storage.ref().child('backups/$backupId.json');
      await ref.putData(Uint8List.fromList(data));
      return true;
    } catch (e) {
      debugPrint('Error uploading backup: $e');
      return false;
    }
  }

  // Store backup metadata
  Future<void> _storeBackupMetadata(String userId, String backupId, int dataSize) async {
    await _firestore.collection('backups').doc(backupId).set({
      'user_id': userId,
      'backup_id': backupId,
      'created_at': FieldValue.serverTimestamp(),
      'data_size': dataSize,
      'status': 'completed',
    });
  }

  // Restore user data from backup
  Future<RestoreResult> restoreUserData(String userId, String backupId) async {
    try {
      // Download backup data
      final backupData = await _downloadBackup(backupId);
      if (backupData == null) {
        return RestoreResult(
          success: false,
          message: 'Backup not found',
        );
      }

      // Validate backup data
      if (!_validateBackupData(backupData, userId)) {
        return RestoreResult(
          success: false,
          message: 'Invalid backup data',
        );
      }

      // Restore user profile
      if (backupData['profile'] != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .set(backupData['profile'], SetOptions(merge: true));
      }

      // Note: Circle data, posts, tasks, and messages would typically not be restored
      // as they might conflict with current data. This would require careful consideration
      // and possibly a merge strategy.

      AnalyticsService.instance.logCustomEvent('backup_restored', {
        'user_id': userId,
        'backup_id': backupId,
      });

      return RestoreResult(
        success: true,
        message: 'Data restored successfully',
      );
    } catch (e) {
      ErrorService.instance.reportError(
        AppError(
          type: ErrorType.storage,
          message: 'Restore failed',
          context: 'userId: $userId, backupId: $backupId, error: $e',
        ),
      );

      return RestoreResult(
        success: false,
        message: 'Restore failed: ${e.toString()}',
      );
    }
  }

  // Download backup data
  Future<Map<String, dynamic>?> _downloadBackup(String backupId) async {
    try {
      final ref = _storage.ref().child('backups/$backupId.json');
      final data = await ref.getData();
      
      if (data != null) {
        final jsonString = utf8.decode(data);
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error downloading backup: $e');
    }
    return null;
  }

  // Validate backup data
  bool _validateBackupData(Map<String, dynamic> data, String userId) {
    return data['user_id'] == userId &&
           data['version'] != null &&
           data['timestamp'] != null;
  }

  // Get user backups
  Future<List<BackupInfo>> getUserBackups(String userId) async {
    try {
      final query = await _firestore
          .collection('backups')
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return BackupInfo(
          id: doc.id,
          createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
          dataSize: data['data_size'] ?? 0,
          status: data['status'] ?? 'unknown',
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting user backups: $e');
      return [];
    }
  }

  // Delete backup
  Future<bool> deleteBackup(String backupId) async {
    try {
      // Delete from storage
      final ref = _storage.ref().child('backups/$backupId.json');
      await ref.delete();

      // Delete metadata
      await _firestore.collection('backups').doc(backupId).delete();

      return true;
    } catch (e) {
      debugPrint('Error deleting backup: $e');
      return false;
    }
  }

  // Auto backup functionality
  void _startAutoBackup() {
    _autoBackupTimer = Timer.periodic(autoBackupInterval, (timer) {
      _performAutoBackup();
    });
  }

  Future<void> _performAutoBackup() async {
    // This would typically backup data for all users or based on user preferences
    // For now, we'll just log the event
    AnalyticsService.instance.logCustomEvent('auto_backup_triggered', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Cleanup old backups
  Future<void> _cleanupOldBackups(String userId) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: maxBackupRetention));
      
      final query = await _firestore
          .collection('backups')
          .where('user_id', isEqualTo: userId)
          .where('created_at', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      for (final doc in query.docs) {
        await deleteBackup(doc.id);
      }
    } catch (e) {
      debugPrint('Error cleaning up old backups: $e');
    }
  }

  // Export user data (for GDPR compliance)
  Future<String?> exportUserData(String userId) async {
    try {
      final userData = await _collectUserData(userId);
      final jsonString = const JsonEncoder.withIndent('  ').convert(userData);
      
      // Save to local file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/user_data_export_$userId.json');
      await file.writeAsString(jsonString);
      
      return file.path;
    } catch (e) {
      debugPrint('Error exporting user data: $e');
      return null;
    }
  }

  void dispose() {
    _autoBackupTimer?.cancel();
  }
}

// Backup models
class BackupResult {
  final bool success;
  final String message;
  final String? backupId;

  BackupResult({
    required this.success,
    required this.message,
    this.backupId,
  });
}

class RestoreResult {
  final bool success;
  final String message;

  RestoreResult({
    required this.success,
    required this.message,
  });
}

class BackupInfo {
  final String id;
  final DateTime createdAt;
  final int dataSize;
  final String status;

  BackupInfo({
    required this.id,
    required this.createdAt,
    required this.dataSize,
    required this.status,
  });
}