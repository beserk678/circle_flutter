import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/auth_service.dart';
import 'task_controller.dart';
import 'task_service.dart';
import 'task_model.dart';
import 'create_task_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final String circleId;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.circleId,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _commentController = TextEditingController();
  List<TaskActivity> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _loadActivities() {
    TaskService.instance
        .getTaskActivities(widget.circleId, widget.task.id)
        .listen((activities) {
          setState(() {
            _activities = activities;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.instance.currentUser;
    final isCreator = currentUser?.uid == widget.task.createdBy;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          if (isCreator)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => CreateTaskScreen(
                            circleId: widget.circleId,
                            editTask: widget.task,
                          ),
                    ),
                  );
                } else if (value == 'delete') {
                  _confirmDeleteTask();
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Task'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Task'),
                    ),
                  ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Task details
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Task header
                Row(
                  children: [
                    Consumer<TaskController>(
                      builder: (context, taskController, child) {
                        return Checkbox(
                          value: widget.task.isCompleted,
                          onChanged: (value) {
                            taskController.toggleTaskCompletion(
                              widget.circleId,
                              widget.task.id,
                            );
                          },
                        );
                      },
                    ),
                    Expanded(
                      child: Text(
                        widget.task.title,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          decoration:
                              widget.task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Task description
                if (widget.task.description != null &&
                    widget.task.description!.isNotEmpty) ...[
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.task.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                ],

                // Task details
                _buildDetailCard(),
                const SizedBox(height: 16),

                // Activities
                Text(
                  'Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ..._activities.map((activity) => _buildActivityItem(activity)),
              ],
            ),
          ),

          // Comment input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer<TaskController>(
                    builder: (context, taskController, child) {
                      return IconButton(
                        onPressed:
                            taskController.isLoading ? null : _handleComment,
                        icon:
                            taskController.isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.send),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority
            Row(
              children: [
                const Icon(Icons.flag_outlined, size: 20),
                const SizedBox(width: 8),
                Text('Priority: '),
                Icon(
                  Icons.circle,
                  size: 12,
                  color: _getPriorityColor(widget.task.priority),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.task.priorityDisplayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Status
            Row(
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 8),
                Text('Status: '),
                Text(
                  widget.task.statusDisplayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.task.isCompleted ? Colors.green : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Created by
            Row(
              children: [
                const Icon(Icons.person_outline, size: 20),
                const SizedBox(width: 8),
                Text('Created by: '),
                Text(
                  widget.task.createdByName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Assigned to
            Row(
              children: [
                const Icon(Icons.assignment_ind_outlined, size: 20),
                const SizedBox(width: 8),
                Text('Assigned to: '),
                Text(
                  widget.task.assignedToName ?? 'Unassigned',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Due date
            if (widget.task.dueDate != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: widget.task.isOverdue ? Colors.red : null,
                  ),
                  const SizedBox(width: 8),
                  Text('Due date: '),
                  Text(
                    _formatDate(widget.task.dueDate!),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.task.isOverdue ? Colors.red : null,
                    ),
                  ),
                  if (widget.task.isOverdue && !widget.task.isCompleted) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.warning, color: Colors.red, size: 16),
                    const Text(' Overdue', style: TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Created date
            Row(
              children: [
                const Icon(Icons.schedule_outlined, size: 20),
                const SizedBox(width: 8),
                Text('Created: '),
                Text(
                  _formatDateTime(widget.task.createdAt),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            // Completed info
            if (widget.task.isCompleted && widget.task.completedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text('Completed by: '),
                  Text(
                    '${widget.task.completedByName} on ${_formatDateTime(widget.task.completedAt!)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(TaskActivity activity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              activity.userName.isNotEmpty
                  ? activity.userName[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: activity.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' ${_getActionText(activity.action)}'),
                    ],
                  ),
                ),
                if (activity.comment != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(activity.comment!),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  _formatDateTime(activity.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final taskController = context.read<TaskController>();
    final success = await taskController.addTaskComment(
      circleId: widget.circleId,
      taskId: widget.task.id,
      comment: _commentController.text.trim(),
    );

    if (success) {
      _commentController.clear();
    }
  }

  void _confirmDeleteTask() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: const Text(
              'Are you sure you want to delete this task? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  nav.pop();
                  final taskController = context.read<TaskController>();
                  final success = await taskController.deleteTask(
                    widget.circleId,
                    widget.task.id,
                  );
                  if (success && mounted) {
                    nav.pop();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Task deleted'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.urgent:
        return Colors.purple;
    }
  }

  String _getActionText(String action) {
    switch (action) {
      case 'created':
        return 'created this task';
      case 'completed':
        return 'completed this task';
      case 'reopened':
        return 'reopened this task';
      case 'commented':
        return 'commented:';
      case 'assigned':
        return 'was assigned to this task';
      default:
        return action;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
