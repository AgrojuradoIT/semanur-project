import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/auth/data/models/user_model.dart';

class AuthRepository {
  static const String _authTokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _deviceNameKey = 'device_name';

  final ApiClient _apiClient;
  final _storage = const FlutterSecureStorage();

  AuthRepository(this._apiClient);

  Future<User?> login(String email, String password) async {
    try {
      const deviceName = 'flutter_app';
      final response = await _apiClient.dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
          'device_name': deviceName,
        },
      );

      if (response.statusCode == 200) {
        final String token = response.data['token'];
        final userData = response.data['user'];

        await _storage.write(key: _authTokenKey, value: token);
        await _storage.write(key: _deviceNameKey, value: deviceName);
        await _storage.write(key: _userDataKey, value: jsonEncode(userData));

        return User.fromJson(userData);
      }
    } on DioException catch (e) {
      debugPrint('Error en login: ${e.message}');
      rethrow;
    }
    return null;
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post(ApiConstants.logout);
    } catch (e) {
      debugPrint('Error logout API (possible offline): $e');
    } finally {
      await _storage.delete(key: _authTokenKey);
      await _storage.delete(key: _userDataKey);
      await _storage.delete(key: _deviceNameKey);
    }
  }

  Future<void> logoutAllDevices() async {
    try {
      await _apiClient.dio.post(ApiConstants.logoutAll);
    } catch (e) {
      debugPrint('Error logout-all API: $e');
      rethrow;
    } finally {
      await _storage.delete(key: _authTokenKey);
      await _storage.delete(key: _userDataKey);
      await _storage.delete(key: _deviceNameKey);
    }
  }

  Future<List<User>> getUsers() async {
    try {
      final response = await _apiClient.dio.get('/users');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => User.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error al cargar usuarios: $e');
    }
  }

  Future<User?> restoreSession() async {
    final token = await _storage.read(key: _authTokenKey);
    if (token == null) return null;

    try {
      final response = await _apiClient.dio.get(ApiConstants.user);
      if (response.statusCode == 200) {
        await _storage.write(
          key: _userDataKey,
          value: jsonEncode(response.data),
        );
        return User.fromJson(response.data);
      }
    } on DioException catch (e) {
      debugPrint('Error restaurando sesion API: $e');

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        final cachedUser = await _storage.read(key: _userDataKey);
        if (cachedUser != null) {
          debugPrint('Restaurando sesion desde cache (OFFLINE MODE)');
          return User.fromJson(jsonDecode(cachedUser));
        }
      }
    } catch (e) {
      debugPrint('Error general restaurando sesion: $e');
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _authTokenKey);
    return token != null;
  }
}
