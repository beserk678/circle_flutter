import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../core/services/auth_service.dart';
import 'circle_model.dart';

class CircleService {
  static final CircleService _instance = CircleService._internal();
  static CircleService get instance => _instance;
  CircleService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Generate a unique 6-character invite code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      6,
      (index) => chars[DateTime.now().millisecondsSinceEpoch % chars.length],
    ).join();
  }

  // Create a new circle
  Future<Circle> createCircle({
    required String name,
    required String userId,
  }) async {
    final inviteCode = _generateInviteCode();

    // Ensure invite code is unique
    final existingCircle = await getCircleByInviteCode(inviteCode);
    if (existingCircle != null) {
      // Recursively try again with a new code
      return createCircle(name: name, userId: userId);
    }

    final circle = Circle(
      id: _uuid.v4(),
      name: name,
      inviteCode: inviteCode,
      createdBy: userId,
      members: [userId], // Creator is automatically a member
      admins: [userId], // Creator is automatically an admin
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('circles')
        .doc(circle.id)
        .set(circle.toFirestore());
    return circle;
  }

  // Join a circle using invite code
  Future<Circle?> joinCircleByInviteCode({
    required String inviteCode,
    required String userId,
  }) async {
    final circle = await getCircleByInviteCode(inviteCode);
    if (circle == null) {
      throw Exception('Invalid invite code');
    }

    // Check if user is already a member
    if (circle.members.contains(userId)) {
      return circle;
    }

    // Add user to circle members
    final updatedMembers = [...circle.members, userId];
    await _firestore.collection('circles').doc(circle.id).update({
      'members': updatedMembers,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return circle.copyWith(members: updatedMembers);
  }

  // Get circle by invite code
  Future<Circle?> getCircleByInviteCode(String inviteCode) async {
    final query =
        await _firestore
            .collection('circles')
            .where('inviteCode', isEqualTo: inviteCode)
            .limit(1)
            .get();

    if (query.docs.isEmpty) {
      return null;
    }

    return Circle.fromFirestore(query.docs.first);
  }

  // Get all circles (for discovery/browsing)
  Stream<List<Circle>> getAllCircles() {
    return _firestore
        .collection('circles')
        .orderBy('createdAt', descending: true)
        .limit(50) // Limit to 50 most recent circles
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Circle.fromFirestore(doc)).toList(),
        );
  }

  // Get circles where user is a member
  Stream<List<Circle>> getUserCircles(String userId) {
    return _firestore
        .collection('circles')
        .where('members', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Circle.fromFirestore(doc)).toList(),
        );
  }

  // Get single circle by ID
  Future<Circle?> getCircleById(String circleId) async {
    final doc = await _firestore.collection('circles').doc(circleId).get();
    if (!doc.exists) return null;
    return Circle.fromFirestore(doc);
  }

  // Leave a circle
  Future<void> leaveCircle({
    required String circleId,
    required String userId,
  }) async {
    final circle = await getCircleById(circleId);
    if (circle == null) return;

    final updatedMembers = circle.members.where((id) => id != userId).toList();

    // If no members left, delete the circle
    if (updatedMembers.isEmpty) {
      await _firestore.collection('circles').doc(circleId).delete();
    } else {
      await _firestore.collection('circles').doc(circleId).update({
        'members': updatedMembers,
      });
    }
  }

  // Get circle members info
  Future<List<Map<String, dynamic>>> getCircleMembers(String circleId) async {
    final circle = await getCircleById(circleId);
    if (circle == null) return [];

    final members = <Map<String, dynamic>>[];
    for (final memberId in circle.members) {
      final userDoc = await AuthService.instance.getUserDocument(memberId);
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        members.add({
          'uid': memberId,
          'name': userData['displayName'] ?? 'Unknown',
          'email': userData['email'] ?? '',
          'isCreator': memberId == circle.createdBy,
        });
      }
    }
    return members;
  }
}
