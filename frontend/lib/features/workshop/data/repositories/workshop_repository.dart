import 'package:dio/dio.dart';
import 'package:frontend/core/network/api_client.dart';
import '../models/work_order_model.dart';
import 'package:frontend/core/database/database_helper.dart';

class WorkOrderRepository {
  final ApiClient _apiClient;

  WorkOrderRepository(this._apiClient);

  Future<List<OrdenTrabajo>> getOrdenesTrabajo() async {
    try {
      final response = await _apiClient.dio.get('/ordenes-trabajo');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        // Guardar en cache local (async, no bloqueamos UI necesariamente, o sí para consistencia)
        await DatabaseHelper().saveOrdenesTrabajo(data);

        return data.map((json) => OrdenTrabajo.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      // Si es error de conexión, intentamos cargar local
      if (e is DioException &&
          (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionError ||
              e.error.toString().contains('SocketException'))) {
        final cachedData = await DatabaseHelper().getOrdenesTrabajo();
        if (cachedData.isNotEmpty) {
          return cachedData.map((json) => OrdenTrabajo.fromJson(json)).toList();
        }
      }

      // Si no hay cache o es otro error, lanzamos excepción
      throw Exception('Error al cargar órdenes de trabajo: $e');
    }
  }

  Future<List<OrdenTrabajo>> buscarOrdenes(String query) async {
    try {
      final response = await _apiClient.dio.get(
        '/ordenes-trabajo',
        queryParameters: {'q': query},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => OrdenTrabajo.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error al buscar órdenes: $e');
    }
  }

  Future<OrdenTrabajo> getOrdenTrabajo(int id) async {
    try {
      final response = await _apiClient.dio.get('/ordenes-trabajo/$id');
      if (response.statusCode == 200) {
        return OrdenTrabajo.fromJson(response.data);
      }
      throw Exception('Orden de trabajo no encontrada');
    } catch (e) {
      if (e is DioException &&
          (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionError ||
              e.error.toString().contains('SocketException'))) {
        // Buscar en cache local por ID. getOrdenesTrabajo ahora soporta filtrado.
        final cachedData = await DatabaseHelper().getOrdenesTrabajo(id: id);
        if (cachedData.isNotEmpty) {
          return OrdenTrabajo.fromJson(cachedData.first);
        }
      }
      throw Exception('Error al cargar detalle de la orden: $e');
    }
  }

  Future<bool> updateEstado(int id, String estado) async {
    try {
      final response = await _apiClient.dio.patch(
        '/ordenes-trabajo/$id/estado',
        data: {'estado': estado},
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al actualizar estado de la orden: $e');
    }
  }

  Future<bool> crearOrdenTrabajo({
    required int vehiculoId,
    required String prioridad,
    required String descripcion,
    List<Map<String, dynamic>>? repuestos,
    List<Map<String, dynamic>>? herramientas,
    String? localImagePath,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'vehiculo_id': vehiculoId,
        'prioridad': prioridad,
        'descripcion': descripcion,
        'estado': 'Abierta',
      };

      if (repuestos != null && repuestos.isNotEmpty) {
        data['repuestos'] = repuestos;
      }
      if (herramientas != null && herramientas.isNotEmpty) {
        data['herramientas'] = herramientas;
      }

      final formData = FormData.fromMap(data);

      if (localImagePath != null && localImagePath.isNotEmpty) {
        formData.files.add(
          MapEntry(
            'foto_evidencia',
            await MultipartFile.fromFile(
              localImagePath,
              filename: 'ot_foto.jpg',
            ),
          ),
        );
      }

      final response = await _apiClient.dio.post(
        '/ordenes-trabajo',
        data: formData,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Error al crear orden de trabajo: $e');
    }
  }
}
