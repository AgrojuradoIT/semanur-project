import 'package:frontend/core/network/api_client.dart';
import '../models/checklist_model.dart';

class ChecklistRepository {
  final ApiClient _apiClient;

  ChecklistRepository(this._apiClient);

  Future<List<Checklist>> getChecklists({String? tipoVehiculo}) async {
    try {
      final response = await _apiClient.dio.get(
        '/checklists',
        queryParameters: tipoVehiculo != null
            ? {'tipo_vehiculo': tipoVehiculo}
            : null,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Checklist.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error fetching checklists: $e');
    }
  }

  Future<bool> submitResponse(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/checklists', data: data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Error submitting checklist: $e');
    }
  }

  Future<List<ChecklistResponse>> getHistory({int? vehiculoId}) async {
    try {
      final response = await _apiClient.dio.get(
        '/checklists/history',
        queryParameters: vehiculoId != null
            ? {'vehiculo_id': vehiculoId}
            : null,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data']; // Pagination wrapper
        return data.map((json) => ChecklistResponse.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error fetching history: $e');
    }
  }
}
