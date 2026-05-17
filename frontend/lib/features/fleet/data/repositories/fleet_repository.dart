import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/database/database_helper.dart';
import 'package:dio/dio.dart';
import '../models/vehicle_model.dart';

class FleetRepository {
  final ApiClient _apiClient;

  FleetRepository(this._apiClient);

  Future<List<Vehiculo>> getVehiculos() async {
    try {
      final response = await _apiClient.dio.get('/vehiculos');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        int? toIntOrNull(dynamic value) {
          if (value == null) return null;
          if (value is int) return value;
          return int.tryParse(value.toString());
        }

        double? toDoubleOrNull(dynamic value) {
          if (value == null) return null;
          if (value is num) return value.toDouble();
          return double.tryParse(value.toString());
        }

        // Convertir a map para guardar en BD (alineado con API actual y compat legacy)
        final List<Map<String, dynamic>> maps = data.map((json) {
          final map = Map<String, dynamic>.from(json as Map);

          return {
            'vehiculo_id': toIntOrNull(map['vehiculo_id'] ?? map['id']),
            'placa': map['placa'],
            'marca': map['marca'],
            'modelo': map['modelo'],
            'tipo': map['tipo'],
            'foto_url': map['imagen_url'] ?? map['foto_url'],
            'foto_thumb_url': map['imagen_thumb_url'],
            'horometro_actual': toDoubleOrNull(map['horometro_actual']),
            'kilometraje_actual': toDoubleOrNull(map['kilometraje_actual']),
            'horometro_proximo_mantenimiento':
                toDoubleOrNull(map['horometro_proximo_mantenimiento']),
            'kilometraje_proximo_mantenimiento':
                toDoubleOrNull(map['kilometraje_proximo_mantenimiento']),
            'fecha_vencimiento_soat': map['fecha_vencimiento_soat'],
            'fecha_vencimiento_tecnomecanica':
                map['fecha_vencimiento_tecnomecanica'],
            'operador_asignado_id': toIntOrNull(map['operador_asignado_id']),
            'mecanico_asignado_id': toIntOrNull(map['mecanico_asignado_id']),
            'last_updated': DateTime.now().toIso8601String(),
          };
        }).toList();

        await DatabaseHelper().saveVehiculos(maps);

        return data.map((json) => Vehiculo.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      // Offline fallback
      if (e is DioException &&
          (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionError ||
              e.error.toString().contains('SocketException'))) {
        final cachedData = await DatabaseHelper().getVehiculos();

        // Mapear de vuelta de BD a Modelo
        return cachedData.map((row) {
          double toDoubleOrZero(dynamic value) {
            if (value == null) return 0.0;
            if (value is num) return value.toDouble();
            return double.tryParse(value.toString()) ?? 0.0;
          }

          double? toDoubleOrNull(dynamic value) {
            if (value == null) return null;
            if (value is num) return value.toDouble();
            return double.tryParse(value.toString());
          }

          return Vehiculo(
            id: row['vehiculo_id'],
            placa: row['placa'],
            marca: row['marca'],
            modelo: row['modelo'],
            tipo: row['tipo'],
            horometroActual: toDoubleOrZero(row['horometro_actual']),
            kilometrajeActual: toDoubleOrZero(row['kilometraje_actual']),
            horometroProximoMantenimiento:
                toDoubleOrNull(row['horometro_proximo_mantenimiento']),
            kilometrajeProximoMantenimiento:
                toDoubleOrNull(row['kilometraje_proximo_mantenimiento']),
            fechaVencimientoSoat: row['fecha_vencimiento_soat'] != null
                ? DateTime.parse(row['fecha_vencimiento_soat'])
                : null,
            fechaVencimientoTecnomecanica:
                row['fecha_vencimiento_tecnomecanica'] != null
                ? DateTime.parse(row['fecha_vencimiento_tecnomecanica'])
                : null,
          );
        }).toList();
      }
      throw Exception('Error al cargar la flota de vehículos: $e');
    }
  }

  Future<Vehiculo> getVehiculo(int id) async {
    try {
      final response = await _apiClient.dio.get('/vehiculos/$id');
      if (response.statusCode == 200) {
        return Vehiculo.fromJson(response.data);
      }
      throw Exception('Vehículo no encontrado');
    } catch (e) {
      throw Exception('Error al cargar detalle del vehículo: $e');
    }
  }

  Future<List<Vehiculo>> buscarVehiculos(String query) async {
    try {
      final response = await _apiClient.dio.get(
        '/vehiculos',
        queryParameters: {'q': query},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Vehiculo.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error al buscar vehículos: $e');
    }
  }

  Future<bool> updateVehicle(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/vehiculos/$id', data: data);
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al actualizar vehículo: $e');
    }
  }

  Future<bool> createVehicle(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/vehiculos', data: data);
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al crear vehículo: $e');
    }
  }
}
