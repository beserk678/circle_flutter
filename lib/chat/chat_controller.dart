import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import 'chat_service.dart';
import 'message_model.dart';

class ChatController extends ChangeNotifier {
  final ChatService _chatService = ChatService.instance;

  List<Message> _messages = [];
  List<TypingIndicator> _typingIndicators = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _typingTimer;
  String? _currentCircleId;

  List<Message> get messages => _messages;
  List<TypingIndicator> get typingIndicators => _typingIndicators;
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

  // Initialize chat for a circle
  void initializeChat(String circleId) {
    if (_currentCircleId == circleId) return; // Already initialized

    _currentCircleId = circleId;

    // Listen to messages
    _chatService
        .getCircleMessages(circleId)
        .listen(
          (messages) {
            _messages = messages;
            _markVisibleMessagesAsRead(circleId);
            notifyListeners();
          },
          onError: (error) {
            _setError('Failed to load messages: $error');
          },
        );

    // Listen to typing indicators
    final user = AuthService.instance.currentUser;
    if (user != null) {
      _chatService
          .getTypingIndicators(circleId, user.uid)
          .listen(
            (indicators) {
              _typingIndicators = indicators;
              notifyListeners();
            },
            onError: (error) {
              // Typing indicators are not critical, so we don't show errors
              debugPrint('Typing indicators error: $error');
            },
          );
    }
  }

  // Send a message
  Future<bool> sendMessage({
    required String circleId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    if (content.trim().isEmpty && type == MessageType.text) {
      _setError('Message cannot be empty');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      await _chatService.sendMessage(
        circleId: circleId,
        content: content.trim(),
        type: type,
      );

      // Stop typing indicator after sending
      final user = AuthService.instance.currentUser;
      if (user != null) {
        await _chatService.stopTypingIndicator(circleId, user.uid);
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to send message: $e');
      _setLoading(false);
      return false;
    }
  }

  // Send typing indicator
  Future<void> sendTypingIndicator(String circleId) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    try {
      // Get user data for name
      final userDoc = await AuthService.instance.getUserDocument(user.uid);
      final userData = userDoc.data() as Map<String, dynamic>?;
      final userName = userData?['displayName'] ?? 'Unknown';

      await _chatService.sendTypingIndicator(circleId, user.uid, userName);

      // Cancel previous timer
      _typingTimer?.cancel();

      // Set timer to stop typing indicator after 3 seconds
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _chatService.stopTypingIndicator(circleId, user.uid);
      });
    } catch (e) {
      // Typing indicators are not critical
      debugPrint('Failed to send typing indicator: $e');
    }
  }

  // Stop typing indicator
  Future<void> stopTypingIndicator(String circleId) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    _typingTimer?.cancel();

    try {
      await _chatService.stopTypingIndicator(circleId, user.uid);
    } catch (e) {
      debugPrint('Failed to stop typing indicator: $e');
    }
  }

  // Mark visible messages as read
  Future<void> _markVisibleMessagesAsRead(String circleId) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    final unreadMessages =
        _messages
            .where(
              (message) =>
                  !message.isReadBy(user.uid) && message.senderId != user.uid,
            ) // Don't mark own messages
            .map((message) => message.id)
            .toList();

    if (unreadMessages.isNotEmpty) {
      try {
        await _chatService.markMessagesAsRead(
          circleId,
          unreadMessages,
          user.uid,
        );
      } catch (e) {
        debugPrint('Failed to mark messages as read: $e');
      }
    }
  }

  // Delete a message
  Future<bool> deleteMessage(String circleId, String messageId) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return false;

    try {
      await _chatService.deleteMessage(circleId, messageId, user.uid);
      return true;
    } catch (e) {
      _setError('Failed to delete message: $e');
      return false;
    }
  }

  void clearError() {
    _setError(null);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }
}
