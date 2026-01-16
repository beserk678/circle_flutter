import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;
  
  bool _isLoading = false;
  String? _errorMessage;

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

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  void clearError() {
    _setError(null);
  }
}