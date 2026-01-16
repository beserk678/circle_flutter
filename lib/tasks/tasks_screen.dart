import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';
import '../core/services/auth_service.dart';
import '../core/widgets/empty_state_widgets.dart';
import '../core/widgets/enhanced_widgets.dart';
import '../core/widgets/loading_widgets.dart';
import '../core/utils/performance_utils.dart';
import '../circles/circle_controller.dart';
import 'task_controller.dart';
import 'task_model.dart';
import 'create_task_screen.dart';
import 'task_detail_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _debouncer = Debouncer(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final circleController = context.read<CircleController>();
      final taskController = context.read<TaskController>();

      if (circleController.selectedCircle != null) {
        taskController.initializeTasks(circleController.selectedCircle!.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _debouncer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CircleController, TaskController>(
      builder: (context, circleController, taskController, child) {
        final selectedCircle = circleController.selectedCircle;

        if (selectedCircle == null) {
          return const Center(child: Text('No circle selected'));
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: Column(
            children: [
              // Task stats
              if (taskController.taskStats.isNotEmpty)
                _buildTaskStats(taskController.taskStats),

              // Tab bar
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Pending'),
                  Tab(text: 'In Progress'),
                  Tab(text: 'Completed'),
                ],
                onTap: (index) {
                  _debouncer.run(() {
                    TaskStatus? filterStatus;
                    switch (index) {
                      case 1:
                        filterStatus = TaskStatus.pending;
                        break;
                      case 2:
                        filterStatus = TaskStatus.inProgress;
                        break;
                      case 3:
                        filterStatus = TaskStatus.completed;
                        break;
                    }
                    taskController.setFilterStatus(
                      filterStatus,
                      selectedCircle.id,
                    );
                  });
                },
              ),

              // Task list
              Expanded(
                child:
                    taskController.isLoading && taskController.tasks.isEmpty
                        ? const Center(
                          child: LoadingIndicator(message: 'Loading tasks...'),
                        )
                        : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildTaskList(taskController.tasks, 'all'),
                            _buildTaskList(
                              taskController.tasks
                                  .where((t) => t.status == TaskStatus.pending)
                                  .toList(),
                              'pending',
                            ),
                            _buildTaskList(
                              taskController.tasks
                                  .where(
                                    (t) => t.status == TaskStatus.inProgress,
                                  )
                                  .toList(),
                              'inProgress',
                            ),
                            _buildTaskList(
                              taskController.tasks
                                  .where(
                                    (t) => t.status == TaskStatus.completed,
                                  )
                                  .toList(),
                              'completed',
                            ),
                          ],
                        ),
              ),
            ],
          ),
          floatingActionButton: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            CreateTaskScreen(circleId: selectedCircle.id),
                  ),
                );
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'New Task',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskStats(Map<String, int> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              stats['total'] ?? 0,
              Colors.blue,
              Icons.task_outlined,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Pending',
              stats['pending'] ?? 0,
              Colors.orange,
              Icons.pending_outlined,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Completed',
              stats['completed'] ?? 0,
              Colors.green,
              Icons.check_circle_outline,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Overdue',
              stats['overdue'] ?? 0,
              Colors.red,
              Icons.warning_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return EnhancedCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          AnimatedCounter(
            count: count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, String tabType) {
    if (tasks.isEmpty) {
      return EmptyTasksState(
        onCreateTask: () {
          final selectedCircle =
              context.read<CircleController>().selectedCircle;
          if (selectedCircle != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => CreateTaskScreen(circleId: selectedCircle.id),
              ),
            );
          }
        },
      );
    }

    return OptimizedListView(
      itemCount: tasks.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return AnimatedListItem(
          index: index,
          child: TaskTile(
            task: task,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => TaskDetailScreen(
                        task: task,
                        circleId:
                            context.read<CircleController>().selectedCircle!.id,
                      ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const TaskTile({super.key, required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.instance.currentUser;
    final isAssignedToMe = currentUser?.uid == task.assignedTo;

    return EnhancedCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Consumer<TaskController>(
          builder: (context, taskController, child) {
            return Checkbox(
              value: task.isCompleted,
              onChanged: (value) {
                final circleController = context.read<CircleController>();
                if (circleController.selectedCircle != null) {
                  taskController.toggleTaskCompletion(
                    circleController.selectedCircle!.id,
                    task.id,
                  );
                }
              },
            );
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty) ...[
              Text(
                task.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: task.isCompleted ? Colors.grey : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                // Priority indicator
                Icon(
                  Icons.circle,
                  size: 12,
                  color: _getPriorityColor(task.priority),
                ),
                const SizedBox(width: 4),
                Text(
                  task.priorityDisplayName,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (task.assignedToName != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.person,
                    size: 12,
                    color: isAssignedToMe ? Colors.blue : Colors.grey[600],
                  ),
                  const SizedBox(width: 2),
                  Text(
                    task.assignedToName!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isAssignedToMe ? Colors.blue : Colors.grey[600],
                      fontWeight:
                          isAssignedToMe ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
                if (task.dueDate != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: task.isOverdue ? Colors.red : Colors.grey[600],
                  ),
                  const SizedBox(width: 2),
                  Text(
                    _formatDate(task.dueDate!),
                    style: TextStyle(
                      fontSize: 12,
                      color: task.isOverdue ? Colors.red : Colors.grey[600],
                      fontWeight:
                          task.isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing:
            task.isOverdue && !task.isCompleted
                ? Badge(
                  text: 'Overdue',
                  color: Colors.red.withValues(alpha: 0.1),
                  textColor: Colors.red,
                )
                : task.isDueSoon && !task.isCompleted
                ? Badge(
                  text: 'Due Soon',
                  color: Colors.orange.withValues(alpha: 0.1),
                  textColor: Colors.orange,
                )
                : null,
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return 'Today';
    } else if (taskDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (taskDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
