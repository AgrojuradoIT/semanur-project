import 'dart:async';

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
      _user = await _authRepository
          .login(email, password)
          .timeout(const Duration(seconds: 65));
      return _user != null;
    } on TimeoutException {
      _user = null;
      _error =
          'Tiempo de espera agotado. Verifica tu conexion e intenta de nuevo.';
      return false;
    } catch (e) {
      debugPrint('AuthProvider: Login error: $e');
      if (e is DioException) {
        debugPrint(
          'AuthProvider: DioError details: ${e.response?.statusCode} - ${e.response?.data}',
        );
        
        // Extraer mensaje de error del backend
        final data = e.response?.data;
        if (data is Map) {
          // Si hay errores de validación (Laravel), extraer el primero
          if (data['errors'] is Map && (data['errors'] as Map).isNotEmpty) {
            final firstErrorKey = (data['errors'] as Map).keys.first;
            final firstErrorList = data['errors'][firstErrorKey];
            if (firstErrorList is List && firstErrorList.isNotEmpty) {
              _error = firstErrorList.first.toString();
            }
          }
          
          // Si no se extrajo de 'errors', buscar en otros campos
          _error ??= data['message']?.toString() ??
                   data['error']?.toString() ??
                   e.message ??
                   'Credenciales incorrectas';
        } else if (data is String) {
          _error = data;
        } else {
          _error = e.message ?? 'Credenciales incorrectas';
        }
      } else {
        _error = e.toString();
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> logoutAllDevices() async {
    await _authRepository.logoutAllDevices();
    _user = null;
    notifyListeners();
  }

  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  Future<bool> updateProfileProfile({String? name, String? phone, String? licenseNumber}) async {
    _error = null;
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;
      if (licenseNumber != null) data['license_number'] = licenseNumber;

      final updatedUser = await _authRepository.updateProfileProfile(data);
      if (updatedUser != null) {
        _user = updatedUser;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('AuthProvider: Update profile error: $e');
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          _error = data['message']?.toString() ?? e.message ?? 'Error actualizando perfil';
        } else {
          _error = e.message ?? 'Error actualizando perfil';
        }
      } else {
        _error = e.toString();
      }
      return false;
    }
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = await _authRepository
          .restoreSession()
          .timeout(const Duration(seconds: 65), onTimeout: () => null);
      _user = user;
    } catch (e) {
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
