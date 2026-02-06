import 'package:flutter/foundation.dart';
import '../../data/models/fuel_record_model.dart';
import '../../data/repositories/fuel_repository.dart';

import 'package:frontend/core/providers/sync_provider.dart';
import 'package:frontend/core/database/database_helper.dart';

class FuelProvider extends ChangeNotifier {
  final FuelRepository _repository;
  final SyncProvider _syncProvider;

  List<RegistroCombustible> _registros = [];
  bool _isLoading = false;
  String? _error;

  FuelProvider(this._repository, this._syncProvider);

  List<RegistroCombustible> get registros => _registros;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRegistros({int? vehiculoId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _registros = await _repository.getRegistros(vehiculoId: vehiculoId);
      _isLoading = false;
      notifyListeners();

      // Cachear localmente
      try {
        final logsMap = _registros.map((r) => r.toJson()).toList();
        await DatabaseHelper().saveCombustibleLogs(logsMap);
      } catch (cacheError) {
        debugPrint('Error cacheando combustible logs: $cacheError');
      }
    } catch (e) {
      debugPrint('Error obteniendo registros: $e. Intentando local...');
      // Fallback local
      try {
        final localData = await DatabaseHelper().getCombustibleLogs(
          vehiculoId: vehiculoId,
        );
        if (localData.isNotEmpty) {
          _registros = localData
              .map((json) {
                try {
                  return RegistroCombustible.fromJson(json);
                } catch (parseError) {
                  debugPrint(
                    'Error parseando log combustible local: $parseError',
                  );
                  return null;
                }
              })
              .whereType<RegistroCombustible>()
              .toList();

          if (_registros.isNotEmpty) {
            _isLoading = false;
            notifyListeners();
            return;
          }
        }
      } catch (dbError) {
        debugPrint('Error leyendo DB local combustible: $dbError');
      }

      _isLoading = false;
      _error = 'No se pudo conectar y no hay datos locales.';
      notifyListeners();
    }
  }

  Future<bool> registrarTanqueo({
    required int vehiculoId,
    required double cantidad,
    required double valor,
    double? horometro,
    double? kilometraje,
    String? estacion,
    String? notas,
    int? productoId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.crearRegistro(
        vehiculoId: vehiculoId,
        cantidadGalones: cantidad,
        valorTotal: valor,
        horometro: horometro,
        kilometraje: kilometraje,
        estacion: estacion,
        notas: notas,
        productoId: productoId,
      );
      if (success) {
        await fetchRegistros(vehiculoId: vehiculoId);
      }
      return success;
    } catch (e) {
      // Offline implementation
      if (_syncProvider.status == SyncStatus.offline ||
          e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('socket')) {
        await _syncProvider.addToQueue(
          endpoint: '/combustible',
          method: 'POST',
          payload: {
            'vehiculo_id': vehiculoId,
            'cantidad_galones': cantidad,
            'valor_total': valor,
            'horometro_actual': horometro,
            'kilometraje_actual': kilometraje,
            'estacion_servicio': estacion,
            'notas': notas,
            'producto_id': productoId,
          },
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
