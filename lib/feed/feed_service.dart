import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/services/auth_service.dart';
import '../notifications/notification_service.dart';
import '../circles/circle_service.dart';
import 'post_model.dart';

class FeedService {
  static final FeedService _instance = FeedService._internal();
  static FeedService get instance => _instance;
  FeedService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Create a new post
  Future<Post> createPost({
    required String circleId,
    required String text,
    String? mediaUrl,
    String? mediaType,
  }) async {
    final user = AuthService.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get user data for author info
    final userDoc = await AuthService.instance.getUserDocument(user.uid);
    final userData = userDoc.data() as Map<String, dynamic>?;

    final post = Post(
      id: _uuid.v4(),
      circleId: circleId,
      authorId: user.uid,
      authorName: userData?['displayName'] ?? 'Unknown',
      authorPhotoUrl: userData?['photoURL'],
      text: text,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('circles')
        .doc(circleId)
        .collection('posts')
        .doc(post.id)
        .set(post.toFirestore());

    // Send notification to other circle members
    try {
      final circle = await CircleService.instance.getCircleById(circleId);
      if (circle != null) {
        await NotificationService.instance.notifyNewPost(
          circleId: circleId,
          circleName: circle.name,
          memberIds: circle.members,
          authorName: post.authorName,
          postPreview:
              post.text.length > 50
                  ? '${post.text.substring(0, 50)}...'
                  : post.text,
          postId: post.id,
        );
      }
    } catch (e) {
      debugPrint('Failed to send post notification: $e');
    }

    return post;
  }

  // Get posts for a circle (real-time stream)
  Stream<List<Post>> getCirclePosts(String circleId, {int limit = 20}) {
    return _firestore
        .collection('circles')
        .doc(circleId)
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList(),
        );
  }

  // Get single post
  Future<Post?> getPost(String circleId, String postId) async {
    final doc =
        await _firestore
            .collection('circles')
            .doc(circleId)
            .collection('posts')
            .doc(postId)
            .get();

    if (!doc.exists) return null;
    return Post.fromFirestore(doc);
  }

  // Like/unlike a post
  Future<void> togglePostLike(
    String circleId,
    String postId,
    String userId,
  ) async {
    final postRef = _firestore
        .collection('circles')
        .doc(circleId)
        .collection('posts')
        .doc(postId);

    await _firestore.runTransaction((transaction) async {
      final postDoc = await transaction.get(postRef);
      if (!postDoc.exists) return;

      final post = Post.fromFirestore(postDoc);
      List<String> likedBy = List.from(post.likedBy);

      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }

      transaction.update(postRef, {'likedBy': likedBy});
    });
  }

  // Add comment to post
  Future<Comment> addComment({
    required String circleId,
    required String postId,
    required String text,
  }) async {
    final user = AuthService.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get user data for author info
    final userDoc = await AuthService.instance.getUserDocument(user.uid);
    final userData = userDoc.data() as Map<String, dynamic>?;

    final comment = Comment(
      id: _uuid.v4(),
      postId: postId,
      authorId: user.uid,
      authorName: userData?['displayName'] ?? 'Unknown',
      authorPhotoUrl: userData?['photoURL'],
      text: text,
      createdAt: DateTime.now(),
    );

    // Add comment and increment comment count
    await _firestore.runTransaction((transaction) async {
      final commentRef = _firestore
          .collection('circles')
          .doc(circleId)
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(comment.id);

      final postRef = _firestore
          .collection('circles')
          .doc(circleId)
          .collection('posts')
          .doc(postId);

      transaction.set(commentRef, comment.toFirestore());
      transaction.update(postRef, {'commentCount': FieldValue.increment(1)});
    });

    return comment;
  }

  // Get comments for a post
  Stream<List<Comment>> getPostComments(String circleId, String postId) {
    return _firestore
        .collection('circles')
        .doc(circleId)
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList(),
        );
  }

  // Delete post (only by author)
  Future<void> deletePost(String circleId, String postId, String userId) async {
    final post = await getPost(circleId, postId);
    if (post == null || post.authorId != userId) {
      throw Exception('Unauthorized to delete this post');
    }

    // Delete post and all its comments
    final batch = _firestore.batch();

    // Delete all comments
    final commentsSnapshot =
        await _firestore
            .collection('circles')
            .doc(circleId)
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .get();

    for (final doc in commentsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete the post
    batch.delete(
      _firestore
          .collection('circles')
          .doc(circleId)
          .collection('posts')
          .doc(postId),
    );

    await batch.commit();
  }
}
