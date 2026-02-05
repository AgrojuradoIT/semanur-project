import 'package:frontend/core/network/api_client.dart';
import '../models/movement_model.dart';

class MovementRepository {
  final ApiClient _apiClient;

  MovementRepository(this._apiClient);

  Future<List<MovimientoInventario>> getMovimientos() async {
    try {
      final response = await _apiClient.dio.get('/movimientos');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => MovimientoInventario.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error al cargar historial de movimientos: $e');
    }
  }

  Future<bool> crearMovimiento({
    required int productoId,
    required String tipo,
    required double cantidad,
    required String motivo,
    int? referenciaId,
    String? referenciaType,
    String? notas,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/movimientos',
        data: {
          'producto_id': productoId,
          'transaccion_tipo': tipo,
          'transaccion_cantidad': cantidad,
          'transaccion_motivo': motivo,
          'transaccion_referencia_id': referenciaId,
          'transaccion_referencia_type': referenciaType,
          'transaccion_notas': notas,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Error al registrar movimiento: $e');
    }
  }
}
