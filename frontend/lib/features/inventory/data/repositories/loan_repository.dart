import 'package:frontend/core/network/api_client.dart';
import '../models/loan_model.dart';

class LoanRepository {
  final ApiClient _apiClient;

  LoanRepository(this._apiClient);

  Future<List<PrestamoHerramienta>> getPrestamos({String? estado}) async {
    try {
      final response = await _apiClient.dio.get(
        '/prestamos',
        queryParameters: estado != null ? {'estado': estado} : null,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => PrestamoHerramienta.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error al obtener préstamos: $e');
    }
  }

  Future<bool> crearPrestamo({
    required int productoId,
    required int mecanicoId,
    required double cantidad,
    String? notas,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/prestamos',
        data: {
          'producto_id': productoId,
          'mecanico_id': mecanicoId,
          'prestamo_cantidad': cantidad,
          'notas': notas,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Error al registrar préstamo: $e');
    }
  }

  Future<bool> devolverPrestamo(int id, String estado, {String? notas}) async {
    try {
      final response = await _apiClient.dio.post(
        '/prestamos/$id/devolver',
        data: {'estado': estado, 'notas': notas},
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al registrar devolución: $e');
    }
  }
}
