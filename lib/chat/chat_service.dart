import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/services/auth_service.dart';
import '../notifications/notification_service.dart';
import '../circles/circle_service.dart';
import 'message_model.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  static ChatService get instance => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Send a text message
  Future<Message> sendMessage({
    required String circleId,
    required String content,
    MessageType type = MessageType.text,
    String? mediaUrl,
    String? fileName,
    int? fileSize,
  }) async {
    final user = AuthService.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get user data for sender info
    final userDoc = await AuthService.instance.getUserDocument(user.uid);
    final userData = userDoc.data() as Map<String, dynamic>?;

    final message = Message(
      id: _uuid.v4(),
      circleId: circleId,
      senderId: user.uid,
      senderName: userData?['displayName'] ?? 'Unknown',
      senderPhotoUrl: userData?['photoURL'],
      content: content,
      type: type,
      createdAt: DateTime.now(),
      mediaUrl: mediaUrl,
      fileName: fileName,
      fileSize: fileSize,
      readBy: [user.uid], // Sender has "read" their own message
    );

    await _firestore
        .collection('circles')
        .doc(circleId)
        .collection('messages')
        .doc(message.id)
        .set(message.toFirestore());

    // Send notification to other circle members
    try {
      final circle = await CircleService.instance.getCircleById(circleId);
      if (circle != null) {
        await NotificationService.instance.notifyNewMessage(
          circleId: circleId,
          circleName: circle.name,
          memberIds: circle.members,
          senderName: message.senderName,
          messagePreview:
              message.content.length > 50
                  ? '${message.content.substring(0, 50)}...'
                  : message.content,
        );
      }
    } catch (e) {
      debugPrint('Failed to send message notification: $e');
    }

    return message;
  }

  // Get messages for a circle (real-time stream)
  Stream<List<Message>> getCircleMessages(String circleId, {int limit = 50}) {
    return _firestore
        .collection('circles')
        .doc(circleId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final messages =
              snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
          // Return in chronological order (oldest first) for chat display
          return messages.reversed.toList();
        });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(
    String circleId,
    List<String> messageIds,
    String userId,
  ) async {
    final batch = _firestore.batch();

    for (final messageId in messageIds) {
      final messageRef = _firestore
          .collection('circles')
          .doc(circleId)
          .collection('messages')
          .doc(messageId);

      batch.update(messageRef, {
        'readBy': FieldValue.arrayUnion([userId]),
      });
    }

    await batch.commit();
  }

  // Send typing indicator
  Future<void> sendTypingIndicator(
    String circleId,
    String userId,
    String userName,
  ) async {
    final typingIndicator = TypingIndicator(
      userId: userId,
      userName: userName,
      lastTyping: DateTime.now(),
    );

    await _firestore
        .collection('circles')
        .doc(circleId)
        .collection('typing')
        .doc(userId)
        .set(typingIndicator.toFirestore());
  }

  // Stop typing indicator
  Future<void> stopTypingIndicator(String circleId, String userId) async {
    await _firestore
        .collection('circles')
        .doc(circleId)
        .collection('typing')
        .doc(userId)
        .delete();
  }

  // Get typing indicators (real-time stream)
  Stream<List<TypingIndicator>> getTypingIndicators(
    String circleId,
    String currentUserId,
  ) {
    return _firestore
        .collection('circles')
        .doc(circleId)
        .collection('typing')
        .snapshots()
        .map((snapshot) {
          final indicators =
              snapshot.docs
                  .map((doc) => TypingIndicator.fromFirestore(doc))
                  .where(
                    (indicator) =>
                        indicator.userId !=
                            currentUserId && // Exclude current user
                        indicator.isActive,
                  ) // Only active indicators
                  .toList();

          return indicators;
        });
  }

  // Get single message
  Future<Message?> getMessage(String circleId, String messageId) async {
    final doc =
        await _firestore
            .collection('circles')
            .doc(circleId)
            .collection('messages')
            .doc(messageId)
            .get();

    if (!doc.exists) return null;
    return Message.fromFirestore(doc);
  }

  // Delete message (only by sender)
  Future<void> deleteMessage(
    String circleId,
    String messageId,
    String userId,
  ) async {
    final message = await getMessage(circleId, messageId);
    if (message == null || message.senderId != userId) {
      throw Exception('Unauthorized to delete this message');
    }

    await _firestore
        .collection('circles')
        .doc(circleId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  // Send system message (like "User joined the circle")
  Future<void> sendSystemMessage(String circleId, String content) async {
    final message = Message(
      id: _uuid.v4(),
      circleId: circleId,
      senderId: 'system',
      senderName: 'System',
      content: content,
      type: MessageType.system,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('circles')
        .doc(circleId)
        .collection('messages')
        .doc(message.id)
        .set(message.toFirestore());
  }

  // Get unread message count for a circle
  Future<int> getUnreadMessageCount(String circleId, String userId) async {
    final snapshot =
        await _firestore
            .collection('circles')
            .doc(circleId)
            .collection('messages')
            .where('readBy', whereNotIn: [userId])
            .where('senderId', isNotEqualTo: userId) // Don't count own messages
            .get();

    return snapshot.docs.length;
  }
}
