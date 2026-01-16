import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/services/auth_service.dart';
import 'notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final _uuid = const Uuid();

  // Initialize notifications
  Future<void> initialize() async {
    // Request permission
    await _requestPermission();
    
    // Get FCM token
    await _updateFCMToken();
    
    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_updateFCMToken);
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
    
    // Handle app launch from notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }

  // Request notification permission
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('Notification permission: ${settings.authorizationStatus}');
  }

  // Update FCM token in user document
  Future<void> _updateFCMToken([String? token]) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    try {
      token ??= await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM token updated: $token');
      }
    } catch (e) {
      debugPrint('Failed to update FCM token: $e');
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    // You can show in-app notification here
  }

  // Handle message tap (when user taps notification)
  void _handleMessageTap(RemoteMessage message) {
    debugPrint('Message tapped: ${message.data}');
    // Navigate to relevant screen based on message data
  }

  // Create notification
  Future<void> createNotification({
    required String userId,
    required String circleId,
    required String circleName,
    required NotificationType type,
    required String title,
    required String body,
    String? actionUserId,
    String? actionUserName,
    String? actionUserPhotoUrl,
    String? relatedId,
    Map<String, dynamic>? data,
  }) async {
    // Don't notify the user about their own actions
    if (actionUserId == userId) return;

    final notification = AppNotification(
      id: _uuid.v4(),
      userId: userId,
      circleId: circleId,
      circleName: circleName,
      type: type,
      title: title,
      body: body,
      actionUserId: actionUserId,
      actionUserName: actionUserName,
      actionUserPhotoUrl: actionUserPhotoUrl,
      relatedId: relatedId,
      data: data,
      createdAt: DateTime.now(),
    );

    // Save to Firestore
    await _firestore
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toFirestore());

    // Send push notification if user preferences allow
    await _sendPushNotification(notification);
  }

  // Send push notification
  Future<void> _sendPushNotification(AppNotification notification) async {
    try {
      // Get user preferences
      final prefs = await getNotificationPreferences(notification.userId);
      if (!prefs.shouldNotify(notification.type)) return;

      // Check quiet hours
      if (prefs.quietHoursEnabled && _isQuietHours(prefs)) return;

      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(notification.userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      
      if (fcmToken == null) return;

      // This would typically be handled by Cloud Functions
      // For now, we'll just mark as push sent
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .update({'isPushSent': true});

      debugPrint('Push notification would be sent to: $fcmToken');
    } catch (e) {
      debugPrint('Failed to send push notification: $e');
    }
  }

  // Check if current time is within quiet hours
  bool _isQuietHours(NotificationPreferences prefs) {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    // Simple time comparison (doesn't handle cross-midnight ranges perfectly)
    return currentTime.compareTo(prefs.quietHoursStart) >= 0 || 
           currentTime.compareTo(prefs.quietHoursEnd) <= 0;
  }

  // Get notifications for user
  Stream<List<AppNotification>> getUserNotifications(String userId, {int limit = 50}) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList());
  }

  // Get unread notification count
  Stream<int> getUnreadNotificationCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    
    final unreadNotifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in unreadNotifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  // Get notification preferences
  Future<NotificationPreferences> getNotificationPreferences(String userId) async {
    final doc = await _firestore.collection('notificationPreferences').doc(userId).get();
    return NotificationPreferences.fromFirestore(doc);
  }

  // Update notification preferences
  Future<void> updateNotificationPreferences(NotificationPreferences preferences) async {
    await _firestore
        .collection('notificationPreferences')
        .doc(preferences.userId)
        .set(preferences.toFirestore(), SetOptions(merge: true));
  }

  // Notification helpers for different events
  Future<void> notifyNewMessage({
    required String circleId,
    required String circleName,
    required List<String> memberIds,
    required String senderName,
    required String messagePreview,
  }) async {
    final sender = AuthService.instance.currentUser;
    if (sender == null) return;

    for (final memberId in memberIds) {
      if (memberId != sender.uid) {
        await createNotification(
          userId: memberId,
          circleId: circleId,
          circleName: circleName,
          type: NotificationType.newMessage,
          title: circleName,
          body: '$senderName: $messagePreview',
          actionUserId: sender.uid,
          actionUserName: senderName,
        );
      }
    }
  }

  Future<void> notifyNewPost({
    required String circleId,
    required String circleName,
    required List<String> memberIds,
    required String authorName,
    required String postPreview,
    required String postId,
  }) async {
    final author = AuthService.instance.currentUser;
    if (author == null) return;

    for (final memberId in memberIds) {
      if (memberId != author.uid) {
        await createNotification(
          userId: memberId,
          circleId: circleId,
          circleName: circleName,
          type: NotificationType.newPost,
          title: 'New post in $circleName',
          body: '$authorName shared: $postPreview',
          actionUserId: author.uid,
          actionUserName: authorName,
          relatedId: postId,
        );
      }
    }
  }

  Future<void> notifyTaskAssigned({
    required String assigneeId,
    required String circleId,
    required String circleName,
    required String taskTitle,
    required String assignerName,
    required String taskId,
  }) async {
    final assigner = AuthService.instance.currentUser;
    if (assigner == null) return;

    await createNotification(
      userId: assigneeId,
      circleId: circleId,
      circleName: circleName,
      type: NotificationType.taskAssigned,
      title: 'Task assigned',
      body: '$assignerName assigned you: $taskTitle',
      actionUserId: assigner.uid,
      actionUserName: assignerName,
      relatedId: taskId,
    );
  }

  Future<void> notifyFileUploaded({
    required String circleId,
    required String circleName,
    required List<String> memberIds,
    required String uploaderName,
    required String fileName,
    required String fileId,
  }) async {
    final uploader = AuthService.instance.currentUser;
    if (uploader == null) return;

    for (final memberId in memberIds) {
      if (memberId != uploader.uid) {
        await createNotification(
          userId: memberId,
          circleId: circleId,
          circleName: circleName,
          type: NotificationType.fileUploaded,
          title: 'File uploaded',
          body: '$uploaderName uploaded $fileName',
          actionUserId: uploader.uid,
          actionUserName: uploaderName,
          relatedId: fileId,
        );
      }
    }
  }
}