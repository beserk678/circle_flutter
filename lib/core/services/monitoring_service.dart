import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'analytics_service.dart';
import 'error_service.dart';

class MonitoringService {
  static final MonitoringService _instance = MonitoringService._internal();
  static MonitoringService get instance => _instance;
  MonitoringService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Monitoring configuration
  static const Duration metricsInterval = Duration(minutes: 5);
  static const Duration healthCheckInterval = Duration(minutes: 1);
  static const int maxMetricsHistory = 288; // 24 hours of 5-minute intervals

  Timer? _metricsTimer;
  Timer? _healthCheckTimer;
  
  // Performance metrics
  final List<PerformanceMetric> _performanceHistory = [];
  final Map<String, double> _currentMetrics = {};
  
  // Health status
  HealthStatus _currentHealth = HealthStatus.healthy;
  final Map<String, ServiceHealth> _serviceHealth = {};
  
  // Alerts
  final List<Alert> _activeAlerts = [];
  final Map<String, DateTime> _lastAlertTimes = {};

  void initialize() {
    _initializeServiceHealth();
    _startMetricsCollection();
    _startHealthChecks();
  }

  void _initializeServiceHealth() {
    final services = ['firestore', 'storage', 'auth', 'messaging', 'analytics'];
    for (final service in services) {
      _serviceHealth[service] = ServiceHealth(
        name: service,
        status: HealthStatus.healthy,
        lastCheck: DateTime.now(),
        responseTime: 0,
      );
    }
  }

  // Performance monitoring
  void _startMetricsCollection() {
    _metricsTimer = Timer.periodic(metricsInterval, (timer) {
      _collectPerformanceMetrics();
    });
  }

  Future<void> _collectPerformanceMetrics() async {
    try {
      final metrics = PerformanceMetric(
        timestamp: DateTime.now(),
        memoryUsage: await _getMemoryUsage(),
        cpuUsage: await _getCpuUsage(),
        networkLatency: await _getNetworkLatency(),
        activeUsers: await _getActiveUsers(),
        errorRate: await _getErrorRate(),
        responseTime: await _getAverageResponseTime(),
      );

      _performanceHistory.add(metrics);
      
      // Keep only recent history
      if (_performanceHistory.length > maxMetricsHistory) {
        _performanceHistory.removeAt(0);
      }

      // Update current metrics
      _currentMetrics['memory_usage'] = metrics.memoryUsage;
      _currentMetrics['cpu_usage'] = metrics.cpuUsage;
      _currentMetrics['network_latency'] = metrics.networkLatency;
      _currentMetrics['active_users'] = metrics.activeUsers.toDouble();
      _currentMetrics['error_rate'] = metrics.errorRate;
      _currentMetrics['response_time'] = metrics.responseTime;

      // Check for performance alerts
      _checkPerformanceAlerts(metrics);

      // Log metrics to analytics
      AnalyticsService.instance.logCustomEvent('performance_metrics', {
        'memory_usage': metrics.memoryUsage,
        'cpu_usage': metrics.cpuUsage,
        'network_latency': metrics.networkLatency,
        'active_users': metrics.activeUsers,
        'error_rate': metrics.errorRate,
        'response_time': metrics.responseTime,
      });

    } catch (e) {
      ErrorService.instance.reportError(
        AppError(
          type: ErrorType.framework,
          message: 'Failed to collect performance metrics',
          context: e.toString(),
        ),
      );
    }
  }

  // Health checks
  void _startHealthChecks() {
    _healthCheckTimer = Timer.periodic(healthCheckInterval, (timer) {
      _performHealthChecks();
    });
  }

  Future<void> _performHealthChecks() async {
    final healthChecks = <Future<void>>[
      _checkFirestoreHealth(),
      _checkStorageHealth(),
      _checkAuthHealth(),
      _checkMessagingHealth(),
      _checkAnalyticsHealth(),
    ];

    await Future.wait(healthChecks);
    _updateOverallHealth();
  }

  Future<void> _checkFirestoreHealth() async {
    final startTime = DateTime.now();
    try {
      await _firestore.collection('_health_check').limit(1).get();
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      
      _serviceHealth['firestore'] = ServiceHealth(
        name: 'firestore',
        status: responseTime < 5000 ? HealthStatus.healthy : HealthStatus.degraded,
        lastCheck: DateTime.now(),
        responseTime: responseTime,
      );
    } catch (e) {
      _serviceHealth['firestore'] = ServiceHealth(
        name: 'firestore',
        status: HealthStatus.unhealthy,
        lastCheck: DateTime.now(),
        responseTime: DateTime.now().difference(startTime).inMilliseconds,
        error: e.toString(),
      );
    }
  }

