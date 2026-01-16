import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_controller.dart';
import 'profile_controller.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
      ),
      body: Consumer<ProfileController>(
        builder: (context, controller, child) {
          final profile = controller.currentUserProfile;
          final preferences = controller.appPreferences;
          
          return ListView(
            children: [
              // Account info section
              _buildSectionHeader(context, 'Account Information'),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email'),
                subtitle: Text(profile?.email ?? 'Loading...'),
                trailing: const Icon(Icons.edit, size: 20),
                onTap: () => _showChangeEmailDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Password'),
                subtitle: const Text('Change your password'),
                trailing: const Icon(Icons.edit, size: 20),
                onTap: () => _showChangePasswordDialog(context),
              ),

              const Divider(),

              // Privacy section
              _buildSectionHeader(context, 'Privacy'),
              SwitchListTile(
                secondary: const Icon(Icons.visibility_outlined),
                title: const Text('Online Status'),
                subtitle: const Text('Show when you\'re online'),
                value: preferences?.showOnlineStatus ?? true,
                onChanged: (value) {
                  if (preferences != null) {
                    controller.updateAppPreferences(
                      preferences.copyWith(showOnlineStatus: value),
                    );
                  }
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.message_outlined),
                title: const Text('Direct Messages'),
                subtitle: const Text('Allow others to message you directly'),
                value: preferences?.allowDirectMessages ?? true,
                onChanged: (value) {
                  if (preferences != null) {
                    controller.updateAppPreferences(
                      preferences.copyWith(allowDirectMessages: value),
                    );
                  }
                },
              ),

              const Divider(),

              // Danger zone
              _buildSectionHeader(context, 'Danger Zone'),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete Account'),
                subtitle: const Text('Permanently delete your account and data'),
                textColor: Colors.red,
                onTap: () => _showDeleteAccountDialog(context),
              ),
            ],
          );
        },
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

  void _showChangeEmailDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Email'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'New Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your new email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer<ProfileController>(
            builder: (context, controller, child) {
              return TextButton(
                onPressed: controller.isUpdating
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          final success = await controller.updateEmail(
                            emailController.text.trim(),
                            passwordController.text,
                          );
                          if (success && context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Verification email sent to new address'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                child: controller.isUpdating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Update'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer<ProfileController>(
            builder: (context, controller, child) {
              return TextButton(
                onPressed: controller.isUpdating
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          final success = await controller.changePassword(
                            currentPasswordController.text,
                            newPasswordController.text,
                          );
                          if (success && context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password changed successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                child: controller.isUpdating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Change'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This action cannot be undone. All your data will be permanently deleted.',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Enter your password to confirm',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer<ProfileController>(
            builder: (context, controller, child) {
              return TextButton(
                onPressed: controller.isUpdating
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          final success = await controller.deleteAccount(
                            passwordController.text,
                          );
                          if (success && context.mounted) {
                            Navigator.pop(context);
                            // Sign out will be handled automatically
                            context.read<AuthController>().signOut();
                          }
                        }
                      },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: controller.isUpdating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Delete Account'),
              );
            },
          ),
        ],
      ),
    );
  }
}