import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'circle_controller.dart';
import 'circle_model.dart';
import 'circle_service.dart';
import '../core/theme/design_tokens.dart';

class JoinCircleScreen extends StatefulWidget {
  const JoinCircleScreen({super.key});

  @override
  State<JoinCircleScreen> createState() => _JoinCircleScreenState();
}

class _JoinCircleScreenState extends State<JoinCircleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inviteCodeController = TextEditingController();
  final _circleService = CircleService.instance;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundColor(context),
      appBar: DesignTokens.appBar(context, title: 'Join Circle'),
      body: Consumer<CircleController>(
        builder: (context, circleController, child) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Available Circles Section
                Padding(
                  padding: const EdgeInsets.all(DesignTokens.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Circles',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: DesignTokens.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spacing8),
                      Text(
                        'Browse and join circles',
                        style: TextStyle(
                          fontSize: 14,
                          color: DesignTokens.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spacing16),
                      _buildCirclesList(),
                    ],
                  ),
                ),

                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacing16,
                    vertical: DesignTokens.spacing8,
                  ),
                  child: Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacing16,
                        ),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: DesignTokens.textTertiary(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                ),

                // Invite Code Section
                Padding(
                  padding: const EdgeInsets.all(DesignTokens.spacing16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Join with Invite Code',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: DesignTokens.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spacing8),
                        Text(
                          'Have an invite code? Enter it below',
                          style: TextStyle(
                            fontSize: 14,
                            color: DesignTokens.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spacing16),

                        // Invite code field
                        TextFormField(
                          controller: _inviteCodeController,
                          decoration: DesignTokens.inputDecoration(
                            context,
                            'Enter 6-character code',
                          ).copyWith(
                            labelText: 'Invite Code',
                            prefixIcon: const Icon(Icons.vpn_key_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an invite code';
                            }
                            if (value.trim().length != 6) {
                              return 'Invite code must be 6 characters';
                            }
                            return null;
                          },
                          textCapitalization: TextCapitalization.characters,
                          onChanged: (value) {
                            final upperValue = value.toUpperCase();
                            if (upperValue != value) {
                              _inviteCodeController
                                  .value = _inviteCodeController.value.copyWith(
                                text: upperValue,
                                selection: TextSelection.collapsed(
                                  offset: upperValue.length,
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: DesignTokens.spacing16),

                        // Info card
                        Container(
                          padding: const EdgeInsets.all(DesignTokens.spacing12),
                          decoration: BoxDecoration(
                            color: DesignTokens.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radius12,
                            ),
                            border: Border.all(
                              color: DesignTokens.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: DesignTokens.primaryColor,
                                size: 20,
                              ),
                              SizedBox(width: DesignTokens.spacing12),
                              Expanded(
                                child: Text(
                                  'Ask a circle member for the 6-character invite code',
                                  style: TextStyle(
                                    color: DesignTokens.primaryColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spacing16),

                        // Error message
                        if (circleController.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(
                              DesignTokens.spacing12,
                            ),
                            decoration: BoxDecoration(
                              color: DesignTokens.errorColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(
                                DesignTokens.radius8,
                              ),
                              border: Border.all(
                                color: DesignTokens.errorColor.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Text(
                              circleController.errorMessage!,
                              style: const TextStyle(
                                color: DesignTokens.errorColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: DesignTokens.spacing16),
                        ],

                        // Join button
                        DesignTokens.gradientButton(
                          text: 'Join with Code',
                          icon: Icons.vpn_key,
                          onPressed:
                              circleController.isLoading
                                  ? null
                                  : _handleJoinByCode,
                          isLoading: circleController.isLoading,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCirclesList() {
    return StreamBuilder<List<Circle>>(
      stream: _circleService.getAllCircles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(DesignTokens.spacing24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(DesignTokens.spacing16),
            decoration: BoxDecoration(
              color: DesignTokens.errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: DesignTokens.errorColor),
                const SizedBox(width: DesignTokens.spacing12),
                Expanded(
                  child: Text(
                    'Error loading circles: ${snapshot.error}',
                    style: const TextStyle(color: DesignTokens.errorColor),
                  ),
                ),
              ],
            ),
          );
        }

        final circles = snapshot.data ?? [];

        if (circles.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(DesignTokens.spacing24),
            decoration: DesignTokens.cardDecoration(context),
            child: Column(
              children: [
                Icon(
                  Icons.groups_outlined,
                  size: 48,
                  color: DesignTokens.textTertiary(context),
                ),
                const SizedBox(height: DesignTokens.spacing12),
                Text(
                  'No circles available yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textPrimary(context),
                  ),
                ),
                const SizedBox(height: DesignTokens.spacing4),
                Text(
                  'Be the first to create one!',
                  style: TextStyle(
                    fontSize: 14,
                    color: DesignTokens.textSecondary(context),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: circles.length,
          itemBuilder: (context, index) {
            final circle = circles[index];
            return _buildCircleCard(circle);
          },
        );
      },
    );
  }

  Widget _buildCircleCard(Circle circle) {
    final circleController = context.read<CircleController>();
    final currentUserId =
        circleController.userCircles.isNotEmpty
            ? circleController.userCircles.first.members.first
            : null;
    final isAlreadyMember =
        currentUserId != null && circle.members.contains(currentUserId);

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacing12),
      decoration: DesignTokens.cardDecoration(context),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacing16,
          vertical: DesignTokens.spacing8,
        ),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: DesignTokens.primaryGradient,
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
          ),
          child: Center(
            child: Text(
              circle.name.isNotEmpty ? circle.name[0].toUpperCase() : 'C',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          circle.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: DesignTokens.textPrimary(context),
          ),
        ),
        subtitle: Text(
          '${circle.members.length} ${circle.members.length == 1 ? 'member' : 'members'}',
          style: TextStyle(
            color: DesignTokens.textSecondary(context),
            fontSize: 14,
          ),
        ),
        trailing:
            isAlreadyMember
                ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacing12,
                    vertical: DesignTokens.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radius8),
                    border: Border.all(
                      color: DesignTokens.successColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    'Joined',
                    style: TextStyle(
                      color: DesignTokens.successColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                : Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: DesignTokens.textTertiary(context),
                ),
        onTap: isAlreadyMember ? null : () => _handleJoinCircle(circle),
      ),
    );
  }

  Future<void> _handleJoinCircle(Circle circle) async {
    final circleController = context.read<CircleController>();
    final success = await circleController.joinCircle(circle.inviteCode);

    if (success && mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joined ${circle.name}! Tap it to open.'),
          backgroundColor: DesignTokens.successColor,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Go back to selection screen where the circle will now appear in the list
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleJoinByCode() async {
    if (!_formKey.currentState!.validate()) return;

    final circleController = context.read<CircleController>();
    
    print('JoinCircleScreen - Before join, selectedCircle: ${circleController.selectedCircle?.name}');
    
    final success = await circleController.joinCircle(
      _inviteCodeController.text.trim(),
    );

    print('JoinCircleScreen - After join, success: $success, selectedCircle: ${circleController.selectedCircle?.name}');

    if (success && mounted) {
      final selectedCircle = circleController.selectedCircle;
      
      if (selectedCircle == null) {
        print('ERROR: selectedCircle is null after successful join!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Circle not found after joining'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      print('JoinCircleScreen - Circle joined: ${selectedCircle.name}, ID: ${selectedCircle.id}');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joined ${selectedCircle.name}! Tap it to open.'),
          backgroundColor: DesignTokens.successColor,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Go back to selection screen where the circle will now appear in the list
      Navigator.of(context).pop();
    }
  }
}
