import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import 'task_service.dart';
import 'task_model.dart';

class TaskController extends ChangeNotifier {
  final TaskService _taskService = TaskService.instance;
  
  List<Task> _tasks = [];
  TaskStatus? _filterStatus;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, int> _taskStats = {};

  List<Task> get tasks => _tasks;
  TaskStatus? get filterStatus => _filterStatus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, int> get taskStats => _taskStats;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Initialize tasks for a circle
  void initializeTasks(String circleId) {
    _taskService.getCircleTasks(circleId, filterStatus: _filterStatus).listen(
      (tasks) {
        _tasks = tasks;
        notifyListeners();
      },
      onError: (error) {
        _setError('Failed to load tasks: $error');
      },
    );

    // Load task statistics
    _loadTaskStats(circleId);
  }

  // Load task statistics
  Future<void> _loadTaskStats(String circleId) async {
    try {
      _taskStats = await _taskService.getTaskStats(circleId);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load task stats: $e');
    }
  }

  // Create a new task
  Future<bool> createTask({
    required String circleId,
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    String? assignedTo,
    DateTime? dueDate,
    List<String> tags = const [],
  }) async {
    if (title.trim().isEmpty) {
      _setError('Task title cannot be empty');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      await _taskService.createTask(
        circleId: circleId,
        title: title.trim(),
        description: description?.trim(),
        priority: priority,
        assignedTo: assignedTo,
        dueDate: dueDate,
        tags: tags,
      );
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to create task: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update a task
  Future<bool> updateTask({
    required String circleId,
    required String taskId,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    String? assignedTo,
    DateTime? dueDate,
    List<String>? tags,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await _taskService.updateTask(
        circleId: circleId,
        taskId: taskId,
        title: title?.trim(),
        description: description?.trim(),
        priority: priority,
        status: status,
        assignedTo: assignedTo,
        dueDate: dueDate,
        tags: tags,
      );
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update task: $e');
      _setLoading(false);
      return false;
    }
  }

  // Toggle task completion
  Future<bool> toggleTaskCompletion(String circleId, String taskId) async {
    try {
      await _taskService.toggleTaskCompletion(circleId, taskId);
      return true;
    } catch (e) {
      _setError('Failed to update task: $e');
      return false;
    }
  }

  // Delete a task
  Future<bool> deleteTask(String circleId, String taskId) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return false;

    try {
      await _taskService.deleteTask(circleId, taskId, user.uid);
      return true;
    } catch (e) {
      _setError('Failed to delete task: $e');
      return false;
    }
  }

  // Add comment to task
  Future<bool> addTaskComment({
    required String circleId,
    required String taskId,
    required String comment,
  }) async {
    if (comment.trim().isEmpty) {
      _setError('Comment cannot be empty');
      return false;
    }

    try {
      await _taskService.addTaskComment(
        circleId: circleId,
        taskId: taskId,
        comment: comment.trim(),
      );
      return true;
    } catch (e) {
      _setError('Failed to add comment: $e');
      return false;
    }
  }

  // Set filter status
  void setFilterStatus(TaskStatus? status, String circleId) {
    if (_filterStatus != status) {
      _filterStatus = status;
      initializeTasks(circleId); // Reload with new filter
    }
  }

  // Get filtered tasks
  List<Task> getFilteredTasks() {
    if (_filterStatus == null) return _tasks;
    return _tasks.where((task) => task.status == _filterStatus).toList();
  }

  void clearError() {
    _setError(null);
  }
}