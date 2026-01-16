import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/auth_service.dart';
import 'feed_controller.dart';
import 'feed_service.dart';
import 'post_model.dart';

class PostCommentsScreen extends StatefulWidget {
  final Post post;
  final String circleId;

  const PostCommentsScreen({
    super.key,
    required this.post,
    required this.circleId,
  });

  @override
  State<PostCommentsScreen> createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends State<PostCommentsScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  List<Comment> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadComments() {
    FeedService.instance
        .getPostComments(widget.circleId, widget.post.id)
        .listen((comments) {
      setState(() {
        _comments = comments;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.instance.currentUser;
    final isLiked = currentUser != null && widget.post.isLikedBy(currentUser.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
      ),
      body: Column(
        children: [
          // Original post
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      backgroundImage: widget.post.authorPhotoUrl != null
                          ? NetworkImage(widget.post.authorPhotoUrl!)
                          : null,
                      child: widget.post.authorPhotoUrl == null
                          ? Text(
                              widget.post.authorName.isNotEmpty 
                                  ? widget.post.authorName[0].toUpperCase() 
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.authorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _formatTime(widget.post.createdAt),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Post content
                Text(
                  widget.post.text,
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 8),

                // Post actions
                Row(
                  children: [
                    Consumer<FeedController>(
                      builder: (context, feedController, child) {
                        return InkWell(
                          onTap: () {
                            feedController.toggleLike(widget.circleId, widget.post.id);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: isLiked ? Colors.red : Colors.grey[600],
                                  size: 18,
                                ),
                                if (widget.post.likedBy.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.post.likedBy.length}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          color: Colors.grey[600],
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_comments.length}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Comments list
          Expanded(
            child: _comments.isEmpty
                ? const Center(
                    child: Text(
                      'No comments yet.\nBe the first to comment!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return CommentWidget(comment: comment);
                    },
                  ),
          ),

          // Comment input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
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
                  Consumer<FeedController>(
                    builder: (context, feedController, child) {
                      return IconButton(
                        onPressed: feedController.isLoading ? null : _handleComment,
                        icon: feedController.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
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

  Future<void> _handleComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final feedController = context.read<FeedController>();
    final success = await feedController.addComment(
      circleId: widget.circleId,
      postId: widget.post.id,
      text: _commentController.text.trim(),
    );

    if (success) {
      _commentController.clear();
      // Scroll to bottom to show new comment
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  String _formatTime(DateTime dateTime) {
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

class CommentWidget extends StatelessWidget {
  final Comment comment;

  const CommentWidget({
    super.key,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Theme.of(context).colorScheme.primary,
            backgroundImage: comment.authorPhotoUrl != null
                ? NetworkImage(comment.authorPhotoUrl!)
                : null,
            child: comment.authorPhotoUrl == null
                ? Text(
                    comment.authorName.isNotEmpty 
                        ? comment.authorName[0].toUpperCase() 
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(comment.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.text,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}