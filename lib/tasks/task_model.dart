import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}

enum TaskStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

class Task {
  final String id;
  final String circleId;
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final String createdBy;
  final String createdByName;
  final String? assignedTo;
  final String? assignedToName;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final String? completedBy;
  final String? completedByName;
  final List<String> tags;

  Task({
    required this.id,
    required this.circleId,
    required this.title,
    this.description,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    required this.createdBy,
    required this.createdByName,
    this.assignedTo,
    this.assignedToName,
    required this.createdAt,
    this.dueDate,
    this.completedAt,
    this.completedBy,
    this.completedByName,
    this.tags = const [],
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      circleId: data['circleId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => TaskPriority.medium,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TaskStatus.pending,
      ),
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'] ?? 'Unknown',
      assignedTo: data['assignedTo'],
      assignedToName: data['assignedToName'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      completedBy: data['completedBy'],
      completedByName: data['completedByName'],
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'circleId': circleId,
      'title': title,
      'description': description,
      'priority': priority.name,
      'status': status.name,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'completedBy': completedBy,
      'completedByName': completedByName,
      'tags': tags,
    };
  }

  Task copyWith({
    String? id,
    String? circleId,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    String? createdBy,
    String? createdByName,
    String? assignedTo,
    String? assignedToName,
    DateTime? createdAt,
    DateTime? dueDate,
    DateTime? completedAt,
    String? completedBy,
    String? completedByName,
    List<String>? tags,
  }) {
    return Task(
      id: id ?? this.id,
      circleId: circleId ?? this.circleId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      completedByName: completedByName ?? this.completedByName,
      tags: tags ?? this.tags,
    );
  }

  bool get isCompleted => status == TaskStatus.completed;
  bool get isOverdue => dueDate != null && 
                       !isCompleted && 
                       DateTime.now().isAfter(dueDate!);
  
  bool get isDueSoon => dueDate != null && 
                       !isCompleted && 
                       DateTime.now().difference(dueDate!).inDays.abs() <= 1;

  String get priorityDisplayName {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }
}

// Task activity/comment model
class TaskActivity {
  final String id;
  final String taskId;
  final String userId;
  final String userName;
  final String action; // 'created', 'completed', 'assigned', 'commented', etc.
  final String? comment;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata; // For storing additional data

  TaskActivity({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.userName,
    required this.action,
    this.comment,
    required this.createdAt,
    this.metadata,
  });

  factory TaskActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskActivity(
      id: doc.id,
      taskId: data['taskId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      action: data['action'] ?? '',
      comment: data['comment'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'taskId': taskId,
      'userId': userId,
      'userName': userName,
      'action': action,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }
}