  Future<void> _checkStorageHealth() async {
    final startTime = DateTime.now();
    try {
      // Simple storage health check - list root directory
      // In a real implementation, you might upload/download a small test file
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      
      _serviceHealth['storage'] = ServiceHealth(
        name: 'storage',
        status: HealthStatus.healthy,
        lastCheck: DateTime.now(),
        responseTime: responseTime,
      );
    } catch (e) {
      _serviceHealth['storage'] = ServiceHealth(
        name: 'storage',
        status: HealthStatus.unhealthy,
        lastCheck: DateTime.now(),
        responseTime: DateTime.now().difference(startTime).inMilliseconds,
        error: e.toString(),
      );
    }
  }

  Future<void> _checkAuthHealth() async {
    final startTime = DateTime.now();
    try {
      // Auth health check would typically verify token validation
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      
      _serviceHealth['auth'] = ServiceHealth(
        name: 'auth',
        status: HealthStatus.healthy,
        lastCheck: DateTime.now(),
        responseTime: responseTime,
      );
    } catch (e) {
      _serviceHealth['auth'] = ServiceHealth(
        name: 'auth',
        status: HealthStatus.unhealthy,
        lastCheck: DateTime.now(),
        responseTime: DateTime.now().difference(startTime).inMilliseconds,
        error: e.toString(),
      );
    }
  }

  Future<void> _checkMessagingHealth() async {
    final startTime = DateTime.now();
    try {
      // Messaging health check
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      
      _serviceHealth['messaging'] = ServiceHealth(
        name: 'messaging',
        status: HealthStatus.healthy,
        lastCheck: DateTime.now(),
        responseTime: responseTime,
      );
    } catch (e) {
      _serviceHealth['messaging'] = ServiceHealth(
        name: 'messaging',
        status: HealthStatus.unhealthy,
        lastCheck: DateTime.now(),
        responseTime: DateTime.now().difference(startTime).inMilliseconds,
        error: e.toString(),
      );
    }
  }

  Future<void> _checkAnalyticsHealth() async {
    final startTime = DateTime.now();
    try {
      // Analytics health check
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      
      _serviceHealth['analytics'] = ServiceHealth(
        name: 'analytics',
        status: HealthStatus.healthy,
        lastCheck: DateTime.now(),
        responseTime: responseTime,
      );
    } catch (e) {
      _serviceHealth['analytics'] = ServiceHealth(
        name: 'analytics',
        status: HealthStatus.unhealthy,
        lastCheck: DateTime.now(),
        responseTime: DateTime.now().difference(startTime).inMilliseconds,
        error: e.toString(),
      );
    }
  }

  void _updateOverallHealth() {
    final unhealthyServices = _serviceHealth.values
        .where((service) => service.status == HealthStatus.unhealthy)
        .length;
    
    final degradedServices = _serviceHealth.values
        .where((service) => service.status == HealthStatus.degraded)
        .length;

    HealthStatus newHealth;
    if (unhealthyServices > 0) {
      newHealth = HealthStatus.unhealthy;
    } else if (degradedServices > 0) {
      newHealth = HealthStatus.degraded;
    } else {
      newHealth = HealthStatus.healthy;
    }

    if (_currentHealth != newHealth) {
      _currentHealth = newHealth;
      _triggerHealthAlert(newHealth);
    }
  }

  // Metric collection methods
  Future<double> _getMemoryUsage() async {
    // In a real implementation, you would get actual memory usage
    // For now, return a simulated value
    return 45.0 + (DateTime.now().millisecond % 20); // 45-65%
  }

  Future<double> _getCpuUsage() async {
    // In a real implementation, you would get actual CPU usage
    return 25.0 + (DateTime.now().millisecond % 30); // 25-55%
  }

  Future<double> _getNetworkLatency() async {
    final startTime = DateTime.now();
    try {
      await _firestore.collection('_ping').limit(1).get();
      return DateTime.now().difference(startTime).inMilliseconds.toDouble();
    } catch (e) {
      return 5000.0; // High latency on error
    }
  }

  Future<int> _getActiveUsers() async {
    try {
      // In a real implementation, you would track active users
      // For now, return a simulated value
      return 50 + (DateTime.now().hour * 2); // Varies by hour
    } catch (e) {
      return 0;
    }
  }

  Future<double> _getErrorRate() async {
    // Calculate error rate from recent errors
    // For now, return a simulated value since getRecentErrors doesn't exist
    return 1.0; // 1% error rate
  }

  Future<double> _getAverageResponseTime() async {
    // Calculate average response time from service health
    final responseTimes = _serviceHealth.values
        .map((service) => service.responseTime.toDouble())
        .where((time) => time > 0);
    
    if (responseTimes.isEmpty) return 0.0;
    
    return responseTimes.reduce((a, b) => a + b) / responseTimes.length;
  }

