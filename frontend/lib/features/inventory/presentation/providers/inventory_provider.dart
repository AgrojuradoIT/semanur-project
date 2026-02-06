import 'package:flutter/foundation.dart';
import 'package:frontend/features/inventory/data/models/product_model.dart';
import 'package:frontend/features/inventory/data/repositories/inventory_repository.dart';
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:frontend/core/database/database_helper.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryRepository _repository;
  final NotificationProvider _notificationProvider;

  List<Producto> _productos = [];
  bool _isLoading = false;
  String? _error;

  InventoryProvider(this._repository, this._notificationProvider);

  List<Producto> get productos => _productos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProductos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _productos = await _repository.getProductos();
      _checkLowStock(); // Check alert
      _isLoading = false;
      notifyListeners();

      // Cachear en DB Local
      try {
        final productosMap = _productos.map((p) => p.toJson()).toList();
        await DatabaseHelper().saveProductos(productosMap);
      } catch (e) {
        debugPrint('Error cacheando productos: $e');
      }
    } catch (e) {
      debugPrint('Error obteniendo productos: $e. Intentando local...');
      // Fallback: Leer de DB Local
      try {
        final localData = await DatabaseHelper().getProductos();
        if (localData.isNotEmpty) {
          _productos = localData
              .map((json) {
                try {
                  return Producto.fromJson(json);
                } catch (e) {
                  debugPrint('Error parseando producto local: $e');
                  return null;
                }
              })
              .whereType<Producto>()
              .toList();

          if (_productos.isNotEmpty) {
            try {
              _checkLowStock(); // Check alert
            } catch (stockError) {
              debugPrint('Error verificando stock: $stockError');
            }

            _isLoading = false;
            // No seteamos _error para mostrar la data local (offline mode implícito)
            notifyListeners();
            return;
          }
        }
      } catch (dbError) {
        debugPrint('Error leyendo DB local: $dbError');
      }

      _isLoading = false;
      _error = 'No se pudo conectar al servidor y no hay datos locales.';
      notifyListeners();
    }
  }

  void _checkLowStock() {
    for (var p in _productos) {
      if (p.stockActual <= p.alertaStockMinimo) {
        final isCritical = p.stockActual <= 0;
        _notificationProvider.addNotification(
          title: isCritical ? '¡Stock Agotado!' : 'Stock Bajo',
          body:
              '${p.nombre} tiene ${p.stockActual} ${p.unidadMedida} disponibles.',
          type: isCritical ? 'error' : 'warning',
          showSystemNotification: true, // Also show system notification
        );
      }
    }
  }

  Future<void> searchProductos(String query) async {
    if (query.isEmpty) {
      return fetchProductos();
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _productos = await _repository.buscarProductos(query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
}
