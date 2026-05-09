import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  Future<OrdenTrabajo> getOrdenTrabajo(int id, {bool forceRefresh = false}) async {
    // Si es force refresh, ignorar caché local e ir directo al servidor
    if (forceRefresh) {
      debugPrint('WorkOrderRepository: Forzando refresh desde servidor para orden $id');
      try {
        final response = await _apiClient.dio.get('/ordenes-trabajo/$id');
        if (response.statusCode == 200) {
          debugPrint('WorkOrderRepository: Datos recibidos del servidor para orden $id');
          final orden = OrdenTrabajo.fromJson(response.data);
          debugPrint('WorkOrderRepository: Orden tiene ${orden.sesiones?.length ?? 0} sesiones');
          // Actualizar caché local con los datos más recientes
          await DatabaseHelper().saveOrdenTrabajoLocal(orden.toJson());
          return orden;
        } else {
          debugPrint('WorkOrderRepository: Error en respuesta del servidor: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('WorkOrderRepository: Excepción al fetch del servidor (force refresh): $e');
        // Continuar con fallback a caché si falla el servidor
      }
    }
    
    try {
      final response = await _apiClient.dio.get('/ordenes-trabajo/$id');
      if (response.statusCode == 200) {
        final orden = OrdenTrabajo.fromJson(response.data);

        // Actualizar cache local con el detalle más reciente
        await DatabaseHelper().saveOrdenTrabajoLocal(orden.toJson());

        return orden;
      }
      throw Exception('Orden de trabajo no encontrada');
    } catch (e) {
      // Si es error de conexión o error del servidor (500), intentamos cargar local
      if (e is DioException &&
          (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.badResponse || // Incluye 500
              e.error.toString().contains('SocketException'))) {

        // Buscar en cache local por ID
        final cachedData = await DatabaseHelper().getOrdenesTrabajo(id: id);
        if (cachedData.isNotEmpty) {
          debugPrint('WorkOrderRepository: Usando caché local para orden $id');
          return OrdenTrabajo.fromJson(cachedData.first);
        }

        // Intentar buscar en la tabla de ordenes generales
        final allCached = await DatabaseHelper().getOrdenesTrabajo();
        Map<String, dynamic>? found;
        for (var o in allCached) {
          if (o['orden_trabajo_id'] == id || o['id'] == id) {
            found = o;
            break;
          }
        }
        if (found != null) {
          debugPrint('WorkOrderRepository: Usando caché general para orden $id');
          return OrdenTrabajo.fromJson(found);
        }
      }

      debugPrint('WorkOrderRepository: Error cargando detalle orden $id: $e');
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
    int? mecanicoId,
    List<Map<String, dynamic>>? repuestos,
    List<Map<String, dynamic>>? herramientas,
    String? localImagePath,
  }) async {
    try {
      // NO enviamos fecha_inicio - el backend la pone automáticamente con now()
      // que está configurado en America/Bogota
      final Map<String, dynamic> data = {
        'vehiculo_id': vehiculoId,
        'prioridad': prioridad,
        'descripcion': descripcion,
        'estado': 'Abierta',
        'mecanico_asignado_id': mecanicoId,
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
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        String msg = data['message'] ?? 'Error en el servidor';
        if (data['error'] != null) {
          msg = "$msg: ${data['error']}";
        }
        throw Exception(msg);
      }
      throw Exception('Error al crear orden de trabajo: ${e.message}');
    } catch (e) {
      throw Exception('Error al crear orden de trabajo: $e');
    }
  }
}
