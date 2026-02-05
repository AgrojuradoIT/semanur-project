import 'package:flutter/foundation.dart';
import 'package:frontend/features/inventory/data/models/product_model.dart';
import 'package:frontend/features/inventory/data/repositories/inventory_repository.dart';
import '../../../../core/database/database_helper.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryRepository _repository;
  List<Producto> _productos = [];
  bool _isLoading = false;
  String? _error;

  InventoryProvider(this._repository);

  List<Producto> get productos => _productos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProductos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _productos = await _repository.getProductos();
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
              .map((json) => Producto.fromJson(json))
              .toList();
          _isLoading = false;
          notifyListeners();
          return;
        }
      } catch (dbError) {
        debugPrint('Error leyendo DB local: $dbError');
      }

      _isLoading = false;
      _error = e.toString();
      notifyListeners();
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
