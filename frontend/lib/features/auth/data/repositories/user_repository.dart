import 'package:frontend/core/network/api_client.dart';
import '../models/user_model.dart';

class UserRepository {
  final ApiClient _apiClient;

  UserRepository(this._apiClient);

  Future<List<User>> getUsers({String? role}) async {
    try {
      final response = await _apiClient.dio.get(
        '/empleados',
        queryParameters: role != null ? {'role': role} : null,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => User.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error al cargar usuarios: $e');
    }
  }

  Future<User> createUser(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/empleados', data: data);
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  Future<User> updateUser(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/empleados/$id', data: data);
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      await _apiClient.dio.delete('/empleados/$id');
    } catch (e) {
      throw Exception('Error al eliminar usuario: $e');
    }
  }
}
