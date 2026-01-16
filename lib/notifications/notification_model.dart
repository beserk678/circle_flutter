import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  newMessage,
  newPost,
  postComment,
  postLike,
  taskAssigned,
  taskCompleted,
  taskDue,
  fileUploaded,
  circleInvite,
  memberJoined,
  memberLeft,
  system,
}

class AppNotification {
  final String id;
  final String userId; // Who should receive this notification
  final String circleId;
  final String circleName;
  final NotificationType type;
  final String title;
  final String body;
  final String? actionUserId; // Who performed the action
  final String? actionUserName;
  final String? actionUserPhotoUrl;
  final String? relatedId; // ID of related post, task, message, etc.
  final Map<String, dynamic>? data; // Additional data
  final DateTime createdAt;
  final bool isRead;
  final bool isPushSent;

  AppNotification({
    required this.id,
    required this.userId,
    required this.circleId,
    required this.circleName,
    required this.type,
    required this.title,
    required this.body,
    this.actionUserId,
    this.actionUserName,
    this.actionUserPhotoUrl,
    this.relatedId,
    this.data,
    required this.createdAt,
    this.isRead = false,
    this.isPushSent = false,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      circleId: data['circleId'] ?? '',
      circleName: data['circleName'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.system,
      ),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      actionUserId: data['actionUserId'],
      actionUserName: data['actionUserName'],
      actionUserPhotoUrl: data['actionUserPhotoUrl'],
      relatedId: data['relatedId'],
      data: data['data'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      isPushSent: data['isPushSent'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'circleId': circleId,
      'circleName': circleName,
      'type': type.name,
      'title': title,
      'body': body,
      'actionUserId': actionUserId,
      'actionUserName': actionUserName,
      'actionUserPhotoUrl': actionUserPhotoUrl,
      'relatedId': relatedId,
      'data': data,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'isPushSent': isPushSent,
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? circleId,
    String? circleName,
    NotificationType? type,
    String? title,
    String? body,
    String? actionUserId,
    String? actionUserName,
    String? actionUserPhotoUrl,
    String? relatedId,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
    bool? isPushSent,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      circleId: circleId ?? this.circleId,
      circleName: circleName ?? this.circleName,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      actionUserId: actionUserId ?? this.actionUserId,
      actionUserName: actionUserName ?? this.actionUserName,
      actionUserPhotoUrl: actionUserPhotoUrl ?? this.actionUserPhotoUrl,
      relatedId: relatedId ?? this.relatedId,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isPushSent: isPushSent ?? this.isPushSent,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case NotificationType.newMessage:
        return 'New Message';
      case NotificationType.newPost:
        return 'New Post';
      case NotificationType.postComment:
        return 'Comment';
      case NotificationType.postLike:
        return 'Like';
      case NotificationType.taskAssigned:
        return 'Task Assigned';
      case NotificationType.taskCompleted:
        return 'Task Completed';
      case NotificationType.taskDue:
        return 'Task Due';
      case NotificationType.fileUploaded:
        return 'File Uploaded';
      case NotificationType.circleInvite:
        return 'Circle Invite';
      case NotificationType.memberJoined:
        return 'Member Joined';
      case NotificationType.memberLeft:
        return 'Member Left';
      case NotificationType.system:
        return 'System';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}

// Notification preferences model
class NotificationPreferences {
  final String userId;
  final bool pushNotifications;
  final bool newMessages;
  final bool newPosts;
  final bool postComments;
  final bool postLikes;
  final bool taskAssignments;
  final bool taskReminders;
  final bool fileUploads;
  final bool circleActivity;
  final String quietHoursStart; // "22:00"
  final String quietHoursEnd; // "08:00"
  final bool quietHoursEnabled;

  NotificationPreferences({
    required this.userId,
    this.pushNotifications = true,
    this.newMessages = true,
    this.newPosts = true,
    this.postComments = true,
    this.postLikes = false, // Usually less important
    this.taskAssignments = true,
    this.taskReminders = true,
    this.fileUploads = true,
    this.circleActivity = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
    this.quietHoursEnabled = false,
  });

  factory NotificationPreferences.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NotificationPreferences(
      userId: doc.id,
      pushNotifications: data['pushNotifications'] ?? true,
      newMessages: data['newMessages'] ?? true,
      newPosts: data['newPosts'] ?? true,
      postComments: data['postComments'] ?? true,
      postLikes: data['postLikes'] ?? false,
      taskAssignments: data['taskAssignments'] ?? true,
      taskReminders: data['taskReminders'] ?? true,
      fileUploads: data['fileUploads'] ?? true,
      circleActivity: data['circleActivity'] ?? true,
      quietHoursStart: data['quietHoursStart'] ?? '22:00',
      quietHoursEnd: data['quietHoursEnd'] ?? '08:00',
      quietHoursEnabled: data['quietHoursEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'pushNotifications': pushNotifications,
      'newMessages': newMessages,
      'newPosts': newPosts,
      'postComments': postComments,
      'postLikes': postLikes,
      'taskAssignments': taskAssignments,
      'taskReminders': taskReminders,
      'fileUploads': fileUploads,
      'circleActivity': circleActivity,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'quietHoursEnabled': quietHoursEnabled,
    };
  }

  bool shouldNotify(NotificationType type) {
    if (!pushNotifications) return false;

    switch (type) {
      case NotificationType.newMessage:
        return newMessages;
      case NotificationType.newPost:
        return newPosts;
      case NotificationType.postComment:
        return postComments;
      case NotificationType.postLike:
        return postLikes;
      case NotificationType.taskAssigned:
      case NotificationType.taskCompleted:
        return taskAssignments;
      case NotificationType.taskDue:
        return taskReminders;
      case NotificationType.fileUploaded:
        return fileUploads;
      case NotificationType.circleInvite:
      case NotificationType.memberJoined:
      case NotificationType.memberLeft:
        return circleActivity;
      case NotificationType.system:
        return true; // Always notify for system messages
    }
  }
}