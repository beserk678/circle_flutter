import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../circle_controller.dart';

class CreateCircleScreen extends StatefulWidget {
  const CreateCircleScreen({super.key});

  @override
  State<CreateCircleScreen> createState() => _CreateCircleScreenState();
}

class _CreateCircleScreenState extends State<CreateCircleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Circle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Consumer<CircleController>(
          builder: (context, circleController, child) {
            return Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const Icon(
                    Icons.group_add,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Create Your Circle',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Give your circle a name that represents your group',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Circle name field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Circle Name',
                      hintText: 'e.g., Family, Work Team, Study Group',
                      prefixIcon: Icon(Icons.circle_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a circle name';
                      }
                      if (value.trim().length < 2) {
                        return 'Circle name must be at least 2 characters';
                      }
                      if (value.trim().length > 50) {
                        return 'Circle name must be less than 50 characters';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 24),

                  // Info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'After creating your circle, you\'ll get an invite code to share with others.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error message
                  if (circleController.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        circleController.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Create button
                  ElevatedButton(
                    onPressed: circleController.isLoading ? null : _handleCreate,
                    child: circleController.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Circle'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final circleController = context.read<CircleController>();
    final success = await circleController.createCircle(_nameController.text.trim());

    if (success && mounted) {
      // Show success and invite code
      _showInviteCodeDialog();
    }
  }

  void _showInviteCodeDialog() {
    final circle = context.read<CircleController>().selectedCircle;
    if (circle == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Circle Created!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Your circle "${circle.name}" has been created successfully!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'Invite Code:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    circle.inviteCode,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share this code with others to invite them to your circle.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}