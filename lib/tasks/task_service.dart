import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/services/auth_service.dart';
import '../notifications/notification_service.dart';
import '../circles/circle_service.dart';
import 'task_model.dart';

class TaskService {
  static final TaskService _instance = TaskService._internal();
  static TaskService get instance => _instance;
  TaskService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Create a new task
  Future<Task> createTask({
    required String circleId,
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    String? assignedTo,
    DateTime? dueDate,
    List<String> tags = const [],
  }) async {
    final user = AuthService.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get user data for creator info
    final userDoc = await AuthService.instance.getUserDocument(user.uid);
    final userData = userDoc.data() as Map<String, dynamic>?;

    // Get assigned user info if provided
    String? assignedToName;
    if (assignedTo != null) {
      final assignedUserDoc = await AuthService.instance.getUserDocument(
        assignedTo,
      );
      final assignedUserData = assignedUserDoc.data() as Map<String, dynamic>?;
      assignedToName = assignedUserData?['displayName'] ?? 'Unknown';
    }

    final task = Task(
      id: _uuid.v4(),
      circleId: circleId,
      title: title,
      description: description,
      priority: priority,
      createdBy: user.uid,
      createdByName: userData?['displayName'] ?? 'Unknown',
      assignedTo: assignedTo,
      assignedToName: assignedToName,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      tags: tags,
    );

    await _firestore
        .collection('circles')
        .doc(circleId)
        .collection('tasks')
        .doc(task.id)
        .set(task.toFirestore());

    // Add activity log
    await _addTaskActivity(
      taskId: task.id,
      circleId: circleId,
      action: 'created',
      userId: user.uid,
      userName: userData?['displayName'] ?? 'Unknown',
    );

    // Send notification if task is assigned
    if (assignedTo != null && assignedTo != user.uid) {
      try {
        final circle = await CircleService.instance.getCircleById(circleId);
        if (circle != null) {
          await NotificationService.instance.notifyTaskAssigned(
            assigneeId: assignedTo,
            circleId: circleId,
            circleName: circle.name,
            taskTitle: task.title,
            assignerName: userData?['displayName'] ?? 'Unknown',
            taskId: task.id,
          );
        }
      } catch (e) {
        debugPrint('Failed to send task assignment notification: $e');
      }
    }

    return task;
  }

  // Get tasks for a circle (real-time stream)
  Stream<List<Task>> getCircleTasks(
    String circleId, {
    TaskStatus? filterStatus,
  }) {
    Query query = _firestore
        .collection('circles')
        .doc(circleId)
        .collection('tasks')
        .orderBy('createdAt', descending: true);

    if (filterStatus != null) {
      query = query.where('status', isEqualTo: filterStatus.name);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList(),
    );
  }

  // Get single task
  Future<Task?> getTask(String circleId, String taskId) async {
    final doc =
        await _firestore
            .collection('circles')
            .doc(circleId)
            .collection('tasks')
            .doc(taskId)
            .get();

    if (!doc.exists) return null;
    return Task.fromFirestore(doc);
  }

