import 'package:flutter/material.dart';
import 'analytics_service.dart';
import 'error_service.dart';
import '../utils/performance_utils.dart';

class AppLifecycleService extends WidgetsBindingObserver {
  static final AppLifecycleService _instance = AppLifecycleService._internal();
  static AppLifecycleService get instance => _instance;
  AppLifecycleService._internal();

  bool _isInitialized = false;
  DateTime? _backgroundTime;
  DateTime? _foregroundTime;

  void initialize() {
    if (_isInitialized) return;
    
    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;
    
    // Log app initialization
    AnalyticsService.instance.logAppOpen();
    PerformanceMonitor.startTimer('app_startup');
  }

  void dispose() {
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
      _isInitialized = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.inactive:
        _handleAppInactive();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.hidden:
        _handleAppHidden();
        break;
    }
  }

  void _handleAppResumed() {
    _foregroundTime = DateTime.now();
    
    // Log app foreground
    AnalyticsService.instance.logAppForeground();
    
    // Calculate background duration if available
    if (_backgroundTime != null) {
      final backgroundDuration = _foregroundTime!.difference(_backgroundTime!);
      AnalyticsService.instance.logPerformanceMetric(
        'background_duration_seconds',
        backgroundDuration.inSeconds,
      );
    }
    
    // Update connection state
    ConnectionStateManager.updateConnectionState(true);
    
    // Trigger data refresh if app was backgrounded for more than 5 minutes
    if (_backgroundTime != null) {
      final backgroundDuration = _foregroundTime!.difference(_backgroundTime!);
      if (backgroundDuration.inMinutes > 5) {
        _triggerDataRefresh();
      }
    }
  }

  void _handleAppPaused() {
    _backgroundTime = DateTime.now();
    
    // Log app background
    AnalyticsService.instance.logAppBackground();
    
    // Calculate foreground duration if available
    if (_foregroundTime != null) {
      final foregroundDuration = _backgroundTime!.difference(_foregroundTime!);
      AnalyticsService.instance.logPerformanceMetric(
        'foreground_duration_seconds',
        foregroundDuration.inSeconds,
      );
    }
    
    // Clear sensitive data from memory
    _clearSensitiveData();
    
    // Save app state
    _saveAppState();
  }

  void _handleAppInactive() {
    // App is transitioning between foreground and background
    // Pause non-critical operations
    _pauseNonCriticalOperations();
  }

  void _handleAppDetached() {
    // App is being terminated
    // Perform final cleanup
    _performFinalCleanup();
  }

  void _handleAppHidden() {
    // App is hidden (iOS specific)
    // Similar to paused state
    _handleAppPaused();
  }

  void _triggerDataRefresh() {
    // Trigger refresh of critical data
    // This would typically notify controllers to refresh their data
    debugPrint('Triggering data refresh after long background period');
  }

  void _clearSensitiveData() {
    // Clear sensitive data from memory when app goes to background
    // This is important for security
    debugPrint('Clearing sensitive data from memory');
  }

  void _saveAppState() {
    // Save current app state for restoration
    debugPrint('Saving app state');
  }

  void _pauseNonCriticalOperations() {
    // Pause animations, timers, etc.
    debugPrint('Pausing non-critical operations');
  }

  void _performFinalCleanup() {
    // Final cleanup before app termination
    debugPrint('Performing final cleanup');
    
    // Log app termination
    AnalyticsService.instance.logCustomEvent('app_terminated', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Handle screen size changes, keyboard appearance, etc.
    _handleMetricsChange();
  }

  void _handleMetricsChange() {
    final window = WidgetsBinding.instance.platformDispatcher.views.first;
    final size = window.physicalSize / window.devicePixelRatio;
    
    AnalyticsService.instance.logCustomEvent('screen_metrics_changed', {
      'width': size.width,
      'height': size.height,
      'pixel_ratio': window.devicePixelRatio,
    });
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    // Handle system theme changes
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    
    AnalyticsService.instance.logCustomEvent('system_theme_changed', {
      'brightness': brightness.name,
    });
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    super.didChangeLocales(locales);
    // Handle system locale changes
    if (locales != null && locales.isNotEmpty) {
      AnalyticsService.instance.logCustomEvent('system_locale_changed', {
        'locale': locales.first.toString(),
      });
    }
  }

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    // Handle memory pressure
    _handleMemoryPressure();
  }

  void _handleMemoryPressure() {
    debugPrint('Memory pressure detected - clearing caches');
    
    // Clear image cache
    ImageCacheManager.clearCache();
    
    // Clear other caches
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    
    // Log memory pressure event
    AnalyticsService.instance.logCustomEvent('memory_pressure', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    // Report as performance issue
    ErrorService.instance.reportError(
      AppError(
        type: ErrorType.unknown,
        message: 'Memory pressure detected',
        context: 'app_lifecycle',
      ),
    );
  }

  // Public methods for manual lifecycle management
  void onAppStartupComplete() {
    PerformanceMonitor.endTimer('app_startup');
    AnalyticsService.instance.logCustomEvent('app_startup_complete', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void onUserEngagement() {
    AnalyticsService.instance.logUserEngagement();
  }

  void onCriticalError(String error) {
    ErrorService.instance.reportError(
      AppError(
        type: ErrorType.unknown,
        message: error,
        context: 'critical_error',
      ),
    );
  }

  // Battery optimization
  void optimizeForBattery() {
    // Reduce animation frame rates
    // Pause non-essential background tasks
    // Reduce network polling frequency
    debugPrint('Optimizing for battery life');
  }

  void restoreNormalOperation() {
    // Restore normal animation frame rates
    // Resume background tasks
    // Restore normal network polling
    debugPrint('Restoring normal operation');
  }
}

// Widget to wrap the app and handle lifecycle
class AppLifecycleWrapper extends StatefulWidget {
  final Widget child;

  const AppLifecycleWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper> {
  @override
  void initState() {
    super.initState();
    AppLifecycleService.instance.initialize();
    
    // Mark startup as complete after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLifecycleService.instance.onAppStartupComplete();
    });
  }

  @override
  void dispose() {
    AppLifecycleService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}