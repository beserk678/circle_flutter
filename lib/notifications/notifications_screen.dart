import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notification_controller.dart';
import 'notification_model.dart';
import 'notification_settings_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationController>().initializeNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF6366F1)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Consumer<NotificationController>(
              builder: (context, controller, child) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF6366F1)),
                  onSelected: (value) {
                    if (value == 'mark_all_read') {
                      controller.markAllAsRead();
                    } else if (value == 'settings') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (context) => const NotificationSettingsScreen(),
                        ),
                      );
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder:
                      (context) => [
                        if (controller.unreadCount > 0)
                          const PopupMenuItem(
                            value: 'mark_all_read',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.mark_email_read,
                                  color: Color(0xFF6366F1),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Mark all as read',
                                  style: TextStyle(color: Color(0xFF374151)),
                                ),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'settings',
                          child: Row(
                            children: [
                              Icon(Icons.settings, color: Color(0xFF6366F1)),
                              SizedBox(width: 12),
                              Text(
                                'Settings',
                                style: TextStyle(color: Color(0xFF374151)),
                              ),
                            ],
                          ),
                        ),
                      ],
                );
              },
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Consumer<NotificationController>(
              builder: (context, controller, child) {
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('All'),
                      if (controller.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            controller.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const Tab(text: 'Today'),
            const Tab(text: 'This Week'),
          ],
        ),
      ),
      body: Consumer<NotificationController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildNotificationList(controller.notifications),
              _buildNotificationList(controller.todayNotifications),
              _buildNotificationList(controller.thisWeekNotifications),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationList(List<AppNotification> notifications) {
    if (notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.notifications_none,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You\'re all caught up!',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return NotificationTile(
          notification: notification,
          onTap: () => _handleNotificationTap(notification),
          onDismiss: () => _handleNotificationDismiss(notification),
        );
      },
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    final controller = context.read<NotificationController>();

    // Mark as read if not already
    if (!notification.isRead) {
      controller.markAsRead(notification.id);
    }

    // Navigate based on notification type
    // This would typically navigate to the relevant screen
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tapped: ${notification.title}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleNotificationDismiss(AppNotification notification) {
    final controller = context.read<NotificationController>();
    controller.deleteNotification(notification.id);
  }
}

class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        color:
            notification.isRead
                ? null
                : Theme.of(context).colorScheme.primary.withOpacity(0.05),
        child: ListTile(
          leading: _buildNotificationIcon(),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    notification.circleName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    notification.timeAgo,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          trailing:
              notification.actionUserPhotoUrl != null
                  ? CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(
                      notification.actionUserPhotoUrl!,
                    ),
                  )
                  : notification.actionUserName != null
                  ? CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      notification.actionUserName![0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                  : null,
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.newMessage:
        icon = Icons.message;
        color = Colors.blue;
        break;
      case NotificationType.newPost:
        icon = Icons.article;
        color = Colors.green;
        break;
      case NotificationType.postComment:
        icon = Icons.comment;
        color = Colors.orange;
        break;
      case NotificationType.postLike:
        icon = Icons.favorite;
        color = Colors.red;
        break;
      case NotificationType.taskAssigned:
        icon = Icons.assignment;
        color = Colors.purple;
        break;
      case NotificationType.taskCompleted:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case NotificationType.taskDue:
        icon = Icons.schedule;
        color = Colors.orange;
        break;
      case NotificationType.fileUploaded:
        icon = Icons.upload_file;
        color = Colors.teal;
        break;
      case NotificationType.circleInvite:
        icon = Icons.group_add;
        color = Colors.indigo;
        break;
      case NotificationType.memberJoined:
        icon = Icons.person_add;
        color = Colors.green;
        break;
      case NotificationType.memberLeft:
        icon = Icons.person_remove;
        color = Colors.grey;
        break;
      case NotificationType.system:
        icon = Icons.info;
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