  // Update task
  Future<Task> updateTask({
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
    final user = AuthService.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final taskRef = _firestore
        .collection('circles')
        .doc(circleId)
        .collection('tasks')
        .doc(taskId);

    final updates = <String, dynamic>{};

    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (priority != null) updates['priority'] = priority.name;
    if (status != null) updates['status'] = status.name;
    if (dueDate != null) updates['dueDate'] = Timestamp.fromDate(dueDate);
    if (tags != null) updates['tags'] = tags;

    // Handle assignment
    if (assignedTo != null) {
      final assignedUserDoc = await AuthService.instance.getUserDocument(
        assignedTo,
      );
      final assignedUserData = assignedUserDoc.data() as Map<String, dynamic>?;
      updates['assignedTo'] = assignedTo;
      updates['assignedToName'] = assignedUserData?['displayName'] ?? 'Unknown';
    }

    await taskRef.update(updates);

    // Get updated task
    final updatedTask = await getTask(circleId, taskId);
    if (updatedTask == null) throw Exception('Task not found after update');

    return updatedTask;
  }

  // Complete/uncomplete task
  Future<Task> toggleTaskCompletion(String circleId, String taskId) async {
    final user = AuthService.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final task = await getTask(circleId, taskId);
    if (task == null) throw Exception('Task not found');

    // Get user data
    final userDoc = await AuthService.instance.getUserDocument(user.uid);
    final userData = userDoc.data() as Map<String, dynamic>?;
    final userName = userData?['displayName'] ?? 'Unknown';

    final isCompleting = !task.isCompleted;
    final updates = <String, dynamic>{
      'status':
          isCompleting ? TaskStatus.completed.name : TaskStatus.pending.name,
    };

    if (isCompleting) {
      updates['completedAt'] = Timestamp.fromDate(DateTime.now());
      updates['completedBy'] = user.uid;
      updates['completedByName'] = userName;
    } else {
      updates['completedAt'] = null;
      updates['completedBy'] = null;
      updates['completedByName'] = null;
    }

    await _firestore
        .collection('circles')
        .doc(circleId)
        .collection('tasks')
        .doc(taskId)
        .update(updates);

    // Add activity log
    await _addTaskActivity(
      taskId: taskId,
      circleId: circleId,
      action: isCompleting ? 'completed' : 'reopened',
      userId: user.uid,
      userName: userName,
    );

    final updatedTask = await getTask(circleId, taskId);
    if (updatedTask == null) throw Exception('Task not found after update');

    return updatedTask;
  }

  // Delete task
  Future<void> deleteTask(String circleId, String taskId, String userId) async {
    final task = await getTask(circleId, taskId);
    if (task == null) return;

    // Only creator can delete task
    if (task.createdBy != userId) {
      throw Exception('Only the task creator can delete this task');
    }

    // Delete task and all its activities
    final batch = _firestore.batch();

    // Delete all activities
    final activitiesSnapshot =
        await _firestore
            .collection('circles')
            .doc(circleId)
            .collection('tasks')
            .doc(taskId)
            .collection('activities')
            .get();

    for (final doc in activitiesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete the task
    batch.delete(
      _firestore
          .collection('circles')
          .doc(circleId)
          .collection('tasks')
          .doc(taskId),
    );

    await batch.commit();
  }

  // Get task activities
  Stream<List<TaskActivity>> getTaskActivities(String circleId, String taskId) {
    return _firestore
        .collection('circles')
        .doc(circleId)
        .collection('tasks')
        .doc(taskId)
        .collection('activities')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => TaskActivity.fromFirestore(doc))
                  .toList(),
        );
  }

  // Add task activity/comment
  Future<void> addTaskComment({
    required String circleId,
    required String taskId,
    required String comment,
  }) async {
    final user = AuthService.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final userDoc = await AuthService.instance.getUserDocument(user.uid);
    final userData = userDoc.data() as Map<String, dynamic>?;

    await _addTaskActivity(
      taskId: taskId,
      circleId: circleId,
      action: 'commented',
      userId: user.uid,
      userName: userData?['displayName'] ?? 'Unknown',
      comment: comment,
    );
  }

  // Private method to add task activity
  Future<void> _addTaskActivity({
    required String taskId,
    required String circleId,
    required String action,
    required String userId,
    required String userName,
    String? comment,
    Map<String, dynamic>? metadata,
  }) async {
    final activity = TaskActivity(
      id: _uuid.v4(),
      taskId: taskId,
      userId: userId,
      userName: userName,
      action: action,
      comment: comment,
      createdAt: DateTime.now(),
      metadata: metadata,
    );

    await _firestore
        .collection('circles')
        .doc(circleId)
        .collection('tasks')
        .doc(taskId)
        .collection('activities')
        .doc(activity.id)
        .set(activity.toFirestore());
  }

  // Get tasks assigned to a specific user
  Stream<List<Task>> getUserAssignedTasks(String circleId, String userId) {
    return _firestore
        .collection('circles')
        .doc(circleId)
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        .where('status', isNotEqualTo: TaskStatus.completed.name)
        .orderBy('dueDate')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList(),
        );
  }

  // Get task statistics for a circle
  Future<Map<String, int>> getTaskStats(String circleId) async {
    final snapshot =
        await _firestore
            .collection('circles')
            .doc(circleId)
            .collection('tasks')
            .get();

    final tasks = snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();

    return {
      'total': tasks.length,
      'completed': tasks.where((t) => t.isCompleted).length,
      'pending': tasks.where((t) => t.status == TaskStatus.pending).length,
      'inProgress':
          tasks.where((t) => t.status == TaskStatus.inProgress).length,
      'overdue': tasks.where((t) => t.isOverdue).length,
    };
  }
}
