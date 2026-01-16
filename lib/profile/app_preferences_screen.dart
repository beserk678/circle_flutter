import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'profile_controller.dart';
import 'user_profile_model.dart';

class AppPreferencesScreen extends StatefulWidget {
  const AppPreferencesScreen({super.key});

  @override
  State<AppPreferencesScreen> createState() => _AppPreferencesScreenState();
}

class _AppPreferencesScreenState extends State<AppPreferencesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileController>().initializeProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Preferences'),
      ),
      body: Consumer<ProfileController>(
        builder: (context, controller, child) {
          final preferences = controller.appPreferences;
          
          if (controller.isLoading && preferences == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (preferences == null) {
            return const Center(
              child: Text('Failed to load preferences'),
            );
          }

          return ListView(
            children: [
              // Appearance section
              _buildSectionHeader(context, 'Appearance'),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Theme'),
                subtitle: Text(_getThemeDisplayName(preferences.theme)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showThemeDialog(context, preferences),
              ),
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: const Text('Font Size'),
                subtitle: Text(_getFontSizeDisplayName(preferences.fontSize)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showFontSizeDialog(context, preferences),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.motion_photos_off_outlined),
                title: const Text('Reduced Motion'),
                subtitle: const Text('Reduce animations and transitions'),
                value: preferences.reducedMotion,
                onChanged: (value) => _updatePreferences(
                  preferences.copyWith(reducedMotion: value),
                ),
              ),

              const Divider(),

              // Language section
              _buildSectionHeader(context, 'Language & Region'),
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: const Text('Language'),
                subtitle: Text(_getLanguageDisplayName(preferences.language)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showLanguageDialog(context, preferences),
              ),

              const Divider(),

              // Privacy section
              _buildSectionHeader(context, 'Privacy'),
              SwitchListTile(
                secondary: const Icon(Icons.visibility_outlined),
                title: const Text('Show Online Status'),
                subtitle: const Text('Let others see when you\'re online'),
                value: preferences.showOnlineStatus,
                onChanged: (value) => _updatePreferences(
                  preferences.copyWith(showOnlineStatus: value),
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.message_outlined),
                title: const Text('Allow Direct Messages'),
                subtitle: const Text('Let others message you directly'),
                value: preferences.allowDirectMessages,
                onChanged: (value) => _updatePreferences(
                  preferences.copyWith(allowDirectMessages: value),
                ),
              ),

              const Divider(),

              // Media section
              _buildSectionHeader(context, 'Media'),
              SwitchListTile(
                secondary: const Icon(Icons.download_outlined),
                title: const Text('Auto-download Media'),
                subtitle: const Text('Automatically download images and files'),
                value: preferences.autoDownloadMedia,
                onChanged: (value) => _updatePreferences(
                  preferences.copyWith(autoDownloadMedia: value),
                ),
              ),

              const Divider(),

              // Sound & Vibration section
              _buildSectionHeader(context, 'Sound & Vibration'),
              SwitchListTile(
                secondary: const Icon(Icons.volume_up_outlined),
                title: const Text('Sound'),
                subtitle: const Text('Play sounds for notifications'),
                value: preferences.soundEnabled,
                onChanged: (value) => _updatePreferences(
                  preferences.copyWith(soundEnabled: value),
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.vibration_outlined),
                title: const Text('Vibration'),
                subtitle: const Text('Vibrate for notifications'),
                value: preferences.vibrationEnabled,
                onChanged: (value) => _updatePreferences(
                  preferences.copyWith(vibrationEnabled: value),
                ),
              ),

              const SizedBox(height: 32),

              // Error message
              if (controller.errorMessage != null) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      controller.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ],
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

  void _updatePreferences(AppPreferences preferences) {
    context.read<ProfileController>().updateAppPreferences(preferences);
  }

  void _showThemeDialog(BuildContext context, AppPreferences preferences) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'light',
              groupValue: preferences.theme,
              onChanged: (value) {
                Navigator.pop(context);
                _updatePreferences(preferences.copyWith(theme: value));
              },
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'dark',
              groupValue: preferences.theme,
              onChanged: (value) {
                Navigator.pop(context);
                _updatePreferences(preferences.copyWith(theme: value));
              },
            ),
            RadioListTile<String>(
              title: const Text('System'),
              value: 'system',
              groupValue: preferences.theme,
              onChanged: (value) {
                Navigator.pop(context);
                _updatePreferences(preferences.copyWith(theme: value));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context, AppPreferences preferences) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Font Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<double>(
              title: const Text('Small'),
              value: 0.8,
              groupValue: preferences.fontSize,
              onChanged: (value) {
                Navigator.pop(context);
                _updatePreferences(preferences.copyWith(fontSize: value));
              },
            ),
            RadioListTile<double>(
              title: const Text('Normal'),
              value: 1.0,
              groupValue: preferences.fontSize,
              onChanged: (value) {
                Navigator.pop(context);
                _updatePreferences(preferences.copyWith(fontSize: value));
              },
            ),
            RadioListTile<double>(
              title: const Text('Large'),
              value: 1.2,
              groupValue: preferences.fontSize,
              onChanged: (value) {
                Navigator.pop(context);
                _updatePreferences(preferences.copyWith(fontSize: value));
              },
            ),
            RadioListTile<double>(
              title: const Text('Extra Large'),
              value: 1.4,
              groupValue: preferences.fontSize,
              onChanged: (value) {
                Navigator.pop(context);
                _updatePreferences(preferences.copyWith(fontSize: value));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, AppPreferences preferences) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: preferences.language,
              onChanged: (value) {
                Navigator.pop(context);
                _updatePreferences(preferences.copyWith(language: value));
              },
            ),
            RadioListTile<String>(
              title: const Text('Español'),
              value: 'es',
              groupValue: preferences.language,
              onChanged: (value) {
                Navigator.pop(context);
                _updatePreferences(preferences.copyWith(language: value));
              },
            ),
            RadioListTile<String>(
              title: const Text('Français'),
              value: 'fr',
              groupValue: preferences.language,
              onChanged: (value) {
                Navigator.pop(context);
                _updatePreferences(preferences.copyWith(language: value));
              },
            ),
            RadioListTile<String>(
              title: const Text('Deutsch'),
              value: 'de',
              groupValue: preferences.language,
              onChanged: (value) {
                Navigator.pop(context);
                _updatePreferences(preferences.copyWith(language: value));
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeDisplayName(String theme) {
    switch (theme) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'system':
        return 'System';
      default:
        return 'System';
    }
  }

  String _getFontSizeDisplayName(double fontSize) {
    if (fontSize <= 0.8) return 'Small';
    if (fontSize <= 1.0) return 'Normal';
    if (fontSize <= 1.2) return 'Large';
    return 'Extra Large';
  }

  String _getLanguageDisplayName(String language) {
    switch (language) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      default:
        return 'English';
    }
  }
}