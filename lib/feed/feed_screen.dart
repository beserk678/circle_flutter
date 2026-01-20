import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/auth_service.dart';
import '../core/widgets/empty_state_widgets.dart';
import '../core/widgets/enhanced_widgets.dart';
import '../core/widgets/loading_widgets.dart';
import '../core/utils/performance_utils.dart';
import '../circles/circle_controller.dart';
import 'feed_controller.dart';
import 'post_model.dart';
import 'create_post_screen.dart';
import 'post_comments_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _debouncer = Debouncer(milliseconds: 300);
  String? _currentCircleId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFeedIfNeeded();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeFeedIfNeeded();
  }

  void _initializeFeedIfNeeded() {
    final circleController = context.read<CircleController>();
    final feedController = context.read<FeedController>();
    final selectedCircleId = circleController.selectedCircle?.id;

    // Only initialize if circle has changed
    if (selectedCircleId != null && selectedCircleId != _currentCircleId) {
      _currentCircleId = selectedCircleId;
      feedController.initializeFeed(selectedCircleId);
    }
  }

  @override
  void dispose() {
    _debouncer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CircleController, FeedController>(
      builder: (context, circleController, feedController, child) {
        final selectedCircle = circleController.selectedCircle;

        print('FeedScreen - selectedCircle: ${selectedCircle?.name}');

        if (selectedCircle == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No circle selected',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomRefreshIndicator(
            onRefresh: () async {
              _debouncer.run(() {
                feedController.initializeFeed(selectedCircle.id);
              });
            },
            child:
                feedController.isLoading && feedController.posts.isEmpty
                    ? const Center(
                      child: LoadingIndicator(message: 'Loading posts...'),
                    )
                    : feedController.posts.isEmpty
                    ? EmptyFeedState(
                      onCreatePost:
                          () => _navigateToCreatePost(selectedCircle.id),
                    )
                    : OptimizedListView(
                      itemCount: feedController.posts.length,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemBuilder: (context, index) {
                        final post = feedController.posts[index];
                        return AnimatedListItem(
                          index: index,
                          child: PostWidget(
                            post: post,
                            circleId: selectedCircle.id,
                          ),
                        );
                      },
                    ),
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
              onPressed: () => _navigateToCreatePost(selectedCircle.id),
              backgroundColor: Colors.transparent,
              elevation: 0,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'New Post',
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

  void _navigateToCreatePost(String circleId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(circleId: circleId),
      ),
    );
  }
}

class PostWidget extends StatelessWidget {
  final Post post;
  final String circleId;

  const PostWidget({super.key, required this.post, required this.circleId});

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.instance.currentUser;
    final isLiked = currentUser != null && post.isLikedBy(currentUser.uid);
    final isAuthor = currentUser?.uid == post.authorId;

    return EnhancedCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              StatusAvatar(
                imageUrl: post.authorPhotoUrl,
                initials:
                    post.authorName.isNotEmpty
                        ? post.authorName[0].toUpperCase()
                        : 'U',
                radius: 20,
                showStatus: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      TextUtils.formatTimeAgo(post.createdAt),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isAuthor)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _confirmDelete(context);
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Content
          Text(post.text, style: const TextStyle(fontSize: 16)),

          // Media (if any)
          if (post.mediaUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                post.mediaUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: Colors.grey[100],
                    child: const Center(child: LoadingIndicator(size: 32)),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(child: Icon(Icons.error_outline)),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              // Like button
              Consumer<FeedController>(
                builder: (context, feedController, child) {
                  return InkWell(
                    onTap: () {
                      feedController.toggleLike(circleId, post.id);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.grey[600],
                            size: 20,
                          ),
                          if (post.likedBy.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            AnimatedCounter(
                              count: post.likedBy.length,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Comment button
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => PostCommentsScreen(
                            post: post,
                            circleId: circleId,
                          ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      if (post.commentCount > 0) ...[
                        const SizedBox(width: 4),
                        AnimatedCounter(
                          count: post.commentCount,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Post'),
            content: const Text('Are you sure you want to delete this post?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final feedController = context.read<FeedController>();
                  final success = await feedController.deletePost(
                    circleId,
                    post.id,
                  );
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Post deleted'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
