import 'package:flutter/foundation.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/repositories/fleet_repository.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/database/database_helper.dart';

class FleetProvider extends ChangeNotifier {
  final FleetRepository _repository;
  List<Vehiculo> _vehiculos = [];
  bool _isLoading = false;
  String? _error;

  FleetProvider(this._repository);

  List<Vehiculo> get vehiculos => _vehiculos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get alertsCount {
    int count = 0;
    final now = DateTime.now();
    for (var v in _vehiculos) {
      bool hasAlert = false;
      // SOAT
      if (v.fechaVencimientoSoat != null &&
          v.fechaVencimientoSoat!.isBefore(now)) {
        hasAlert = true;
      }
      // Tecno
      if (!hasAlert &&
          v.fechaVencimientoTecnomecanica != null &&
          v.fechaVencimientoTecnomecanica!.isBefore(now)) {
        hasAlert = true;
      }
      // Km
      if (!hasAlert &&
          v.kilometrajeProximoMantenimiento != null &&
          (v.kilometrajeActual) >= v.kilometrajeProximoMantenimiento!) {
        hasAlert = true;
      }
      // Horas
      if (!hasAlert &&
          v.horometroProximoMantenimiento != null &&
          (v.horometroActual) >= v.horometroProximoMantenimiento!) {
        hasAlert = true;
      }

      if (hasAlert) count++;
    }
    return count;
  }

  Future<void> fetchVehiculos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vehiculos = await _repository.getVehiculos();
      _isLoading = false;
      _checkExpirations();
      notifyListeners();

      // Cachear en DB Local
      try {
        final vehiculosMap = _vehiculos.map((v) => v.toJson()).toList();
        await DatabaseHelper().saveVehiculos(vehiculosMap);
      } catch (e) {
        debugPrint('Error cacheando vehículos: $e');
      }
    } catch (e) {
      debugPrint('Error obteniendo vehículos de API: $e. Intentando local...');
      // Fallback: Leer de DB Local
      try {
        final localData = await DatabaseHelper().getVehiculos();
        if (localData.isNotEmpty) {
          _vehiculos = localData
              .map((json) {
                try {
                  return Vehiculo.fromJson(json);
                } catch (e) {
                  debugPrint('Error parseando vehículo local: $e');
                  return null;
                }
              })
              .whereType<Vehiculo>()
              .toList();

          if (_vehiculos.isNotEmpty) {
            _isLoading = false;
            // Verificar expiraciones con datos locales
            try {
              _checkExpirations();
            } catch (expError) {
              debugPrint('Error verificando expiraciones locales: $expError');
            }
            notifyListeners();
            return;
          }
        }
      } catch (dbError) {
        debugPrint('Error leyendo DB local: $dbError');
      }

      _isLoading = false;
      _error = 'No se pudo conectar y no hay datos locales.';
      notifyListeners();
    }
  }

  Future<void> searchVehiculos(String query) async {
    if (query.isEmpty) {
      return fetchVehiculos();
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vehiculos = await _repository.buscarVehiculos(query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<Vehiculo?> fetchVehiculoDetalle(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final vehiculo = await _repository.getVehiculo(id);
      _isLoading = false;
      notifyListeners();
      return vehiculo;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateVehicle(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.updateVehicle(id, data);
      if (success) {
        // Recargar detalle para reflejar cambios
        await fetchVehiculoDetalle(id);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _checkExpirations() {
    final now = DateTime.now();
    final sevenDaysFromNow = now.add(const Duration(days: 7));

    for (var v in _vehiculos) {
      // SOAT
      if (v.fechaVencimientoSoat != null) {
        if (v.fechaVencimientoSoat!.isBefore(now)) {
          NotificationService().showNotification(
            id: v.id * 10 + 1,
            title: 'SOAT VENCIDO: ${v.placa}',
            body:
                'El SOAT venció el ${v.fechaVencimientoSoat.toString().split(' ')[0]}',
          );
        } else if (v.fechaVencimientoSoat!.isBefore(sevenDaysFromNow)) {
          NotificationService().showNotification(
            id: v.id * 10 + 1,
            title: 'SOAT POR VENCER: ${v.placa}',
            body:
                'El SOAT vence pronto: ${v.fechaVencimientoSoat.toString().split(' ')[0]}',
          );
        }
      }

      // Technomechanical
      if (v.fechaVencimientoTecnomecanica != null) {
        if (v.fechaVencimientoTecnomecanica!.isBefore(now)) {
          NotificationService().showNotification(
            id: v.id * 10 + 2,
            title: 'TECNO VENCIDA: ${v.placa}',
            body:
                'La tecnomecánica venció el ${v.fechaVencimientoTecnomecanica.toString().split(' ')[0]}',
          );
        } else if (v.fechaVencimientoTecnomecanica!.isBefore(
          sevenDaysFromNow,
        )) {
          NotificationService().showNotification(
            id: v.id * 10 + 2,
            title: 'TECNO POR VENCER: ${v.placa}',
            body:
                'La tecnomecánica vence pronto: ${v.fechaVencimientoTecnomecanica.toString().split(' ')[0]}',
          );
        }
      }
    }
  }
}
