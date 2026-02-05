import 'package:flutter/foundation.dart';
import 'package:frontend/features/workshop/data/models/work_order_model.dart';
import 'package:frontend/features/workshop/data/repositories/workshop_repository.dart';

class WorkshopProvider extends ChangeNotifier {
  final WorkOrderRepository _repository;
  List<OrdenTrabajo> _ordenes = [];
  bool _isLoading = false;
  String? _error;

  WorkshopProvider(this._repository);

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
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
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
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
