import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import 'feed_service.dart';
import 'post_model.dart';

class FeedController extends ChangeNotifier {
  final FeedService _feedService = FeedService.instance;
  
  List<Post> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Initialize feed for a circle
  void initializeFeed(String circleId) {
    _feedService.getCirclePosts(circleId).listen(
      (posts) {
        _posts = posts;
        notifyListeners();
      },
      onError: (error) {
        _setError('Failed to load posts: $error');
      },
    );
  }

  // Create a new post
  Future<bool> createPost({
    required String circleId,
    required String text,
    String? mediaUrl,
    String? mediaType,
  }) async {
    if (text.trim().isEmpty) {
      _setError('Post text cannot be empty');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      await _feedService.createPost(
        circleId: circleId,
        text: text.trim(),
        mediaUrl: mediaUrl,
        mediaType: mediaType,
      );
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to create post: $e');
      _setLoading(false);
      return false;
    }
  }

  // Toggle like on a post
  Future<void> toggleLike(String circleId, String postId) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    try {
      await _feedService.togglePostLike(circleId, postId, user.uid);
    } catch (e) {
      _setError('Failed to update like: $e');
    }
  }

  // Add comment to a post
  Future<bool> addComment({
    required String circleId,
    required String postId,
    required String text,
  }) async {
    if (text.trim().isEmpty) {
      _setError('Comment cannot be empty');
      return false;
    }

    try {
      await _feedService.addComment(
        circleId: circleId,
        postId: postId,
        text: text.trim(),
      );
      return true;
    } catch (e) {
      _setError('Failed to add comment: $e');
      return false;
    }
  }

  // Delete a post
  Future<bool> deletePost(String circleId, String postId) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return false;

    try {
      await _feedService.deletePost(circleId, postId, user.uid);
      return true;
    } catch (e) {
      _setError('Failed to delete post: $e');
      return false;
    }
  }

  void clearError() {
    _setError(null);
  }
}