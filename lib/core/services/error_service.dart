import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'analytics_service.dart';

class ErrorService {
  static final ErrorService _instance = ErrorService._internal();
  static ErrorService get instance => _instance;
  ErrorService._internal();

  final StreamController<AppError> _errorController =
      StreamController<AppError>.broadcast();
  Stream<AppError> get errorStream => _errorController.stream;

  // Initialize error handling
  void initialize() {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      reportError(
        AppError(
          type: ErrorType.framework,
          message: details.exception.toString(),
          stackTrace: details.stack.toString(),
          context: details.context?.toString(),
        ),
      );
    };

    // Catch async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      reportError(
        AppError(
          type: ErrorType.async,
          message: error.toString(),
          stackTrace: stack.toString(),
        ),
      );
      return true;
    };
  }

  // Report error
  void reportError(AppError error) {
    if (kDebugMode) {
      debugPrint('Error: ${error.message}');
      debugPrint('Stack: ${error.stackTrace}');
    }

    // Add to stream for UI handling
    _errorController.add(error);

    // Log to analytics
    AnalyticsService.instance.logError(error.type.toString(), error.message);

    // In production, you might want to send to crash reporting service
    // like Firebase Crashlytics, Sentry, etc.
  }

  // Report network error
  void reportNetworkError(String endpoint, String error) {
    reportError(
      AppError(
        type: ErrorType.network,
        message: 'Network error at $endpoint: $error',
        context: endpoint,
      ),
    );
  }

  // Report authentication error
  void reportAuthError(String error) {
    reportError(
      AppError(
        type: ErrorType.authentication,
        message: 'Authentication error: $error',
      ),
    );
  }

  // Report validation error
  void reportValidationError(String field, String error) {
    reportError(
      AppError(
        type: ErrorType.validation,
        message: 'Validation error in $field: $error',
        context: field,
      ),
    );
  }

  // Report permission error
  void reportPermissionError(String permission, String error) {
    reportError(
      AppError(
        type: ErrorType.permission,
        message: 'Permission error for $permission: $error',
        context: permission,
      ),
    );
  }

  // Report storage error
  void reportStorageError(String operation, String error) {
    reportError(
      AppError(
        type: ErrorType.storage,
        message: 'Storage error during $operation: $error',
        context: operation,
      ),
    );
  }

  // Show error to user
  void showErrorToUser(BuildContext context, AppError error) {
    String userMessage = _getUserFriendlyMessage(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(userMessage),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Get user-friendly error message
  String _getUserFriendlyMessage(AppError error) {
    switch (error.type) {
      case ErrorType.network:
        return 'Network connection error. Please check your internet connection.';
      case ErrorType.authentication:
        return 'Authentication failed. Please sign in again.';
      case ErrorType.validation:
        return 'Please check your input and try again.';
      case ErrorType.permission:
        return 'Permission denied. Please check your app permissions.';
      case ErrorType.storage:
        return 'Storage error. Please try again.';
      case ErrorType.framework:
      case ErrorType.async:
      case ErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  // Clear errors
  void clearErrors() {
    // Implementation depends on your error storage mechanism
  }

  void dispose() {
    _errorController.close();
  }
}

// Error types
enum ErrorType {
  network,
  authentication,
  validation,
  permission,
  storage,
  framework,
  async,
  unknown,
}

// Error model
class AppError {
  final ErrorType type;
  final String message;
  final String? stackTrace;
  final String? context;
  final DateTime timestamp;

  AppError({
    required this.type,
    required this.message,
    this.stackTrace,
    this.context,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'AppError(type: $type, message: $message, context: $context, timestamp: $timestamp)';
  }
}

// Error boundary widget
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(AppError error)? errorBuilder;

  const ErrorBoundary({super.key, required this.child, this.errorBuilder});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  AppError? _error;

  @override
  void initState() {
    super.initState();

    // Listen to error stream
    ErrorService.instance.errorStream.listen((error) {
      if (mounted) {
        setState(() {
          _error = error;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!);
      }

      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Something went wrong',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'An unexpected error occurred. Please try again.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                    });
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}

// Global error handler mixin
mixin ErrorHandlerMixin<T extends StatefulWidget> on State<T> {
  void handleError(dynamic error, {String? context}) {
    ErrorService.instance.reportError(
      AppError(
        type: ErrorType.unknown,
        message: error.toString(),
        context: context ?? widget.runtimeType.toString(),
      ),
    );
  }

  void showError(String message) {
    if (mounted) {
      ErrorService.instance.showErrorToUser(
        context,
        AppError(type: ErrorType.unknown, message: message),
      );
    }
  }
}
