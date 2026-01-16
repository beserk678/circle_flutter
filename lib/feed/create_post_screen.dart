import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'feed_controller.dart';

class CreatePostScreen extends StatefulWidget {
  final String circleId;

  const CreatePostScreen({super.key, required this.circleId});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Create Post',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF6366F1)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Consumer<FeedController>(
              builder: (context, feedController, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient:
                        feedController.isLoading
                            ? null
                            : const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                    color:
                        feedController.isLoading
                            ? const Color(0xFFE5E7EB)
                            : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    onPressed: feedController.isLoading ? null : _handlePost,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        feedController.isLoading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text(
                              'Post',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Consumer<FeedController>(
        builder: (context, feedController, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Text input
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText: 'What\'s on your mind?',
                        hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ),

                // Error message
                if (feedController.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      feedController.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],

                // Media options (placeholder for future)
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.photo_outlined, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Photo & video support coming soon',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handlePost() async {
    final feedController = context.read<FeedController>();
    final success = await feedController.createPost(
      circleId: widget.circleId,
      text: _textController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
