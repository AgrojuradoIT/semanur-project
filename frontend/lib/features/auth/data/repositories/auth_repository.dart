import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/features/auth/data/models/user_model.dart';
import 'dart:convert';

class AuthRepository {
  final ApiClient _apiClient;
  final _storage = const FlutterSecureStorage();

  AuthRepository(this._apiClient);

  Future<User?> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
          'device_name': 'flutter_app', // Se podría parametrizar
        },
      );

      if (response.statusCode == 200) {
        final String token = response.data['token'];
        final userData = response.data['user'];

        // Guardar token de forma segura
        await _storage.write(key: 'auth_token', value: token);
        // Guardar datos del usuario para modo offline
        await _storage.write(key: 'user_data', value: jsonEncode(userData));

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
      // Ignorar error de red al cerrar sesión, igual borramos local
      debugPrint('Error logout API (posible offline): $e');
    } finally {
      await _storage.delete(key: 'auth_token');
      await _storage.delete(key: 'user_data');
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
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return null;

    try {
      final response = await _apiClient.dio.get(ApiConstants.user);
      if (response.statusCode == 200) {
        // Actualizar caché
        await _storage.write(
          key: 'user_data',
          value: jsonEncode(response.data),
        );
        return User.fromJson(response.data);
      }
    } on DioException catch (e) {
      debugPrint('Error restaurando sesión API: $e');

      // Si es error de conexión (Offline), intentamos recuperar caché
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        final cachedUser = await _storage.read(key: 'user_data');
        if (cachedUser != null) {
          debugPrint('Restaurando sesión desde caché (OFFLINE MODE)');
          return User.fromJson(jsonDecode(cachedUser));
        }
      }
      // Si es 401, el token expiró -> Devolvemos null para forzar login
    } catch (e) {
      debugPrint('Error general restaurando sesión: $e');
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null;
  }
}
