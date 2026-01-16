import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/auth_service.dart';
import 'notification_controller.dart';
import 'notification_model.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  NotificationPreferences? _preferences;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    final controller = context.read<NotificationController>();
    if (controller.preferences != null) {
      setState(() {
        _preferences = controller.preferences;
        _isLoading = false;
      });
    } else {
      // Load default preferences
      setState(() {
        _preferences = NotificationPreferences(userId: user.uid);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _preferences == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notification Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        actions: [
          Consumer<NotificationController>(
            builder: (context, controller, child) {
              return TextButton(
                onPressed: controller.isLoading ? null : _savePreferences,
                child: controller.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Push notifications master switch
          Card(
            child: SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive notifications on this device'),
              value: _preferences!.pushNotifications,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(pushNotifications: value);
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // Notification types
          if (_preferences!.pushNotifications) ...[
            Text(
              'Notification Types',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('New Messages'),
                    subtitle: const Text('When someone sends a message'),
                    value: _preferences!.newMessages,
                    onChanged: (value) {
                      setState(() {
                        _preferences = _preferences!.copyWith(newMessages: value);
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('New Posts'),
                    subtitle: const Text('When someone creates a post'),
                    value: _preferences!.newPosts,
                    onChanged: (value) {
                      setState(() {
                        _preferences = _preferences!.copyWith(newPosts: value);
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Post Comments'),
                    subtitle: const Text('When someone comments on posts'),
                    value: _preferences!.postComments,
                    onChanged: (value) {
                      setState(() {
                        _preferences = _preferences!.copyWith(postComments: value);
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Post Likes'),
                    subtitle: const Text('When someone likes posts'),
                    value: _preferences!.postLikes,
                    onChanged: (value) {
                      setState(() {
                        _preferences = _preferences!.copyWith(postLikes: value);
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Task Assignments'),
                    subtitle: const Text('When tasks are assigned or completed'),
                    value: _preferences!.taskAssignments,
                    onChanged: (value) {
                      setState(() {
                        _preferences = _preferences!.copyWith(taskAssignments: value);
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Task Reminders'),
                    subtitle: const Text('When tasks are due'),
                    value: _preferences!.taskReminders,
                    onChanged: (value) {
                      setState(() {
                        _preferences = _preferences!.copyWith(taskReminders: value);
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('File Uploads'),
                    subtitle: const Text('When someone uploads files'),
                    value: _preferences!.fileUploads,
                    onChanged: (value) {
                      setState(() {
                        _preferences = _preferences!.copyWith(fileUploads: value);
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Circle Activity'),
                    subtitle: const Text('When members join or leave'),
                    value: _preferences!.circleActivity,
                    onChanged: (value) {
                      setState(() {
                        _preferences = _preferences!.copyWith(circleActivity: value);
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quiet hours
            Text(
              'Quiet Hours',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Enable Quiet Hours'),
                    subtitle: const Text('Pause notifications during specified hours'),
                    value: _preferences!.quietHoursEnabled,
                    onChanged: (value) {
                      setState(() {
                        _preferences = _preferences!.copyWith(quietHoursEnabled: value);
                      });
                    },
                  ),
                  if (_preferences!.quietHoursEnabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Start Time'),
                      subtitle: Text(_preferences!.quietHoursStart),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _selectTime(true),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('End Time'),
                      subtitle: Text(_preferences!.quietHoursEnd),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _selectTime(false),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Error message
          Consumer<NotificationController>(
            builder: (context, controller, child) {
              if (controller.errorMessage != null) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    controller.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(bool isStartTime) async {
    final currentTime = isStartTime ? _preferences!.quietHoursStart : _preferences!.quietHoursEnd;
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (time != null) {
      final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStartTime) {
          _preferences = _preferences!.copyWith(quietHoursStart: timeString);
        } else {
          _preferences = _preferences!.copyWith(quietHoursEnd: timeString);
        }
      });
    }
  }

  Future<void> _savePreferences() async {
    if (_preferences == null) return;

    final controller = context.read<NotificationController>();
    final success = await controller.updatePreferences(_preferences!);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

extension NotificationPreferencesExtension on NotificationPreferences {
  NotificationPreferences copyWith({
    bool? pushNotifications,
    bool? newMessages,
    bool? newPosts,
    bool? postComments,
    bool? postLikes,
    bool? taskAssignments,
    bool? taskReminders,
    bool? fileUploads,
    bool? circleActivity,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? quietHoursEnabled,
  }) {
    return NotificationPreferences(
      userId: userId,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      newMessages: newMessages ?? this.newMessages,
      newPosts: newPosts ?? this.newPosts,
      postComments: postComments ?? this.postComments,
      postLikes: postLikes ?? this.postLikes,
      taskAssignments: taskAssignments ?? this.taskAssignments,
      taskReminders: taskReminders ?? this.taskReminders,
      fileUploads: fileUploads ?? this.fileUploads,
      circleActivity: circleActivity ?? this.circleActivity,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
    );
  }
}