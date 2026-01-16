import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import 'notification_service.dart';
import 'notification_model.dart';

class NotificationController extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService.instance;
  
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  NotificationPreferences? _preferences;
  bool _isLoading = false;
  String? _errorMessage;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  NotificationPreferences? get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Initialize notifications for current user
  void initializeNotifications() {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    // Listen to notifications
    _notificationService.getUserNotifications(user.uid).listen(
      (notifications) {
        _notifications = notifications;
        notifyListeners();
      },
      onError: (error) {
        _setError('Failed to load notifications: $error');
      },
    );

    // Listen to unread count
    _notificationService.getUnreadNotificationCount(user.uid).listen(
      (count) {
        _unreadCount = count;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Failed to load unread count: $error');
      },
    );

    // Load preferences
    _loadPreferences();
  }

  // Load notification preferences
  Future<void> _loadPreferences() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    try {
      _preferences = await _notificationService.getNotificationPreferences(user.uid);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load notification preferences: $e');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
    } catch (e) {
      _setError('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    _setLoading(true);
    _setError(null);

    try {
      await _notificationService.markAllAsRead(user.uid);
      _setLoading(false);
    } catch (e) {
      _setError('Failed to mark all as read: $e');
      _setLoading(false);
    }
  }

  // Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      return true;
    } catch (e) {
      _setError('Failed to delete notification: $e');
      return false;
    }
  }

  // Update notification preferences
  Future<bool> updatePreferences(NotificationPreferences preferences) async {
    _setLoading(true);
    _setError(null);

    try {
      await _notificationService.updateNotificationPreferences(preferences);
      _preferences = preferences;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update preferences: $e');
      _setLoading(false);
      return false;
    }
  }

  // Get notifications by type
  List<AppNotification> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // Get unread notifications
  List<AppNotification> get unreadNotifications {
    return _notifications.where((n) => !n.isRead).toList();
  }

  // Get notifications from today
  List<AppNotification> get todayNotifications {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return _notifications.where((n) => n.createdAt.isAfter(startOfDay)).toList();
  }

  // Get notifications from this week
  List<AppNotification> get thisWeekNotifications {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return _notifications.where((n) => n.createdAt.isAfter(startOfWeekDay)).toList();
  }

  void clearError() {
    _setError(null);
  }
}