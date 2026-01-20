import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/services/auth_service.dart';
import 'user_profile_model.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  static ProfileService get instance => _instance;
  ProfileService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    } catch (e) {
      debugPrint('Failed to get user profile: $e');
      return null;
    }
  }

  // Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return null;
    return getUserProfile(user.uid);
  }

  // Update user profile
  Future<UserProfile> updateUserProfile({
    required String userId,
    String? name,
    String? bio,
    String? location,
    String? website,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) updates['displayName'] = name;
    if (bio != null) updates['bio'] = bio;
    if (location != null) updates['location'] = location;
    if (website != null) updates['website'] = website;
    if (photoUrl != null) updates['photoURL'] = photoUrl;

    updates['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('users').doc(userId).update(updates);

    final updatedProfile = await getUserProfile(userId);
    if (updatedProfile == null) {
      throw Exception('Failed to get updated profile');
    }

    return updatedProfile;
  }

  // Upload profile photo
  Future<String> uploadProfilePhoto(
    String userId,
    List<int> imageBytes,
    String fileName,
  ) async {
    try {
      final storageRef = _storage.ref().child('profile_photos/$userId.jpg');
      final uploadTask = storageRef.putData(
        Uint8List.fromList(imageBytes),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update user profile with new photo URL
      await updateUserProfile(userId: userId, photoUrl: downloadUrl);

      return downloadUrl;
    } catch (e) {
      debugPrint('Failed to upload profile photo: $e');
      rethrow;
    }
  }

  // Delete profile photo
  Future<void> deleteProfilePhoto(String userId) async {
    try {
      // Delete from storage
      final storageRef = _storage.ref().child('profile_photos/$userId.jpg');
      await storageRef.delete();

      // Update user profile to remove photo URL
      await updateUserProfile(userId: userId, photoUrl: null);
    } catch (e) {
      debugPrint('Failed to delete profile photo: $e');
      // Continue even if storage deletion fails
      await updateUserProfile(userId: userId, photoUrl: null);
    }
  }

  // Update online status
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to update online status: $e');
    }
  }

  // Get app preferences
  Future<AppPreferences> getAppPreferences(String userId) async {
    try {
      final doc =
          await _firestore.collection('appPreferences').doc(userId).get();
      return AppPreferences.fromFirestore(doc);
    } catch (e) {
      debugPrint('Failed to get app preferences: $e');
      return AppPreferences(userId: userId);
    }
  }

  // Update app preferences
  Future<void> updateAppPreferences(AppPreferences preferences) async {
    try {
      await _firestore
          .collection('appPreferences')
          .doc(preferences.userId)
          .set(preferences.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to update app preferences: $e');
      rethrow;
    }
  }

  // Change password
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Re-authenticate user
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);

    // Update password
    await user.updatePassword(newPassword);
  }

  // Update email
  Future<void> updateEmail(String newEmail, String password) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Re-authenticate user
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );

    await user.reauthenticateWithCredential(credential);

    // Send verification email for new email
    await user.verifyBeforeUpdateEmail(newEmail);

    // Update in Firestore (will be updated when email is verified)
    await _firestore.collection('users').doc(user.uid).update({
      'email': newEmail,
    });
  }

  // Delete account
  Future<void> deleteAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Re-authenticate user
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );

    await user.reauthenticateWithCredential(credential);

    // Delete user data from Firestore
    await _deleteUserData(user.uid);

    // Delete profile photo from storage
    try {
      await _storage.ref().child('profile_photos/${user.uid}.jpg').delete();
    } catch (e) {
      debugPrint('Failed to delete profile photo: $e');
    }

    // Delete user account
    await user.delete();
  }

  // Delete all user data
  Future<void> _deleteUserData(String userId) async {
    final batch = _firestore.batch();

    // Delete user document
    batch.delete(_firestore.collection('users').doc(userId));

    // Delete app preferences
    batch.delete(_firestore.collection('appPreferences').doc(userId));

    // Delete notification preferences
    batch.delete(_firestore.collection('notificationPreferences').doc(userId));

    // Delete user's notifications
    final notifications =
        await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .get();

    for (final doc in notifications.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Get user's circle memberships
  Future<List<Map<String, dynamic>>> getUserCircles(String userId) async {
    try {
      final circles =
          await _firestore
              .collection('circles')
              .where('members', arrayContains: userId)
              .get();

      return circles.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['displayName'],
          'memberCount': (data['members'] as List).length,
          'isCreator': data['createdBy'] == userId,
          'joinedAt': data['createdAt'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Failed to get user circles: $e');
      return [];
    }
  }

  // Search users (for mentions, etc.)
  Future<List<UserProfile>> searchUsers(String query, {int limit = 10}) async {
    try {
      if (query.isEmpty) return [];

      final results =
          await _firestore
              .collection('users')
              .where('name', isGreaterThanOrEqualTo: query)
              .where('name', isLessThanOrEqualTo: '$query\uf8ff')
              .limit(limit)
              .get();

      return results.docs.map((doc) => UserProfile.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Failed to search users: $e');
      return [];
    }
  }

  // Get multiple user profiles
  Future<List<UserProfile>> getMultipleUserProfiles(
    List<String> userIds,
  ) async {
    try {
      if (userIds.isEmpty) return [];

      final profiles = <UserProfile>[];

      // Firestore 'in' queries are limited to 10 items
      for (int i = 0; i < userIds.length; i += 10) {
        final batch = userIds.skip(i).take(10).toList();
        final results =
            await _firestore
                .collection('users')
                .where(FieldPath.documentId, whereIn: batch)
                .get();

        profiles.addAll(
          results.docs.map((doc) => UserProfile.fromFirestore(doc)),
        );
      }

      return profiles;
    } catch (e) {
      debugPrint('Failed to get multiple user profiles: $e');
      return [];
    }
  }

  // Stream user profile changes
  Stream<UserProfile?> streamUserProfile(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserProfile.fromFirestore(doc) : null);
  }
}
