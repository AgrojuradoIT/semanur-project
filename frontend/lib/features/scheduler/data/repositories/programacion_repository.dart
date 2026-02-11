import 'package:dio/dio.dart';
import 'package:frontend/core/network/api_client.dart';
import '../models/programacion_model.dart';

class ProgramacionRepository {
  final ApiClient _apiClient;

  ProgramacionRepository(this._apiClient);

  Future<List<Programacion>> getProgramacion(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        '/programacion',
        queryParameters: {
          'fecha_inicio': start.toIso8601String().split('T')[0],
          'fecha_fin': end.toIso8601String().split('T')[0],
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Programacion.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error fetching programacion: $e');
    }
  }

  Future<Programacion> createProgramacion(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/programacion', data: data);
    return Programacion.fromJson(response.data);
  }

  Future<void> reportarNovedad(
    Map<String, dynamic> data, {
    String? localImagePath,
  }) async {
    // data ya contiene prioridad y pausar_actividad desde el provider
    if (localImagePath == null || localImagePath.isEmpty) {
      await _apiClient.dio.post('/programacion/novedad', data: data);
      return;
    }

    final formData = FormData.fromMap(data);

    formData.files.add(
      MapEntry(
        'foto',
        await MultipartFile.fromFile(
          localImagePath,
          filename: 'novedad_foto.jpg',
        ),
      ),
    );

    await _apiClient.dio.post('/programacion/novedad', data: formData);
  }

  Future<void> deleteProgramacion(int id) async {
    await _apiClient.dio.delete('/programacion/$id');
  }

  Future<Programacion> updateProgramacion(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.dio.put('/programacion/$id', data: data);
    return Programacion.fromJson(response.data);
  }
}
