import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/auth_controller.dart';
import '../../feed/feed_screen.dart';
import '../../chat/chat_screen.dart';
import '../../tasks/tasks_screen.dart';
import '../../files/files_screen.dart';
import '../../notifications/notifications_screen.dart';
import '../../notifications/notification_controller.dart';
import '../../profile/profile_screen.dart';
import '../circle_controller.dart';
import '../circle_selection_screen.dart';

class CircleHomeScreen extends StatefulWidget {
  const CircleHomeScreen({super.key});

  @override
  State<CircleHomeScreen> createState() => _CircleHomeScreenState();
}

class _CircleHomeScreenState extends State<CircleHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const FeedScreen(),
    const ChatScreen(),
    const TasksScreen(),
    const FilesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<CircleController>(
      builder: (context, circleController, child) {
        final selectedCircle = circleController.selectedCircle;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.circle,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedCircle?.name ?? 'Circle',
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.groups, color: Color(0xFF6366F1)),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CircleSelectionScreen(),
                    ),
                  );
                },
              ),
            ),
            actions: [
              // Notifications button with badge
              Consumer<NotificationController>(
                builder: (context, notificationController, child) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: Color(0xFF6366F1),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) => const NotificationsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        if (notificationController.unreadCount > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFEF4444),
                                    Color(0xFFDC2626),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                notificationController.unreadCount > 99
                                    ? '99+'
                                    : notificationController.unreadCount
                                        .toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF6366F1)),
                  onSelected: (value) {
                    if (value == 'logout') {
                      context.read<AuthController>().signOut();
                    } else if (value == 'switch_circle') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CircleSelectionScreen(),
                        ),
                      );
                    } else if (value == 'profile') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                color: Color(0xFF6366F1),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Profile',
                                style: TextStyle(color: Color(0xFF374151)),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'switch_circle',
                          child: Row(
                            children: [
                              Icon(
                                Icons.switch_account_outlined,
                                color: Color(0xFF6366F1),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Switch Circle',
                                style: TextStyle(color: Color(0xFF374151)),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(
                                Icons.logout_outlined,
                                color: Color(0xFFEF4444),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Sign Out',
                                style: TextStyle(color: Color(0xFFEF4444)),
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
              ),
            ],
          ),
          body: _screens[_currentIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Container(
                height: 80,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_outlined, Icons.home, 'Feed'),
                    _buildNavItem(1, Icons.chat_outlined, Icons.chat, 'Chat'),
                    _buildNavItem(2, Icons.task_outlined, Icons.task, 'Tasks'),
                    _buildNavItem(
                      3,
                      Icons.folder_outlined,
                      Icons.folder,
                      'Files',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient:
              isActive
                  ? const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? Colors.white : const Color(0xFF9CA3AF),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF9CA3AF),
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
