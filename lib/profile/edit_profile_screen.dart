import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = context.read<ProfileController>().currentUserProfile;
      if (profile != null) {
        _nameController.text = profile.name;
        _bioController.text = profile.bio ?? '';
        _locationController.text = profile.location ?? '';
        _websiteController.text = profile.website ?? '';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          Consumer<ProfileController>(
            builder: (context, controller, child) {
              return TextButton(
                onPressed: controller.isUpdating ? null : _handleSave,
                child:
                    controller.isUpdating
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
      body: Consumer<ProfileController>(
        builder: (context, controller, child) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile photo section
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        backgroundImage:
                            controller.currentUserProfile?.photoUrl != null
                                ? NetworkImage(
                                  controller.currentUserProfile!.photoUrl!,
                                )
                                : null,
                        child:
                            controller.currentUserProfile?.photoUrl == null
                                ? Text(
                                  controller.currentUserProfile?.initials ??
                                      'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                            onPressed: () => _showPhotoOptions(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                // Bio field
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio (Optional)',
                    prefixIcon: Icon(Icons.info_outline),
                    hintText: 'Tell us about yourself...',
                  ),
                  maxLines: 3,
                  maxLength: 150,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),

                // Location field
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location (Optional)',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    hintText: 'Where are you based?',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                // Website field
                TextFormField(
                  controller: _websiteController,
                  decoration: const InputDecoration(
                    labelText: 'Website (Optional)',
                    prefixIcon: Icon(Icons.link_outlined),
                    hintText: 'https://yourwebsite.com',
                  ),
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final uri = Uri.tryParse(value);
                      if (uri == null || !uri.hasAbsolutePath) {
                        return 'Please enter a valid URL';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Error message
                if (controller.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      controller.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<ProfileController>();
    final success = await controller.updateProfile(
      name: _nameController.text.trim(),
      bio:
          _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
      location:
          _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
      website:
          _websiteController.text.trim().isEmpty
              ? null
              : _websiteController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showPhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    _showUploadingDialog(context);
                    final success =
                        await context
                            .read<ProfileController>()
                            .uploadPhotoFromCamera();
                    if (mounted) {
                      Navigator.pop(context); // Close loading dialog
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Photo uploaded successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    _showUploadingDialog(context);
                    final success =
                        await context
                            .read<ProfileController>()
                            .uploadPhotoFromGallery();
                    if (mounted) {
                      Navigator.pop(context); // Close loading dialog
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Photo uploaded successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                ),
                if (context
                        .read<ProfileController>()
                        .currentUserProfile
                        ?.photoUrl !=
                    null)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Remove Photo'),
                    textColor: Colors.red,
                    onTap: () async {
                      Navigator.pop(context);
                      _showUploadingDialog(context);
                      final success =
                          await context
                              .read<ProfileController>()
                              .deleteProfilePhoto();
                      if (mounted) {
                        Navigator.pop(context); // Close loading dialog
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Photo removed successfully!'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    },
                  ),
              ],
            ),
          ),
    );
  }

  void _showUploadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => PopScope(
            canPop: false,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Uploading photo...',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please wait',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
