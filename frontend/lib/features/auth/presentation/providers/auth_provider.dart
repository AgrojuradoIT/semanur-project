import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:frontend/features/auth/data/models/user_model.dart';
import 'package:frontend/features/auth/data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  User? _user;
  bool _isLoading = false;

  AuthProvider(this._authRepository);

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  String? _error;
  String? get error => _error;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authRepository.login(email, password);
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _isLoading = false;
      debugPrint('AuthProvider: Login error: $e');
      if (e is DioException) {
        debugPrint(
          'AuthProvider: DioError details: ${e.response?.statusCode} - ${e.response?.data}',
        );
        final data = e.response?.data;
        if (data is Map && data.containsKey('message')) {
          _error = data['message'];
        } else if (data is String) {
          _error = data; // If it's a plain string response
        } else {
          _error = e.message ?? 'Error desconocido';
        }
      } else {
        _error = e.toString();
      }
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    notifyListeners();
  }

  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = await _authRepository.restoreSession();
      _user = user;
    } catch (e) {
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
