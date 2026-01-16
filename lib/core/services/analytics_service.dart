import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  static AnalyticsService get instance => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // User events
  Future<void> logSignUp(String method) async {
    if (kDebugMode) return;
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logLogin(String method) async {
    if (kDebugMode) return;
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logUserEngagement() async {
    if (kDebugMode) return;
    await _analytics.logEvent(name: 'user_engagement');
  }

  // Circle events
  Future<void> logCircleCreated() async {
    if (kDebugMode) return;
    await _analytics.logEvent(
      name: 'circle_created',
      parameters: {'timestamp': DateTime.now().millisecondsSinceEpoch},
    );
  }

  Future<void> logCircleJoined() async {
    if (kDebugMode) return;
    await _analytics.logEvent(
      name: 'circle_joined',
      parameters: {'timestamp': DateTime.now().millisecondsSinceEpoch},
    );
  }

  Future<void> logCircleLeft() async {
    if (kDebugMode) return;
    await _analytics.logEvent(
      name: 'circle_left',
      parameters: {'timestamp': DateTime.now().millisecondsSinceEpoch},
    );
  }

  // Content events
  Future<void> logPostCreated() async {
    if (kDebugMode) return;
    await _analytics.logEvent(
      name: 'post_created',
      parameters: {'content_type': 'post'},
    );
  }

  Future<void> logPostLiked() async {
    if (kDebugMode) return;
    await _analytics.logEvent(
      name: 'post_liked',
      parameters: {'engagement_type': 'like'},
    );
  }

  Future<void> logCommentCreated() async {
    if (kDebugMode) return;
    await _analytics.logEvent(
      name: 'comment_created',
      parameters: {'content_type': 'comment'},
    );
  }

  // Chat events
  Future<void> logMessageSent() async {
    if (kDebugMode) return;
    await _analytics.logEvent(
      name: 'message_sent',
      parameters: {'content_type': 'message'},
    );
  }

  // Task events
  Future<void> logTaskCreated() async {
    if (kDebugMode) return;
    await _analytics.logEvent(
      name: 'task_created',
      parameters: {'content_type': 'task'},
    );
  }

  Future<void> logTaskCompleted() async {
    if (kDebugMode) return;
    await _analytics.logEvent(
      name: 'task_completed',
      parameters: {'action': 'complete'},
    );
  }

  // File events
  Future<void> logFileUploaded(String fileType) async {
    if (kDebugMode) return;
    await _analytics.logEvent(
      name: 'file_uploaded',
      parameters: {
        'content_type': 'file',
        'file_type': fileType,
      },
    );
  }

  Future<void> logFileDownloaded(String fileType) async {
    if (kDebugMode) return;
    await _analytics.logEvent(
      name: 'file_downloaded',
      parameters: {
        'action': 'download',
        'file_type': fileType,
      },
    );
  }

  // Profile events
  Future<void> logProfileUpdated() async {
    if (kDebugMode) return;
    await _analytics.logEvent(
      name: 'profile_updated',
      parameters: {'action': 'update'},
    );
  }

  Future<void> logSettingsChanged(String settingType) async {
    if (kDebugMode) return;
    await _analytics.logEvent(
      name: 'settings_changed',
      parameters: {
        'setting_type': settingType,
        'action': 'change',
      },
    );
  }

  // Performance events
  Future<void> logPerformanceMetric(String metricName, int value) async {
    if (kDebugMode) return;
    await _analytics.logEvent(
      name: 'performance_metric',
      parameters: {
        'metric_name': metricName,
        'value': value,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Error events
  Future<void> logError(String errorType, String errorMessage) async {
    if (kDebugMode) return;
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Screen tracking
  Future<void> logScreenView(String screenName) async {
    if (kDebugMode) return;
    await _analytics.logScreenView(screenName: screenName);
  }

  // Custom events
  Future<void> logCustomEvent(String eventName, Map<String, dynamic>? parameters) async {
    if (kDebugMode) return;
    
    // Convert dynamic values to Object for Firebase Analytics
    Map<String, Object>? convertedParams;
    if (parameters != null) {
      convertedParams = parameters.map((key, value) => MapEntry(key, value as Object));
    }
    
    await _analytics.logEvent(
      name: eventName,
      parameters: convertedParams,
    );
  }

  // Set user properties
  Future<void> setUserId(String userId) async {
    if (kDebugMode) return;
    await _analytics.setUserId(id: userId);
  }

  Future<void> setUserProperty(String name, String value) async {
    if (kDebugMode) return;
    await _analytics.setUserProperty(name: name, value: value);
  }

  // App lifecycle events
  Future<void> logAppOpen() async {
    if (kDebugMode) return;
    await _analytics.logAppOpen();
  }

  Future<void> logAppBackground() async {
    if (kDebugMode) return;
    await _analytics.logEvent(name: 'app_background');
  }

  Future<void> logAppForeground() async {
    if (kDebugMode) return;
    await _analytics.logEvent(name: 'app_foreground');
  }
}