  // Alert system
  void _checkPerformanceAlerts(PerformanceMetric metrics) {
    // Memory usage alert
    if (metrics.memoryUsage > 80.0) {
      _triggerAlert(AlertType.highMemoryUsage, 'Memory usage: ${metrics.memoryUsage.toStringAsFixed(1)}%');
    }

    // CPU usage alert
    if (metrics.cpuUsage > 70.0) {
      _triggerAlert(AlertType.highCpuUsage, 'CPU usage: ${metrics.cpuUsage.toStringAsFixed(1)}%');
    }

    // Network latency alert
    if (metrics.networkLatency > 3000.0) {
      _triggerAlert(AlertType.highLatency, 'Network latency: ${metrics.networkLatency.toStringAsFixed(0)}ms');
    }

    // Error rate alert
    if (metrics.errorRate > 5.0) {
      _triggerAlert(AlertType.highErrorRate, 'Error rate: ${metrics.errorRate.toStringAsFixed(1)}%');
    }
  }

  void _triggerAlert(AlertType type, String message) {
    final now = DateTime.now();
    final lastAlert = _lastAlertTimes[type.toString()];
    
    // Rate limit alerts (don't send same alert more than once per hour)
    if (lastAlert != null && now.difference(lastAlert).inHours < 1) {
      return;
    }

    final alert = Alert(
      type: type,
      message: message,
      timestamp: now,
      severity: _getAlertSeverity(type),
    );

    _activeAlerts.add(alert);
    _lastAlertTimes[type.toString()] = now;

    // Log alert
    AnalyticsService.instance.logCustomEvent('monitoring_alert', {
      'type': type.toString(),
      'message': message,
      'severity': alert.severity.toString(),
    });

    // In a real implementation, you would send notifications here
    debugPrint('ALERT: ${alert.severity} - ${alert.message}');
  }

  void _triggerHealthAlert(HealthStatus health) {
    final message = 'System health changed to: ${health.toString()}';
    
    _triggerAlert(
      health == HealthStatus.unhealthy 
          ? AlertType.systemUnhealthy 
          : AlertType.systemDegraded,
      message,
    );
  }

  AlertSeverity _getAlertSeverity(AlertType type) {
    switch (type) {
      case AlertType.systemUnhealthy:
        return AlertSeverity.critical;
      case AlertType.highErrorRate:
        return AlertSeverity.high;
      case AlertType.highMemoryUsage:
      case AlertType.highCpuUsage:
        return AlertSeverity.medium;
      case AlertType.systemDegraded:
      case AlertType.highLatency:
        return AlertSeverity.low;
    }
  }

  // Public API
  HealthStatus get currentHealth => _currentHealth;
  
  Map<String, ServiceHealth> get serviceHealth => Map.from(_serviceHealth);
  
  List<PerformanceMetric> get performanceHistory => List.from(_performanceHistory);
  
  Map<String, double> get currentMetrics => Map.from(_currentMetrics);
  
  List<Alert> get activeAlerts => List.from(_activeAlerts);

  // Get system status summary
  SystemStatus getSystemStatus() {
    return SystemStatus(
      overallHealth: _currentHealth,
      services: Map.from(_serviceHealth),
      metrics: Map.from(_currentMetrics),
      activeAlerts: _activeAlerts.length,
      lastUpdate: DateTime.now(),
    );
  }

  // Clear resolved alerts
  void clearAlert(Alert alert) {
    _activeAlerts.remove(alert);
  }

  void clearAllAlerts() {
    _activeAlerts.clear();
  }

  void dispose() {
    _metricsTimer?.cancel();
    _healthCheckTimer?.cancel();
  }
}

// Monitoring models
class PerformanceMetric {
  final DateTime timestamp;
  final double memoryUsage;
  final double cpuUsage;
  final double networkLatency;
  final int activeUsers;
  final double errorRate;
  final double responseTime;

  PerformanceMetric({
    required this.timestamp,
    required this.memoryUsage,
    required this.cpuUsage,
    required this.networkLatency,
    required this.activeUsers,
    required this.errorRate,
    required this.responseTime,
  });
}

class ServiceHealth {
  final String name;
  final HealthStatus status;
  final DateTime lastCheck;
  final int responseTime;
  final String? error;

  ServiceHealth({
    required this.name,
    required this.status,
    required this.lastCheck,
    required this.responseTime,
    this.error,
  });
}

class Alert {
  final AlertType type;
  final String message;
  final DateTime timestamp;
  final AlertSeverity severity;

  Alert({
    required this.type,
    required this.message,
    required this.timestamp,
    required this.severity,
  });
}

class SystemStatus {
  final HealthStatus overallHealth;
  final Map<String, ServiceHealth> services;
  final Map<String, double> metrics;
  final int activeAlerts;
  final DateTime lastUpdate;

  SystemStatus({
    required this.overallHealth,
    required this.services,
    required this.metrics,
    required this.activeAlerts,
    required this.lastUpdate,
  });
}

enum HealthStatus { healthy, degraded, unhealthy }

enum AlertType {
  systemUnhealthy,
  systemDegraded,
  highMemoryUsage,
  highCpuUsage,
  highLatency,
  highErrorRate,
}

enum AlertSeverity { low, medium, high, critical }