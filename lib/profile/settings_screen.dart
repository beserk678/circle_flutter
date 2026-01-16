import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifications/notification_settings_screen.dart';
import '../core/theme/theme_controller.dart';
import 'profile_controller.dart';
import 'account_settings_screen.dart';
import 'app_preferences_screen.dart';
import 'user_circles_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Appearance section
          _buildSectionHeader(context, 'Appearance'),
          Consumer<ThemeController>(
            builder: (context, themeController, child) {
              return SwitchListTile(
                secondary: Icon(
                  themeController.isDarkMode
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
                title: const Text('Dark Mode'),
                subtitle: Text(
                  themeController.isDarkMode ? 'Enabled' : 'Disabled',
                ),
                value: themeController.isDarkMode,
                onChanged: (value) {
                  themeController.toggleTheme();
                },
              );
            },
          ),

          const Divider(),

          // Account section
          _buildSectionHeader(context, 'Account'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Account Settings'),
            subtitle: const Text('Email, password, and security'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AccountSettingsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: const Text('My Circles'),
            subtitle: const Text('Manage your circle memberships'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const UserCirclesScreen(),
                ),
              );
            },
          ),

          const Divider(),

          // Preferences section
          _buildSectionHeader(context, 'Preferences'),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            subtitle: const Text('Push notifications and preferences'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('App Preferences'),
            subtitle: const Text('Theme, language, and display'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AppPreferencesScreen(),
                ),
              );
            },
          ),

          const Divider(),

          // Support section
          _buildSectionHeader(context, 'Support'),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            subtitle: const Text('Get help and contact support'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showComingSoon(context, 'Help & Support');
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Send Feedback'),
            subtitle: const Text('Help us improve Circle'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showComingSoon(context, 'Send Feedback');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('Version and app information'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showAboutDialog(context);
            },
          ),

          const SizedBox(height: 32),

          // App version
          Consumer<ProfileController>(
            builder: (context, controller, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Circle v1.0.0',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(feature),
            content: const Text('This feature is coming soon!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Circle',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.groups, color: Colors.white, size: 32),
      ),
      children: [
        const Text(
          'Circle is a comprehensive collaboration platform that brings together social interaction, real-time communication, task management, and file sharing in private circles.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Built with Flutter and Firebase for a seamless cross-platform experience.',
        ),
      ],
    );
  }
}
