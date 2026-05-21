import 'package:dio/dio.dart';
import 'package:frontend/core/network/api_client.dart';
import '../models/preoperacional_template_model.dart';
import '../models/preoperacional_semana_model.dart';

class PreoperacionalRemoteDataSource {
  final ApiClient _apiClient;

  PreoperacionalRemoteDataSource(this._apiClient);

  /// GET /api/v2/preoperacionales/templates
  Future<List<PreoperacionalTemplate>> getTemplates({
    String? tipoVehiculo,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/v2/preoperacionales/templates',
        queryParameters: tipoVehiculo != null
            ? {'tipo_vehiculo': tipoVehiculo}
            : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['data'] as List? ?? []);
        return data
            .map((json) => PreoperacionalTemplate.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error fetching preoperacional templates: $e');
    }
  }

  /// POST /api/v2/preoperacionales/semanas
  Future<PreoperacionalSemana> createSemana({
    required int vehiculoId,
    int? templateId,
    required int inspectorId,
    required DateTime semanaInicio,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'vehiculo_id': vehiculoId,
        'inspector_id': inspectorId,
        'semana_inicio': semanaInicio.toIso8601String(),
      };
      if (templateId != null) {
        payload['template_id'] = templateId;
      }

      final response = await _apiClient.dio.post(
        '/v2/preoperacionales/semanas',
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PreoperacionalSemana.fromJson(response.data);
      }
      throw Exception(
        'Failed to create semana: ${response.statusCode}',
      );
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ??
          e.response?.data?['errors']?.values?.expand((e) => e)?.first ??
          e.message ??
          'Error desconocido';
      throw Exception('Error creating semana: $errorMsg');
    } catch (e) {
      throw Exception('Error creating semana: $e');
    }
  }

  /// GET /api/v2/preoperacionales/semanas/{id}
  Future<PreoperacionalSemana> getSemana(int id) async {
    try {
      final response = await _apiClient.dio.get(
        '/v2/preoperacionales/semanas/$id',
      );

      if (response.statusCode == 200) {
        return PreoperacionalSemana.fromJson(response.data);
      }
      throw Exception('Semana not found');
    } catch (e) {
      throw Exception('Error fetching semana: $e');
    }
  }

  /// POST /api/v2/preoperacionales/semanas/{semanaId}/dias/{diaSemana}
  Future<PreoperacionalSemana> submitDailyForm({
    required int semanaId,
    required String diaSemana,
    required List<Map<String, dynamic>> respuestas,
    String? observacionesDia,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'respuestas': respuestas,
      };
      if (observacionesDia != null) {
        payload['observaciones_dia'] = observacionesDia;
      }

      final response = await _apiClient.dio.post(
        '/v2/preoperacionales/semanas/$semanaId/dias/$diaSemana',
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PreoperacionalSemana.fromJson(response.data);
      }
      throw Exception(
        'Failed to submit daily form: ${response.statusCode}',
      );
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ??
          e.response?.data?['errors']?.values?.expand((e) => e)?.first ??
          e.message ??
          'Error desconocido';
      throw Exception('Error submitting daily form: $errorMsg');
    } catch (e) {
      throw Exception('Error submitting daily form: $e');
    }
  }

  /// PUT /api/v2/preoperacionales/semanas/{id}/fuera-servicio
  Future<PreoperacionalSemana> markFueraServicio({
    required int semanaId,
    required String motivo,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/v2/preoperacionales/semanas/$semanaId/fuera-servicio',
        data: {'motivo': motivo},
      );

      if (response.statusCode == 200) {
        return PreoperacionalSemana.fromJson(response.data);
      }
      throw Exception(
        'Failed to mark fuera de servicio: ${response.statusCode}',
      );
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ??
          e.message ??
          'Error desconocido';
      throw Exception('Error marking fuera de servicio: $errorMsg');
    } catch (e) {
      throw Exception('Error marking fuera de servicio: $e');
    }
  }

  /// GET /api/v2/preoperacionales/semanas
  Future<List<PreoperacionalSemana>> getSemanas({
    int? semanaAnio,
    int? semanaNumero,
    int? vehiculoId,
    String? estado,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (semanaAnio != null) queryParams['semana_anio'] = semanaAnio;
      if (semanaNumero != null) queryParams['semana_numero'] = semanaNumero;
      if (vehiculoId != null) queryParams['vehiculo_id'] = vehiculoId;
      if (estado != null) queryParams['estado'] = estado;

      final response = await _apiClient.dio.get(
        '/v2/preoperacionales/semanas',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200) {
        final dynamic data = response.data;
        final List<dynamic> items = data is List
            ? data
            : (data['data'] as List? ?? []);
        return items
            .map((json) => PreoperacionalSemana.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error fetching semanas: $e');
    }
  }

  /// GET /api/v2/preoperacionales/pendientes-hoy
  Future<List<Map<String, dynamic>>> getPendientesHoy({
    DateTime? fecha,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/v2/preoperacionales/pendientes-hoy',
        queryParameters: fecha != null
            ? {'fecha': fecha.toIso8601String().split('T')[0]}
            : null,
      );

      if (response.statusCode == 200) {
        final dynamic data = response.data;
        if (data is List) {
          return data.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        if (data is Map && data['data'] is List) {
          return (data['data'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      throw Exception('Error fetching pendientes hoy: $e');
    }
  }
}
