import 'package:dio/dio.dart';
import 'package:frontend/core/network/api_client.dart';
import 'dart:convert';
import 'package:frontend/core/database/database_helper.dart';
import '../models/checklist_model.dart';

class ChecklistRepository {
  final ApiClient _apiClient;

  ChecklistRepository(this._apiClient);

  Future<List<ChecklistPreoperacional>> getChecklists({int? vehiculoId}) async {
    try {
      final response = await _apiClient.dio.get(
        '/checklists',
        queryParameters: vehiculoId != null
            ? {'vehiculo_id': vehiculoId}
            : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        // Guardar en cache
        await DatabaseHelper().saveChecklists(data);

        return data
            .map((json) => ChecklistPreoperacional.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      // Offline Falback
      if (e is DioException &&
          (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionError ||
              e.error.toString().contains('SocketException'))) {
        final cachedData = await DatabaseHelper().getChecklists(
          vehiculoId: vehiculoId,
        );
        if (cachedData.isNotEmpty) {
          return cachedData
              .map((json) => ChecklistPreoperacional.fromJson(json))
              .toList();
        }
      }
      throw Exception('Error al cargar checklists: $e');
    }
  }

  Future<bool> createChecklist(
    ChecklistPreoperacional checklist, {
    String? localImagePath,
  }) async {
    try {
      final Map<String, dynamic> data = checklist.toJson();

      // Convert map to JSON string for the multipart field
      data['checklist_data'] = jsonEncode(checklist.checklistData);

      final formData = FormData.fromMap(data);

      if (localImagePath != null && localImagePath.isNotEmpty) {
        formData.files.add(
          MapEntry(
            'foto_evidencia',
            await MultipartFile.fromFile(
              localImagePath,
              filename: 'checklist_foto.jpg',
            ),
          ),
        );
      }

      final response = await _apiClient.dio.post('/checklists', data: formData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Error al enviar checklist: $e');
    }
  }
}
