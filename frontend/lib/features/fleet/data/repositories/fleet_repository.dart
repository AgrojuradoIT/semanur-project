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

        // Convertir models a Map para guardar en BD (usando toJson)
        final List<Map<String, dynamic>> maps = data.map((json) {
          // Asegurarnos de que el json es compatible con lo que espera el helper
          // El helper espera un map plano. El Vehiculo.fromJson maneja la estructura.
          // Pero saveVehiculos espera un map compatible con la tabla.
          // Simplemente guardaremos lo básico o adaptamos el helper.
          // Revisando DatabaseHelper._createVehiculosTable, espera:
          // vehiculo_id, placa, marca, modelo, tipo, foto_url...

          return {
            'vehiculo_id': json['id'],
            'placa': json['placa'],
            'marca': json['marca'],
            'modelo': json['modelo'],
            'tipo': json['tipo'],
            'foto_url': json['foto_url'],
            'horometro_actual': json['horometro_actual'],
            'kilometraje_actual': json['kilometraje_actual'],
            'horometro_proximo_mantenimiento':
                json['horometro_proximo_mantenimiento'],
            'kilometraje_proximo_mantenimiento':
                json['kilometraje_proximo_mantenimiento'],
            'fecha_vencimiento_soat': json['fecha_vencimiento_soat'],
            'fecha_vencimiento_tecnomecanica':
                json['fecha_vencimiento_tecnomecanica'],
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

        // Mapear de vuelta de DB a Modelo
        return cachedData.map((row) {
          // Reconstruir el map que espera Vehiculo.fromJson si es necesario,
          // o usar un factory fromDb. Por ahora adaptamos keys.
          return Vehiculo(
            id: row['vehiculo_id'],
            placa: row['placa'],
            marca: row['marca'],
            modelo: row['modelo'],
            tipo: row['tipo'],
            // fotoUrl not in model
            horometroActual: (row['horometro_actual'] as num).toDouble(),
            kilometrajeActual: row['kilometraje_actual'],
            horometroProximoMantenimiento:
                row['horometro_proximo_mantenimiento'],
            kilometrajeProximoMantenimiento:
                row['kilometraje_proximo_mantenimiento'],
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
}
