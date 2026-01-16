import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'circle_controller.dart';
import 'circle_model.dart';
import 'create_circle/create_circle_screen.dart';
import 'join_circle_screen.dart';
import 'circle_home/circle_home_screen.dart';
import '../core/theme/design_tokens.dart';
import '../core/services/auth_service.dart';
import '../profile/profile_screen.dart';
import '../profile/profile_controller.dart';

class CircleSelectionScreen extends StatelessWidget {
  const CircleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundColor(context),
      appBar: DesignTokens.appBar(
        context,
        title: 'Your Circles',
        automaticallyImplyLeading: false,
        actions: [
          // Profile/Account button
          Consumer<ProfileController>(
            builder: (context, profileController, child) {
              final user = AuthService.instance.currentUser;
              final profile = profileController.currentUserProfile;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: CircleAvatar(
                    radius: 16,
                    backgroundColor: DesignTokens.primaryColor,
                    backgroundImage:
                        profile?.photoUrl != null
                            ? NetworkImage(profile!.photoUrl!)
                            : null,
                    child:
                        profile?.photoUrl == null
                            ? Text(
                              user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                            : null,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                  tooltip: 'Profile',
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<CircleController>(
        builder: (context, circleController, child) {
          // Debug: Print current state
          print(
            'CircleSelectionScreen - userCircles: ${circleController.userCircles.length}',
          );
          print(
            'CircleSelectionScreen - selectedCircle: ${circleController.selectedCircle?.name}',
          );

          if (circleController.userCircles.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildCirclesList(context, circleController);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacing24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success indicator
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacing16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: DesignTokens.successColor,
                  size: 20,
                ),
                SizedBox(width: DesignTokens.spacing8),
                Text(
                  'Account created successfully!',
                  style: TextStyle(
                    color: DesignTokens.successColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.spacing32),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: DesignTokens.primaryGradient,
              borderRadius: BorderRadius.circular(DesignTokens.radius24),
            ),
            child: const Icon(Icons.groups, size: 50, color: Colors.white),
          ),
          const SizedBox(height: DesignTokens.spacing24),
          const Text(
            'Welcome to Circle!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: DesignTokens.spacing8),
          Text(
            'Create your first circle or join an existing one to get started.',
            style: TextStyle(
              fontSize: 16,
              color: DesignTokens.textSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacing32),

          // Create Circle Button
          DesignTokens.gradientButton(
            text: 'Create Circle',
            icon: Icons.add,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateCircleScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: DesignTokens.spacing16),

          // Join Circle Button
          DesignTokens.outlinedButton(
            context,
            text: 'Join Circle',
            icon: Icons.group_add,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const JoinCircleScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCirclesList(
    BuildContext context,
    CircleController circleController,
  ) {
    return Column(
      children: [
        // Action buttons
        Padding(
          padding: const EdgeInsets.all(DesignTokens.spacing16),
          child: Row(
            children: [
              Expanded(
                child: DesignTokens.outlinedButton(
                  context,
                  text: 'Create',
                  icon: Icons.add,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreateCircleScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: DesignTokens.spacing16),
              Expanded(
                child: DesignTokens.gradientButton(
                  text: 'Join',
                  icon: Icons.group_add,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const JoinCircleScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Circles list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacing16,
            ),
            itemCount: circleController.userCircles.length,
            itemBuilder: (context, index) {
              final circle = circleController.userCircles[index];
              final isSelected =
                  circleController.selectedCircle?.id == circle.id;

              return Card(
                margin: const EdgeInsets.only(bottom: DesignTokens.spacing8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: DesignTokens.primaryColor,
                    child: Text(
                      circle.name.isNotEmpty
                          ? circle.name[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    circle.name,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text('${circle.members.length} members'),
                  trailing:
                      isSelected
                          ? const Icon(
                            Icons.check_circle,
                            color: DesignTokens.primaryColor,
                          )
                          : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    circleController.selectCircle(circle);
                    // Navigate to circle home and remove all previous routes
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const CircleHomeScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  onLongPress: () {
                    _showCircleOptions(context, circle, circleController);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCircleOptions(
    BuildContext context,
    Circle circle,
    CircleController circleController,
  ) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Circle Info'),
                  subtitle: Text('Invite Code: ${circle.inviteCode}'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCircleInfo(context, circle);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: const Text('Leave Circle'),
                  textColor: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmLeaveCircle(context, circle, circleController);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showCircleInfo(BuildContext context, Circle circle) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(circle.name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Members: ${circle.members.length}'),
                const SizedBox(height: DesignTokens.spacing8),
                Text('Created: ${_formatDate(circle.createdAt)}'),
                const SizedBox(height: DesignTokens.spacing16),
                Container(
                  padding: const EdgeInsets.all(DesignTokens.spacing12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(DesignTokens.radius8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Invite Code:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: DesignTokens.spacing4),
                      Text(
                        circle.inviteCode,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _confirmLeaveCircle(
    BuildContext context,
    Circle circle,
    CircleController circleController,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Leave Circle'),
            content: Text('Are you sure you want to leave "${circle.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final success = await circleController.leaveCircle(circle.id);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Left circle'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Leave'),
              ),
            ],
          ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
