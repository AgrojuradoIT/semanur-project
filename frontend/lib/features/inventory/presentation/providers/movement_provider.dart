import 'package:flutter/foundation.dart';
import '../../data/models/movement_model.dart';
import '../../data/repositories/movement_repository.dart';
import 'package:frontend/core/providers/sync_provider.dart';

class MovementProvider extends ChangeNotifier {
  final MovementRepository _repository;
  final SyncProvider _syncProvider;
  List<MovimientoInventario> _movimientos = [];
  bool _isLoading = false;
  String? _error;

  MovementProvider(this._repository, this._syncProvider);

  List<MovimientoInventario> get movimientos => _movimientos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMovimientos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _movimientos = await _repository.getMovimientos();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> registrarMovimiento({
    required int productoId,
    required String tipo,
    required double cantidad,
    required String motivo,
    int? referenciaId,
    String? referenciaType,
    String? notas,
    int? bodegaId,
    int? bodegaOrigenId,
    int? bodegaDestinoId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.crearMovimiento(
        productoId: productoId,
        tipo: tipo,
        cantidad: cantidad,
        motivo: motivo,
        referenciaId: referenciaId,
        referenciaType: referenciaType,
        notas: notas,
        bodegaId: bodegaId,
        bodegaOrigenId: bodegaOrigenId,
        bodegaDestinoId: bodegaDestinoId,
      );

      if (success) {
        await fetchMovimientos(); // Recargar historial
      }
      return success;
    } catch (e) {
      // Offline logic
      if (_syncProvider.status == SyncStatus.offline ||
          e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('socket')) {
        await _syncProvider.addToQueue(
          endpoint: '/movimientos-inventario',
          method: 'POST',
          payload: {
            'producto_id': productoId,
            // Usar los mismos nombres de campos que la API backend
            'transaccion_tipo': tipo,
            'transaccion_cantidad': cantidad,
            'transaccion_motivo': motivo, // 'ingreso' | 'salida'
            'transaccion_referencia_id': referenciaId,
            'transaccion_referencia_type': referenciaType,
            'transaccion_notas': notas,
            'bodega_id': bodegaId,
            'bodega_origen_id': bodegaOrigenId,
            'bodega_destino_id': bodegaDestinoId,
          },
        );

        return true;
      }

      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners(); // Ensure loading is reset
    }
  }
}
