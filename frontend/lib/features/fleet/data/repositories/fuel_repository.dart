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
        // Handle paginated response {data: [...], meta: {...}} or legacy array
        final List<dynamic> data;
        if (response.data is Map) {
          data = response.data['data'] ?? [];
        } else {
          data = response.data;
        }

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
    required int? vehiculoId,
    required double cantidadGalones,
    required double valorTotal,
    double? horometro,
    double? kilometraje,
    String? estacion,
    String? notas,
    String? labor,
    int? productoId,
    int? empleadoId,
    String? terceroNombre,
    String? placaManual,
    String tipoDestino = 'vehiculo',
    String tipoCombustible = 'gasolina',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/combustible',
        data: {
          'vehiculo_id': vehiculoId,
          'empleado_id': empleadoId,
          'tercero_nombre': terceroNombre,
          'placa_manual': placaManual,
          'tipo_destino': tipoDestino,
          'tipo_combustible': tipoCombustible,
          'cantidad_galones': cantidadGalones,
          'valor_total': valorTotal,
          'horometro_actual': horometro,
          'kilometraje_actual': kilometraje,
          'estacion_servicio': estacion,
          'notas': notas,
          'labor': labor,
          'producto_id': productoId,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        String msg = data['message'] ?? 'Error en el servidor';
        if (data['error'] != null) {
          msg = "$msg: ${data['error']}";
        }
        throw Exception(msg);
      }
      throw Exception('Error de red al registrar abastecimiento: ${e.message}');
    } catch (e) {
      throw Exception('Error al registrar abastecimiento: $e');
    }
  }

  Future<bool> updateRegistro(int id, Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.dio.put('/combustible/$id', data: payload);
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al actualizar registro: $e');
    }
  }

  Future<bool> deleteRegistro(int id) async {
    try {
      final response = await _apiClient.dio.delete('/combustible/$id');
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al eliminar registro: $e');
    }
  }
}
