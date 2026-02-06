import 'package:flutter/foundation.dart';
import 'package:frontend/features/workshop/data/models/work_order_model.dart';
import 'package:frontend/features/workshop/data/repositories/workshop_repository.dart';
import 'package:frontend/core/providers/sync_provider.dart';
import 'package:frontend/core/database/database_helper.dart';

class WorkshopProvider extends ChangeNotifier {
  final WorkOrderRepository _repository;
  final SyncProvider _syncProvider;

  List<OrdenTrabajo> _ordenes = [];
  bool _isLoading = false;
  String? _error;

  WorkshopProvider(this._repository, this._syncProvider);

  List<OrdenTrabajo> get ordenes => _ordenes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchOrdenes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _ordenes = await _repository.getOrdenesTrabajo();

      // Ordenar: Cerradas/Completadas al final, luego por ID descendente
      _ordenes.sort((a, b) {
        final aClosed =
            a.estado.toLowerCase() == 'cerrada' ||
            a.estado.toLowerCase() == 'completada';
        final bClosed =
            b.estado.toLowerCase() == 'cerrada' ||
            b.estado.toLowerCase() == 'completada';

        if (aClosed && !bClosed) return 1;
        if (!aClosed && bClosed) return -1;

        return b.id.compareTo(a.id); // ID descendente
      });

      _isLoading = false;
      notifyListeners();

      // Cachear localmente
      try {
        final ordenesMap = _ordenes.map((o) => o.toJson()).toList();
        await DatabaseHelper().saveOrdenesTrabajo(ordenesMap);
      } catch (cacheError) {
        debugPrint('Error cacheando ordenes: $cacheError');
      }
    } catch (e) {
      debugPrint('Error obteniendo órdenes: $e. Intentando local...');
      // Fallback local
      try {
        final localData = await DatabaseHelper().getOrdenesTrabajo();
        if (localData.isNotEmpty) {
          _ordenes = localData
              .map((json) {
                try {
                  return OrdenTrabajo.fromJson(json);
                } catch (parseError) {
                  debugPrint('Error parseando orden local: $parseError');
                  return null;
                }
              })
              .whereType<OrdenTrabajo>()
              .toList();

          if (_ordenes.isNotEmpty) {
            _isLoading = false;
            notifyListeners();
            return;
          }
        }
      } catch (dbError) {
        debugPrint('Error leyendo DB local ordenes: $dbError');
      }

      _isLoading = false;
      _error = 'No se pudo conectar y no hay datos locales.';
      notifyListeners();
    }
  }

  Future<OrdenTrabajo?> fetchOrdenDetalle(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final orden = await _repository.getOrdenTrabajo(id);

      // Actualizar en la lista local si existe
      final index = _ordenes.indexWhere((o) => o.id == id);
      if (index != -1) {
        _ordenes[index] = orden;
      }

      _isLoading = false;
      notifyListeners();
      return orden;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> searchOrdenes(String query) async {
    if (query.isEmpty) {
      return fetchOrdenes();
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _ordenes = await _repository.buscarOrdenes(query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> actualizarEstado(int id, String nuevoEstado) async {
    try {
      final success = await _repository.updateEstado(id, nuevoEstado);
      if (success) {
        await fetchOrdenes(); // Refrescar lista
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> crearOrden({
    required int vehiculoId,
    required String prioridad,
    required String descripcion,
    List<Map<String, dynamic>>? repuestos,
    List<Map<String, dynamic>>? herramientas,
    String? localImagePath,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.crearOrdenTrabajo(
        vehiculoId: vehiculoId,
        prioridad: prioridad,
        descripcion: descripcion,
        repuestos: repuestos,
        herramientas: herramientas,
        localImagePath: localImagePath,
      );
      if (success) {
        await fetchOrdenes();
      }
      return success;
    } catch (e) {
      // Offline implementation
      if (_syncProvider.status == SyncStatus.offline ||
          e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('socket')) {
        await _syncProvider.addToQueue(
          endpoint: '/ordenes-trabajo',
          method: 'POST',
          payload: {
            'vehiculo_id': vehiculoId,
            'prioridad': prioridad,
            'descripcion': descripcion,
            'repuestos': repuestos,
            'herramientas': herramientas,
          },
          imagePath: localImagePath,
        );

        // Optimistic UI handled by reload, or could manually add to list
        // For now returning true so UI thinks it succeeded
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
