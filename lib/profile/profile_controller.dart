import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/services/auth_service.dart';
import 'profile_service.dart';
import 'user_profile_model.dart';

class ProfileController extends ChangeNotifier {
  final ProfileService _profileService = ProfileService.instance;
  final ImagePicker _imagePicker = ImagePicker();

  UserProfile? _currentUserProfile;
  AppPreferences? _appPreferences;
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _errorMessage;

  UserProfile? get currentUserProfile => _currentUserProfile;
  AppPreferences? get appPreferences => _appPreferences;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setUpdating(bool updating) {
    _isUpdating = updating;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Initialize profile data
  Future<void> initializeProfile() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    _setLoading(true);
    _setError(null);

    try {
      // Load current user profile
      _currentUserProfile = await _profileService.getCurrentUserProfile();

      // Load app preferences
      _appPreferences = await _profileService.getAppPreferences(user.uid);

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load profile: $e');
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? bio,
    String? location,
    String? website,
  }) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return false;

    _setUpdating(true);
    _setError(null);

    try {
      _currentUserProfile = await _profileService.updateUserProfile(
        userId: user.uid,
        name: name,
        bio: bio,
        location: location,
        website: website,
      );

      _setUpdating(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update profile: $e');
      _setUpdating(false);
      return false;
    }
  }

  // Upload profile photo from camera
  Future<bool> uploadPhotoFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        return await _uploadProfilePhoto(image);
      }
      return false;
    } catch (e) {
      _setError('Failed to capture photo: $e');
      return false;
    }
  }

  // Upload profile photo from gallery
  Future<bool> uploadPhotoFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        return await _uploadProfilePhoto(image);
      }
      return false;
    } catch (e) {
      _setError('Failed to pick photo: $e');
      return false;
    }
  }

  // Internal method to upload profile photo
  Future<bool> _uploadProfilePhoto(XFile imageFile) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return false;

    _setUpdating(true);
    _setError(null);

    try {
      // Read image bytes (works on all platforms including web)
      final bytes = await imageFile.readAsBytes();
      final photoUrl = await _profileService.uploadProfilePhoto(
        user.uid,
        bytes,
        imageFile.name,
      );

      // Update local profile
      if (_currentUserProfile != null) {
        _currentUserProfile = _currentUserProfile!.copyWith(photoUrl: photoUrl);
      }

      _setUpdating(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to upload photo: $e');
      _setUpdating(false);
      return false;
    }
  }

  // Delete profile photo
  Future<bool> deleteProfilePhoto() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return false;

    _setUpdating(true);
    _setError(null);

    try {
      await _profileService.deleteProfilePhoto(user.uid);

      // Update local profile
      if (_currentUserProfile != null) {
        _currentUserProfile = _currentUserProfile!.copyWith(photoUrl: null);
      }

      _setUpdating(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete photo: $e');
      _setUpdating(false);
      return false;
    }
  }

  // Update app preferences
  Future<bool> updateAppPreferences(AppPreferences preferences) async {
    _setUpdating(true);
    _setError(null);

    try {
      await _profileService.updateAppPreferences(preferences);
      _appPreferences = preferences;

      _setUpdating(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update preferences: $e');
      _setUpdating(false);
      return false;
    }
  }

  // Change password
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _setUpdating(true);
    _setError(null);

    try {
      await _profileService.changePassword(currentPassword, newPassword);
      _setUpdating(false);
      return true;
    } catch (e) {
      _setError('Failed to change password: $e');
      _setUpdating(false);
      return false;
    }
  }

  // Update email
  Future<bool> updateEmail(String newEmail, String password) async {
    _setUpdating(true);
    _setError(null);

    try {
      await _profileService.updateEmail(newEmail, password);

      // Update local profile
      if (_currentUserProfile != null) {
        _currentUserProfile = _currentUserProfile!.copyWith(email: newEmail);
      }

      _setUpdating(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update email: $e');
      _setUpdating(false);
      return false;
    }
  }

  // Delete account
  Future<bool> deleteAccount(String password) async {
    _setUpdating(true);
    _setError(null);

    try {
      await _profileService.deleteAccount(password);
      _setUpdating(false);
      return true;
    } catch (e) {
      _setError('Failed to delete account: $e');
      _setUpdating(false);
      return false;
    }
  }

  // Get user profile by ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      return await _profileService.getUserProfile(userId);
    } catch (e) {
      _setError('Failed to get user profile: $e');
      return null;
    }
  }

  // Get user's circles
  Future<List<Map<String, dynamic>>> getUserCircles() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return [];

    try {
      return await _profileService.getUserCircles(user.uid);
    } catch (e) {
      _setError('Failed to get user circles: $e');
      return [];
    }
  }

  // Search users
  Future<List<UserProfile>> searchUsers(String query) async {
    try {
      return await _profileService.searchUsers(query);
    } catch (e) {
      _setError('Failed to search users: $e');
      return [];
    }
  }

  void clearError() {
    _setError(null);
  }
}
