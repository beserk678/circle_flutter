import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  file,
  system, // For system messages like "User joined the circle"
}

class Message {
  final String id;
  final String circleId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final String? mediaUrl;
  final String? fileName;
  final int? fileSize;
  final List<String> readBy; // UIDs of users who have read this message

  Message({
    required this.id,
    required this.circleId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.content,
    required this.type,
    required this.createdAt,
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    this.readBy = const [],
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      circleId: data['circleId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      senderPhotoUrl: data['senderPhotoUrl'],
      content: data['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mediaUrl: data['mediaUrl'],
      fileName: data['fileName'],
      fileSize: data['fileSize'],
      readBy: List<String>.from(data['readBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'circleId': circleId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'content': content,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'readBy': readBy,
    };
  }

  Message copyWith({
    String? id,
    String? circleId,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? content,
    MessageType? type,
    DateTime? createdAt,
    String? mediaUrl,
    String? fileName,
    int? fileSize,
    List<String>? readBy,
  }) {
    return Message(
      id: id ?? this.id,
      circleId: circleId ?? this.circleId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      readBy: readBy ?? this.readBy,
    );
  }

  bool isReadBy(String userId) {
    return readBy.contains(userId);
  }

  bool get isSystemMessage => type == MessageType.system;
}

// Typing indicator model
class TypingIndicator {
  final String userId;
  final String userName;
  final DateTime lastTyping;

  TypingIndicator({
    required this.userId,
    required this.userName,
    required this.lastTyping,
  });

  factory TypingIndicator.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TypingIndicator(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      lastTyping: (data['lastTyping'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'lastTyping': Timestamp.fromDate(lastTyping),
    };
  }

  bool get isActive {
    return DateTime.now().difference(lastTyping).inSeconds < 5;
  }
}