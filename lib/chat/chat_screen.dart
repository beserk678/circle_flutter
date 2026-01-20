import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/auth_service.dart';
import '../core/utils/performance_utils.dart';
import '../circles/circle_controller.dart';
import 'chat_controller.dart';
import 'message_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _debouncer = Debouncer(milliseconds: 300);
  bool _isComposing = false;
  String? _currentCircleId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChatIfNeeded();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeChatIfNeeded();
  }

  void _initializeChatIfNeeded() {
    final circleController = context.read<CircleController>();
    final chatController = context.read<ChatController>();
    final selectedCircleId = circleController.selectedCircle?.id;

    // Only initialize if circle has changed
    if (selectedCircleId != null && selectedCircleId != _currentCircleId) {
      _currentCircleId = selectedCircleId;
      chatController.initializeChat(selectedCircleId);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _debouncer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CircleController, ChatController>(
      builder: (context, circleController, chatController, child) {
        final selectedCircle = circleController.selectedCircle;

        if (selectedCircle == null) {
          return const Center(child: Text('No circle selected'));
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Column(
            children: [
              // Messages list
              Expanded(
                child:
                    chatController.messages.isEmpty
                        ? _buildEmptyState(context)
                        : Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                          ),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            itemCount: chatController.messages.length,
                            itemBuilder: (context, index) {
                              final message = chatController.messages[index];
                              final isLastMessage =
                                  index == chatController.messages.length - 1;

                              return MessageBubble(
                                message: message,
                                circleId: selectedCircle.id,
                                showAvatar: _shouldShowAvatar(
                                  chatController.messages,
                                  index,
                                ),
                                isLastMessage: isLastMessage,
                              );
                            },
                          ),
                        ),
              ),

              // Typing indicators
              if (chatController.typingIndicators.isNotEmpty)
                _buildTypingIndicators(chatController.typingIndicators),

              // Message input
              _buildMessageInput(context, selectedCircle.id, chatController),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.chat_outlined,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation with your circle!',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicators(List<TypingIndicator> indicators) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            indicators.length == 1
                ? '${indicators.first.userName} is typing...'
                : '${indicators.length} people are typing...',
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(
    BuildContext context,
    String circleId,
    ChatController chatController,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1F2937)
                          : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF374151)
                            : const Color(0xFFE5E7EB),
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (text) {
                    final isComposing = text.trim().isNotEmpty;
                    if (isComposing != _isComposing) {
                      setState(() {
                        _isComposing = isComposing;
                      });
                    }

                    // Send typing indicator
                    if (isComposing) {
                      chatController.sendTypingIndicator(circleId);
                    } else {
                      chatController.stopTypingIndicator(circleId);
                    }
                  },
                  onSubmitted:
                      (_) => _handleSendMessage(circleId, chatController),
                ),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient:
                      _isComposing && !chatController.isLoading
                          ? const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                          : null,
                  color:
                      !_isComposing || chatController.isLoading
                          ? (Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF374151)
                              : const Color(0xFFE5E7EB))
                          : null,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  onPressed:
                      _isComposing && !chatController.isLoading
                          ? () => _handleSendMessage(circleId, chatController)
                          : null,
                  icon:
                      chatController.isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Icon(
                            Icons.send,
                            color:
                                _isComposing
                                    ? Colors.white
                                    : (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFF6B7280)
                                        : const Color(0xFF9CA3AF)),
                            size: 20,
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSendMessage(
    String circleId,
    ChatController chatController,
  ) async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();
    setState(() {
      _isComposing = false;
    });

    final success = await chatController.sendMessage(
      circleId: circleId,
      content: message,
    );

    if (success) {
      // Scroll to bottom to show new message
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

  bool _shouldShowAvatar(List<Message> messages, int index) {
    if (index == messages.length - 1) {
      return true; // Last message always shows avatar
    }

    final currentMessage = messages[index];
    final nextMessage = messages[index + 1];

    // Show avatar if next message is from different sender
    return currentMessage.senderId != nextMessage.senderId;
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;
  final String circleId;
  final bool showAvatar;
  final bool isLastMessage;

  const MessageBubble({
    super.key,
    required this.message,
    required this.circleId,
    required this.showAvatar,
    required this.isLastMessage,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.instance.currentUser;
    final isMe = currentUser?.uid == message.senderId;
    final isSystem = message.isSystemMessage;

    if (isSystem) {
      return _buildSystemMessage(context);
    }

    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 64 : 16,
        right: isMe ? 16 : 64,
        top: 2,
        bottom: showAvatar ? 8 : 2,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar (for others' messages)
          if (!isMe && showAvatar) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              backgroundImage:
                  message.senderPhotoUrl != null
                      ? NetworkImage(message.senderPhotoUrl!)
                      : null,
              child:
                  message.senderPhotoUrl == null
                      ? Text(
                        message.senderName.isNotEmpty
                            ? message.senderName[0].toUpperCase()
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
          ] else if (!isMe) ...[
            const SizedBox(width: 40), // Space for avatar alignment
          ],

          // Message bubble
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient:
                      isMe
                          ? const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                          : null,
                  color: isMe ? null : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20).copyWith(
                    bottomLeft: Radius.circular(!isMe && showAvatar ? 4 : 20),
                    bottomRight: Radius.circular(isMe && showAvatar ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sender name (for group messages from others)
                    if (!isMe && !showAvatar) ...[
                      Text(
                        message.senderName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],

                    // Message content
                    Text(
                      message.content,
                      style: TextStyle(
                        color:
                            isMe
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 16,
                      ),
                    ),

                    // Timestamp
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        color:
                            isMe
                                ? Colors.white70
                                : Theme.of(context).textTheme.bodySmall?.color
                                    ?.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF374151)
                    : Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content,
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    final currentUser = AuthService.instance.currentUser;
    final isMe = currentUser?.uid == message.senderId;

    if (!isMe) return; // Only show options for own messages

    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete Message'),
                  textColor: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteMessage(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _confirmDeleteMessage(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Message'),
            content: const Text(
              'Are you sure you want to delete this message?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final chatController = context.read<ChatController>();
                  final success = await chatController.deleteMessage(
                    circleId,
                    message.id,
                  );
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message deleted'),
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      // Today - show time
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday';
    } else {
      // Older - show date
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
