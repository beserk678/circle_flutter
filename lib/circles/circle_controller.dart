import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import 'circle_model.dart';
import 'circle_service.dart';

class CircleController extends ChangeNotifier {
  final CircleService _circleService = CircleService.instance;

  List<Circle> _userCircles = [];
  Circle? _selectedCircle;
  bool _isLoading = false;
  String? _errorMessage;

  List<Circle> get userCircles => _userCircles;
  Circle? get selectedCircle => _selectedCircle;
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

  // Initialize circles for current user
  void initializeCircles() {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    _circleService
        .getUserCircles(user.uid)
        .listen(
          (circles) {
            _userCircles = circles;

            // If we have a selected circle, try to keep it selected
            if (_selectedCircle != null) {
              final updatedSelectedCircle = circles.firstWhere(
                (c) => c.id == _selectedCircle!.id,
                orElse: () {
                  // If selected circle not found, don't auto-select another
                  return _selectedCircle!;
                },
              );
              _selectedCircle = updatedSelectedCircle;
            } else if (circles.isNotEmpty && circles.length == 1) {
              // Only auto-select if user has exactly one circle
              _selectedCircle = circles.first;
            }

            notifyListeners();
          },
          onError: (error) {
            _setError('Failed to load circles: $error');
          },
        );
  }

  // Create a new circle
  Future<bool> createCircle(String name) async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      _setError('User not authenticated');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      final circle = await _circleService.createCircle(
        name: name,
        userId: user.uid,
      );

      // Set as selected circle
      _selectedCircle = circle;

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create circle: $e');
      _setLoading(false);
      return false;
    }
  }

  // Join a circle by invite code
  Future<bool> joinCircle(String inviteCode) async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      _setError('User not authenticated');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      final circle = await _circleService.joinCircleByInviteCode(
        inviteCode: inviteCode.toUpperCase(),
        userId: user.uid,
      );

      if (circle != null) {
        // Set as selected circle and immediately notify listeners
        _selectedCircle = circle;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _setError('Invalid invite code');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to join circle: $e');
      _setLoading(false);
      return false;
    }
  }

  // Select a circle
  void selectCircle(Circle circle) {
    _selectedCircle = circle;
    notifyListeners();
  }

  // Leave a circle
  Future<bool> leaveCircle(String circleId) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return false;

    _setLoading(true);
    _setError(null);

    try {
      await _circleService.leaveCircle(circleId: circleId, userId: user.uid);

      // If we left the selected circle, clear selection
      if (_selectedCircle?.id == circleId) {
        _selectedCircle = null;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to leave circle: $e');
      _setLoading(false);
      return false;
    }
  }

  void clearError() {
    _setError(null);
  }
}
