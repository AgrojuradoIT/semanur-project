import 'package:flutter/foundation.dart';
import 'package:frontend/features/inventory/data/models/product_model.dart';
import 'package:frontend/features/inventory/data/repositories/inventory_repository.dart';
import 'package:frontend/core/database/database_helper.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryRepository _repository;

  List<Producto> _productos = [];
  bool _isLoading = false;
  String? _error;
  bool _lowStockOnly = false;
  bool _isFetching = false; // Previene llamadas concurrentes

  // Server-side pagination
  static const int pageSize = 50;
  int _currentPage = 1;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  int _totalItems = 0;

  // Cache de alerts para evitar recalcular
  int? _cachedAlertsCount;

  InventoryProvider(this._repository);

  List<Producto> get productos => _productos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get lowStockOnly => _lowStockOnly;
  String get repositoryUrl => ApiConstants.baseUrl;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;
  int get totalItems => _totalItems;

  /// Obtiene productos paginados (client-side para datos ya cargados)
  List<Producto> get productosPaginados {
    final endIndex = _currentPage * pageSize;
    final actualEndIndex = endIndex > _productos.length
        ? _productos.length
        : endIndex;
    return _productos.sublist(0, actualEndIndex);
  }

  /// Carga más productos desde el servidor (server-side pagination)
  Future<void> loadMoreProductos() async {
    if (_isLoadingMore || !_hasMoreData || _productos.isEmpty) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final newProductos = await _repository.getProductos(
        page: _currentPage,
        perPage: pageSize,
        lowStock: _lowStockOnly,
      );

      if (newProductos.isEmpty || newProductos.length < pageSize) {
        _hasMoreData = false;
      }

      _productos.addAll(newProductos);
      _invalidateAlertsCache();
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMore = false;
      debugPrint('Error cargando más productos: $e');
      notifyListeners();
    }
  }

  /// Resetear pagination
  void resetPagination() {
    _currentPage = 1;
    _hasMoreData = true;
    _isLoadingMore = false;
    _cachedAlertsCount = null;
  }

  Future<void> fetchProductos({bool lowStock = false}) async {
    // Prevenir llamadas concurrentes
    if (_isFetching) {
      debugPrint(
        'InventoryProvider: fetchProductos() ignorado - ya hay una petición en curso',
      );
      return;
    }

    _isFetching = true;
    _isLoading = true;
    _error = null;
    _lowStockOnly = lowStock;
    resetPagination();
    notifyListeners();

    try {
      // Verificar si hay datos locales primero para mostrar algo rápido
      debugPrint(
        'InventoryProvider: Iniciando fetchProductos(lowStock=$lowStock)',
      );
      final localData = await DatabaseHelper().getProductos();
      debugPrint(
        'InventoryProvider: Datos locales: ${localData.length} registros',
      );

      if (localData.isNotEmpty && !lowStock) {
        debugPrint('InventoryProvider: Usando caché local inicialmente');
        // Usar compute para parsing pesado si hay muchos registros
        if (localData.length > 100) {
          _productos = await _parseProductosAsync(localData);
        } else {
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
        }
        _totalItems = _productos.length;
        debugPrint(
          'InventoryProvider: Caché local parseada: ${_productos.length} productos',
        );
        _isLoading = false;
        _error = null;
        _invalidateAlertsCache();
        notifyListeners();
        debugPrint('InventoryProvider: notifyListeners() después de caché');
      } else {
        debugPrint(
          'InventoryProvider: No hay caché local o es lowStock, continuando con API',
        );
      }

      // Cargar desde API con pagination server-side
      debugPrint(
        'InventoryProvider: Llamando a repository.getProductos (page=$_currentPage, perPage=$pageSize)...',
      );
      var productos = await _repository.getProductos(
        page: _currentPage,
        perPage: pageSize,
        lowStock: lowStock,
      );
      debugPrint(
        'InventoryProvider: Repository retornó ${productos.length} productos',
      );

      if (lowStock) {
        productos = _applyLowStockFilter(productos);
        debugPrint(
          'InventoryProvider: Después de filtro low_stock: ${productos.length} productos',
        );
      }

      // Determinar si hay más datos
      _hasMoreData = productos.length >= pageSize;
      _totalItems = productos.length;

      // Asignar productos
      _productos = productos;
      debugPrint(
        'InventoryProvider: _productos asignado con ${_productos.length} elementos',
      );
      _isLoading = false;
      _isFetching = false;
      _invalidateAlertsCache();
      notifyListeners();
      debugPrint(
        'InventoryProvider: notifyListeners() llamado - estado inicial completado',
      );

      // Ahora intentar agregar combustibles (si falla, no afecta lo ya mostrado)
      if (!lowStock) {
        try {
          productos = await _ensureFuelSkus(productos);
          _productos = productos;
          _totalItems = productos.length;
          debugPrint(
            'InventoryProvider: Después de ensureFuelSkus: ${productos.length} productos',
          );
          _invalidateAlertsCache();
          notifyListeners();
        } catch (e) {
          debugPrint('Error en ensureFuelSkus (no crítico): $e');
        }
      }

      // Cachear en DB Local
      try {
        if (!lowStock) {
          final productosMap = _productos.map((p) => p.toJson()).toList();
          await DatabaseHelper().saveProductos(productosMap);
        }
      } catch (e) {
        debugPrint('Error cacheando productos: $e');
      }
    } catch (e) {
      _isFetching = false;
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
          if (lowStock) {
            _productos = _applyLowStockFilter(_productos);
          }

          if (_productos.isNotEmpty) {
            _totalItems = _productos.length;
            _isLoading = false;
            _error = 'Datos en caché (sin conexión)';
            _invalidateAlertsCache();
            notifyListeners();
            return;
          }
        }
      } catch (dbError) {
        debugPrint('Error leyendo DB local: $dbError');
      }

      _isLoading = false;
      // Mensaje de error más descriptivo
      String errorMessage = 'Error de conexión. Verifica tu internet.';
      String errorDetails = e.toString().toLowerCase();

      if (errorDetails.contains('socketexception') ||
          errorDetails.contains('failed host lookup')) {
        errorMessage = 'Sin conexión a internet. Verifica tu red.';
      } else if (errorDetails.contains('handshake') ||
          errorDetails.contains('ssl') ||
          errorDetails.contains('certificate')) {
        errorMessage = 'Error de seguridad SSL. Contacta al administrador.';
      } else if (errorDetails.contains('timeout')) {
        errorMessage = 'Tiempo de espera agotado. Intenta de nuevo.';
      } else if (errorDetails.contains('401') ||
          errorDetails.contains('unauthorized') ||
          errorDetails.contains('token')) {
        errorMessage = 'Sesión expirada. Cierra sesión e inicia nuevamente.';
      } else if (errorDetails.contains('403')) {
        errorMessage = 'No tienes permiso para acceder al inventario.';
      } else if (errorDetails.contains('404')) {
        errorMessage = 'Servicio no disponible. Intenta más tarde.';
      } else if (errorDetails.contains('500') ||
          errorDetails.contains('502') ||
          errorDetails.contains('503')) {
        errorMessage = 'Error del servidor. Contacta al administrador.';
      }

      debugPrint('InventoryProvider Error: $errorMessage');
      debugPrint('Error original: $e');
      _error = errorMessage;
      notifyListeners();
    }
  }

  /// Parsea productos en un isolate separado para no bloquear el UI
  Future<List<Producto>> _parseProductosAsync(
    List<Map<String, dynamic>> jsonData,
  ) async {
    const chunkSize = 50;
    final chunks = <List<Map<String, dynamic>>>[];

    for (var i = 0; i < jsonData.length; i += chunkSize) {
      final end = (i + chunkSize > jsonData.length)
          ? jsonData.length
          : i + chunkSize;
      chunks.add(jsonData.sublist(i, end));
    }

    final results = await Future.wait(
      chunks.map((chunk) => compute(_parseChunk, chunk)),
    );

    return results.expand((list) => list).whereType<Producto>().toList();
  }

  static List<Producto?> _parseChunk(List<Map<String, dynamic>> chunk) {
    return chunk.map((json) {
      try {
        return Producto.fromJson(json);
      } catch (e) {
        debugPrint('Error parseando producto en chunk: $e');
        return null;
      }
    }).toList();
  }

  Future<List<Producto>> _ensureFuelSkus(List<Producto> productos) async {
    final skuGasolina = (dotenv.env['FUEL_SKU_GASOLINA'] ?? '').trim();
    final skuAcpm = (dotenv.env['FUEL_SKU_ACPM'] ?? '').trim();

    debugPrint('_ensureFuelSkus: skuGasolina=$skuGasolina, skuAcpm=$skuAcpm');

    final missing = <String>[];
    if (skuGasolina.isNotEmpty &&
        !productos.any(
          (p) => p.sku.toLowerCase() == skuGasolina.toLowerCase(),
        )) {
      missing.add(skuGasolina);
    }
    if (skuAcpm.isNotEmpty &&
        !productos.any((p) => p.sku.toLowerCase() == skuAcpm.toLowerCase())) {
      missing.add(skuAcpm);
    }
    if (missing.isEmpty) {
      debugPrint(
        '_ensureFuelSkus: No faltan combustibles, retornando ${productos.length} productos',
      );
      return productos;
    }

    debugPrint(
      '_ensureFuelSkus: Faltan ${missing.length} combustibles: $missing',
    );

    final updated = List<Producto>.from(productos);
    bool added = false;
    for (final sku in missing) {
      try {
        debugPrint('_ensureFuelSkus: Buscando SKU $sku...');
        final results = await _repository.buscarProductos(sku);
        debugPrint('_ensureFuelSkus: Resultados para $sku: ${results.length}');
        if (results.isEmpty) continue;
        final exact = results.firstWhere(
          (p) => p.sku.toLowerCase() == sku.toLowerCase(),
          orElse: () => results.first,
        );
        if (!updated.any((p) => p.id == exact.id)) {
          updated.add(exact);
          added = true;
        }
      } catch (e) {
        debugPrint('Error buscando SKU combustible $sku: $e');
      }
    }

    if (added) {
      updated.sort((a, b) => a.nombre.compareTo(b.nombre));
      try {
        final productosMap = updated.map((p) => p.toJson()).toList();
        await DatabaseHelper().saveProductos(productosMap);
      } catch (e) {
        debugPrint('Error cacheando SKUs combustibles: $e');
      }
    }
    debugPrint('_ensureFuelSkus: Retornando ${updated.length} productos');
    return updated;
  }

  /// El cálculo de alertsCount es para vehículos, no para productos
  /// Se deja este getter por compatibilidad pero retorna 0 para productos
  int get alertsCount {
    if (_cachedAlertsCount != null) return _cachedAlertsCount!;
    // Los productos no tienen alertas de SOAT/tecnomecánica
    // Solo tienen alerta de stock bajo
    _cachedAlertsCount = _productos
        .where((p) => p.stockActual <= p.alertaStockMinimo)
        .length;
    return _cachedAlertsCount!;
  }

  void _invalidateAlertsCache() {
    _cachedAlertsCount = null;
  }

  Future<void> searchProductos(String query) async {
    if (query.isEmpty) {
      return fetchProductos(lowStock: _lowStockOnly);
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _productos = await _repository.buscarProductos(query);
      _totalItems = _productos.length;
      _invalidateAlertsCache();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> searchProductosWithLowStock(
    String query, {
    bool lowStock = false,
  }) {
    _lowStockOnly = lowStock;
    return searchProductos(query);
  }


  Future<bool> updateProducto(int id, Map<String, dynamic> payload) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.updateProducto(id, payload);
      await fetchProductos(lowStock: _lowStockOnly);
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> deleteProducto(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _repository.deleteProducto(id);
      if (result['message']?.toString().contains('No se puede') == true) {
        _isLoading = false;
        notifyListeners();
        return result;
      }
      await fetchProductos(lowStock: _lowStockOnly);
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'message': e.toString()};
    }
  }

  List<Producto> _applyLowStockFilter(List<Producto> items) {
    return items.where((p) => p.stockActual <= p.alertaStockMinimo).toList();
  }
}
