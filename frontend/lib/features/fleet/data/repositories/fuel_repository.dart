import 'package:frontend/core/database/database_helper.dart';
import 'package:dio/dio.dart';
import 'package:frontend/core/network/api_client.dart';
import '../models/fuel_record_model.dart';

class FuelRepository {
  final ApiClient _apiClient;

  FuelRepository(this._apiClient);

  Future<List<RegistroCombustible>> getRegistros({int? vehiculoId}) async {
    try {
      final response = await _apiClient.dio.get(
        '/combustible',
        queryParameters: vehiculoId != null
            ? {'vehiculo_id': vehiculoId}
            : null,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        // Cache
        await DatabaseHelper().saveCombustibleLogs(data);

        return data.map((json) => RegistroCombustible.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      // Offline Fallback
      if (e is DioException &&
          (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionError ||
              e.error.toString().contains('SocketException'))) {
        final cachedData = await DatabaseHelper().getCombustibleLogs(
          vehiculoId: vehiculoId,
        );
        if (cachedData.isNotEmpty) {
          return cachedData
              .map((json) => RegistroCombustible.fromJson(json))
              .toList();
        }
      }
      throw Exception('Error al obtener registros de combustible: $e');
    }
  }

  Future<bool> crearRegistro({
    required int vehiculoId,
    required double cantidadGalones,
    required double valorTotal,
    double? horometro,
    double? kilometraje,
    String? estacion,
    String? notas,
    int? productoId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/combustible',
        data: {
          'vehiculo_id': vehiculoId,
          'cantidad_galones': cantidadGalones,
          'valor_total': valorTotal,
          'horometro_actual': horometro,
          'kilometraje_actual': kilometraje,
          'estacion_servicio': estacion,
          'notas': notas,
          'producto_id': productoId,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Error al registrar abastecimiento: $e');
    }
  }
}
