import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String circleId;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String text;
  final String? mediaUrl;
  final String? mediaType; // 'image' or 'video'
  final DateTime createdAt;
  final int commentCount;
  final List<String> likedBy;

  Post({
    required this.id,
    required this.circleId,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.text,
    this.mediaUrl,
    this.mediaType,
    required this.createdAt,
    this.commentCount = 0,
    this.likedBy = const [],
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      circleId: data['circleId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      authorPhotoUrl: data['authorPhotoUrl'],
      text: data['text'] ?? '',
      mediaUrl: data['mediaUrl'],
      mediaType: data['mediaType'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      commentCount: data['commentCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'circleId': circleId,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'text': text,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'createdAt': Timestamp.fromDate(createdAt),
      'commentCount': commentCount,
      'likedBy': likedBy,
    };
  }

  Post copyWith({
    String? id,
    String? circleId,
    String? authorId,
    String? authorName,
    String? authorPhotoUrl,
    String? text,
    String? mediaUrl,
    String? mediaType,
    DateTime? createdAt,
    int? commentCount,
    List<String>? likedBy,
  }) {
    return Post(
      id: id ?? this.id,
      circleId: circleId ?? this.circleId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      createdAt: createdAt ?? this.createdAt,
      commentCount: commentCount ?? this.commentCount,
      likedBy: likedBy ?? this.likedBy,
    );
  }

  bool isLikedBy(String userId) {
    return likedBy.contains(userId);
  }
}

class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      authorPhotoUrl: data['authorPhotoUrl'],
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}