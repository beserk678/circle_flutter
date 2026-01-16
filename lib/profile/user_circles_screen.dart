import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../circles/circle_controller.dart';
import '../circles/join_circle_screen.dart';
import '../circles/create_circle/create_circle_screen.dart';
import 'profile_controller.dart';

class UserCirclesScreen extends StatefulWidget {
  const UserCirclesScreen({super.key});

  @override
  State<UserCirclesScreen> createState() => _UserCirclesScreenState();
}

class _UserCirclesScreenState extends State<UserCirclesScreen> {
  List<Map<String, dynamic>> _userCircles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserCircles();
  }

  Future<void> _loadUserCircles() async {
    setState(() => _isLoading = true);
    
    final circles = await context.read<ProfileController>().getUserCircles();
    
    setState(() {
      _userCircles = circles;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Circles'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'create') {
                _navigateToCreateCircle();
              } else if (value == 'join') {
                _navigateToJoinCircle();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'create',
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline),
                    SizedBox(width: 8),
                    Text('Create Circle'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'join',
                child: Row(
                  children: [
                    Icon(Icons.group_add_outlined),
                    SizedBox(width: 8),
                    Text('Join Circle'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserCircles,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _userCircles.isEmpty
                ? _buildEmptyState()
                : _buildCirclesList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Circles Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first circle or join an existing one',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _navigateToCreateCircle,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Create Circle'),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _navigateToJoinCircle,
                icon: const Icon(Icons.group_add_outlined),
                label: const Text('Join Circle'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCirclesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userCircles.length,
      itemBuilder: (context, index) {
        final circle = _userCircles[index];
        return _buildCircleCard(circle);
      },
    );
  }

  Widget _buildCircleCard(Map<String, dynamic> circle) {
    final isCreator = circle['isCreator'] ?? false;
    final memberCount = circle['memberCount'] ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            circle['name']?.toString().substring(0, 1).toUpperCase() ?? 'C',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          circle['name'] ?? 'Unknown Circle',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '$memberCount member${memberCount != 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (isCreator) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Creator',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Joined ${_formatJoinDate(circle['joinedAt'])}',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleCircleAction(value, circle),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'switch',
              child: Row(
                children: [
                  Icon(Icons.switch_account_outlined),
                  SizedBox(width: 8),
                  Text('Switch to Circle'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 8),
                  Text('Circle Info'),
                ],
              ),
            ),
            if (!isCreator)
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Leave Circle', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
          ],
        ),
        onTap: () => _switchToCircle(circle),
      ),
    );
  }

  void _handleCircleAction(String action, Map<String, dynamic> circle) {
    switch (action) {
      case 'switch':
        _switchToCircle(circle);
        break;
      case 'info':
        _showCircleInfo(circle);
        break;
      case 'leave':
        _showLeaveCircleDialog(circle);
        break;
    }
  }

  void _switchToCircle(Map<String, dynamic> circle) {
    final circleController = context.read<CircleController>();
    
    // Find the full circle object
    final fullCircle = circleController.userCircles.firstWhere(
      (c) => c.id == circle['id'],
      orElse: () => throw Exception('Circle not found'),
    );
    
    circleController.selectCircle(fullCircle);
    
    // Navigate back to home
    Navigator.of(context).popUntil((route) => route.isFirst);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to ${circle['name']}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showCircleInfo(Map<String, dynamic> circle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(circle['name'] ?? 'Circle Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Members', '${circle['memberCount']}'),
            _buildInfoRow('Role', circle['isCreator'] ? 'Creator' : 'Member'),
            _buildInfoRow('Joined', _formatJoinDate(circle['joinedAt'])),
            _buildInfoRow('Circle ID', circle['id']),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showLeaveCircleDialog(Map<String, dynamic> circle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Circle'),
        content: Text(
          'Are you sure you want to leave "${circle['name']}"? You will need an invite code to rejoin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _leaveCircle(circle);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveCircle(Map<String, dynamic> circle) async {
    try {
      final circleController = context.read<CircleController>();
      await circleController.leaveCircle(circle['id']);
      
      // Refresh the list
      await _loadUserCircles();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Left ${circle['name']}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave circle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToCreateCircle() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateCircleScreen(),
      ),
    ).then((_) => _loadUserCircles());
  }

  void _navigateToJoinCircle() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const JoinCircleScreen(),
      ),
    ).then((_) => _loadUserCircles());
  }

  String _formatJoinDate(dynamic joinedAt) {
    if (joinedAt == null) return 'Unknown';
    
    try {
      DateTime date;
      if (joinedAt is DateTime) {
        date = joinedAt;
      } else {
        // Assume it's a Firestore Timestamp
        date = joinedAt.toDate();
      }
      
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays < 1) {
        return 'Today';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks week${weeks != 1 ? 's' : ''} ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months month${months != 1 ? 's' : ''} ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years year${years != 1 ? 's' : ''} ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}