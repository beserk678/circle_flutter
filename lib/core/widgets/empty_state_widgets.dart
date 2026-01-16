import 'package:flutter/material.dart';

/// Generic empty state widget
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final Color? iconColor;
  final double iconSize;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onActionPressed,
    this.iconColor,
    this.iconSize = 80,
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
              icon,
              size: iconSize,
              color: iconColor ?? Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onActionPressed != null) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onActionPressed,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty feed state
class EmptyFeedState extends StatelessWidget {
  final VoidCallback? onCreatePost;

  const EmptyFeedState({super.key, this.onCreatePost});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.article_outlined,
      title: 'No Posts Yet',
      subtitle: 'Be the first to share something with your circle!',
      actionText: 'Create Post',
      onActionPressed: onCreatePost,
      iconColor: Theme.of(context).colorScheme.primary,
    );
  }
}

/// Empty chat state
class EmptyChatState extends StatelessWidget {
  final VoidCallback? onSendMessage;

  const EmptyChatState({super.key, this.onSendMessage});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.chat_bubble_outline,
      title: 'Start the Conversation',
      subtitle: 'Send the first message to get things going!',
      actionText: 'Send Message',
      onActionPressed: onSendMessage,
      iconColor: Theme.of(context).colorScheme.primary,
    );
  }
}

/// Empty tasks state
class EmptyTasksState extends StatelessWidget {
  final VoidCallback? onCreateTask;

  const EmptyTasksState({super.key, this.onCreateTask});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.task_outlined,
      title: 'No Tasks Yet',
      subtitle: 'Create your first task to get organized!',
      actionText: 'Create Task',
      onActionPressed: onCreateTask,
      iconColor: Theme.of(context).colorScheme.primary,
    );
  }
}

/// Empty files state
class EmptyFilesState extends StatelessWidget {
  final VoidCallback? onUploadFile;

  const EmptyFilesState({super.key, this.onUploadFile});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.folder_outlined,
      title: 'No Files Yet',
      subtitle: 'Upload your first file to share with your circle!',
      actionText: 'Upload File',
      onActionPressed: onUploadFile,
      iconColor: Theme.of(context).colorScheme.primary,
    );
  }
}

/// Empty notifications state
class EmptyNotificationsState extends StatelessWidget {
  const EmptyNotificationsState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.notifications_none_outlined,
      title: 'All Caught Up!',
      subtitle: 'You have no new notifications.',
    );
  }
}

/// Empty search results state
class EmptySearchState extends StatelessWidget {
  final String query;

  const EmptySearchState({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.search_off_outlined,
      title: 'No Results Found',
      subtitle: 'No results found for "$query". Try a different search term.',
    );
  }
}

/// No internet connection state
class NoInternetState extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoInternetState({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.wifi_off_outlined,
      title: 'No Internet Connection',
      subtitle: 'Please check your connection and try again.',
      actionText: 'Retry',
      onActionPressed: onRetry,
      iconColor: Colors.orange,
    );
  }
}

/// Generic error state
class ErrorState extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.title = 'Something Went Wrong',
    this.subtitle = 'An unexpected error occurred. Please try again.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      title: title,
      subtitle: subtitle,
      actionText: onRetry != null ? 'Try Again' : null,
      onActionPressed: onRetry,
      iconColor: Theme.of(context).colorScheme.error,
    );
  }
}

/// Maintenance mode state
class MaintenanceState extends StatelessWidget {
  const MaintenanceState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.build_outlined,
      title: 'Under Maintenance',
      subtitle: 'We\'re making improvements! Please check back soon.',
      iconColor: Colors.orange,
    );
  }
}

/// Coming soon state
class ComingSoonState extends StatelessWidget {
  final String feature;

  const ComingSoonState({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.upcoming_outlined,
      title: 'Coming Soon',
      subtitle: '$feature is coming soon! Stay tuned for updates.',
      iconColor: Theme.of(context).colorScheme.primary,
    );
  }
}