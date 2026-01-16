import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Error message banner
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;
  final IconData? icon;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon ?? Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: const Text('Retry'),
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
              color: Theme.of(context).colorScheme.error,
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ],
      ),
    );
  }
}

/// Success message banner
class SuccessBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final IconData? icon;

  const SuccessBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.successColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon ?? Icons.check_circle_outline,
            color: AppTheme.successColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.successColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
              color: AppTheme.successColor,
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ],
      ),
    );
  }
}

/// Warning message banner
class WarningBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionText;
  final IconData? icon;

  const WarningBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.onAction,
    this.actionText,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warningColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon ?? Icons.warning_outlined,
            color: AppTheme.warningColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.warningColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onAction != null && actionText != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.warningColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: Text(actionText!),
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
              color: AppTheme.warningColor,
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ],
      ),
    );
  }
}

/// Info message banner
class InfoBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionText;
  final IconData? icon;

  const InfoBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.onAction,
    this.actionText,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.infoColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.infoColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon ?? Icons.info_outline,
            color: AppTheme.infoColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.infoColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onAction != null && actionText != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.infoColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: Text(actionText!),
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
              color: AppTheme.infoColor,
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ],
      ),
    );
  }
}

/// Inline error text
class InlineError extends StatelessWidget {
  final String message;
  final IconData? icon;

  const InlineError({
    super.key,
    required this.message,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon ?? Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Error dialog
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorDialog({
    super.key,
    this.title = 'Error',
    required this.message,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        Icons.error_outline,
        color: Theme.of(context).colorScheme.error,
        size: 32,
      ),
      title: Text(title),
      content: Text(message),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        TextButton(
          onPressed: onDismiss ?? () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }

  static Future<void> show(
    BuildContext context, {
    String title = 'Error',
    required String message,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        onRetry: onRetry,
        onDismiss: onDismiss,
      ),
    );
  }
}

/// Network error widget
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? message;

  const NetworkErrorWidget({
    super.key,
    this.onRetry,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Connection Error',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'Please check your internet connection and try again.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}