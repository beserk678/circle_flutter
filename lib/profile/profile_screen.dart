import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_controller.dart';
import '../core/theme/design_tokens.dart';
import 'profile_controller.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'user_circles_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // If null, shows current user's profile

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.userId == null) {
        // Initialize current user's profile
        context.read<ProfileController>().initializeProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundColor(context),
      appBar: DesignTokens.appBar(
        context,
        title: widget.userId == null ? 'Profile' : 'User Profile',
        actions:
            widget.userId == null
                ? [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ]
                : null,
      ),
      body:
          widget.userId == null
              ? _buildCurrentUserProfile()
              : _buildOtherUserProfile(widget.userId!),
    );
  }

  Widget _buildCurrentUserProfile() {
    return Consumer<ProfileController>(
      builder: (context, controller, child) {
        if (controller.isLoading && controller.currentUserProfile == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = controller.currentUserProfile;
        if (profile == null) {
          return const Center(child: Text('Failed to load profile'));
        }

        return RefreshIndicator(
          onRefresh: () => controller.initializeProfile(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile header
                _buildProfileHeader(profile, isCurrentUser: true),
                const SizedBox(height: 24),

                // Profile stats
                _buildProfileStats(profile),
                const SizedBox(height: 24),

                // Action buttons
                _buildActionButtons(context),
                const SizedBox(height: 24),

                // Profile info
                _buildProfileInfo(profile),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOtherUserProfile(String userId) {
    return FutureBuilder(
      future: context.read<ProfileController>().getUserProfile(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Failed to load profile'));
        }

        final profile = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildProfileHeader(profile, isCurrentUser: false),
              const SizedBox(height: 24),
              _buildProfileStats(profile),
              const SizedBox(height: 24),
              _buildProfileInfo(profile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(dynamic profile, {required bool isCurrentUser}) {
    return Column(
      children: [
        // Profile photo
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient:
                        profile.photoUrl == null
                            ? const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                            : null,
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.transparent,
                    backgroundImage:
                        profile.photoUrl != null
                            ? NetworkImage(profile.photoUrl!)
                            : null,
                    child:
                        profile.photoUrl == null
                            ? Text(
                              profile.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                            : null,
                  ),
                ),
              ),
            ),
            if (isCurrentUser)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    onPressed: () => _showPhotoOptions(context),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Name and email
        Text(
          profile.displayName,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          profile.email,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),

        // Online status
        if (!isCurrentUser)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: profile.isOnline ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              profile.lastSeenText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileStats(dynamic profile) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: context.read<ProfileController>().getUserCircles(),
      builder: (context, snapshot) {
        final circleCount = snapshot.data?.length ?? 0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('Circles', circleCount.toString(), Icons.groups, () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const UserCirclesScreen(),
                ),
              );
            }),
            _buildStatItem(
              'Joined',
              _formatJoinDate(profile.joinedAt),
              Icons.calendar_today,
              null,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF6366F1)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.edit, color: Color(0xFF6366F1)),
              label: const Text(
                'Edit Profile',
                style: TextStyle(
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton.icon(
              onPressed: () {
                context.read<AuthController>().signOut();
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(dynamic profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profile.bio != null && profile.bio!.isNotEmpty) ...[
          Text(
            'About',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(profile.bio!),
          const SizedBox(height: 16),
        ],

        if (profile.location != null && profile.location!.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.location_on, size: 20),
              const SizedBox(width: 8),
              Text(profile.location!),
            ],
          ),
          const SizedBox(height: 8),
        ],

        if (profile.website != null && profile.website!.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.link, size: 20),
              const SizedBox(width: 8),
              Text(
                profile.website!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
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
                  onTap: () {
                    Navigator.pop(context);
                    context.read<ProfileController>().uploadPhotoFromCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    context.read<ProfileController>().uploadPhotoFromGallery();
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
                    onTap: () {
                      Navigator.pop(context);
                      context.read<ProfileController>().deleteProfilePhoto();
                    },
                  ),
              ],
            ),
          ),
    );
  }

  String _formatJoinDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
