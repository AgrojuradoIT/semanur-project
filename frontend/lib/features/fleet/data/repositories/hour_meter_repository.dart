import 'package:frontend/core/network/api_client.dart';
import '../models/hour_meter_record_model.dart';

class HorometroRepository {
  final ApiClient _apiClient;

  HorometroRepository(this._apiClient);

  Future<List<RegistroHorometro>> getRegistros(int vehiculoId) async {
    try {
      final response = await _apiClient.dio.get(
        '/vehiculos/$vehiculoId/horometro',
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => RegistroHorometro.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error al cargar registros de horómetro: $e');
    }
  }

  Future<bool> registrarHorometro({
    required int vehiculoId,
    required double valorNuevo,
    String? notas,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/horometro',
        data: {
          'vehiculo_id': vehiculoId,
          'valor_nuevo': valorNuevo,
          'notas': notas,
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Error al registrar horómetro: $e');
    }
  }
}
