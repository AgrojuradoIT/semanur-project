import 'package:flutter/foundation.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/repositories/fleet_repository.dart';
import '../../../../core/database/database_helper.dart';

class FleetProvider extends ChangeNotifier {
  final FleetRepository _repository;

  List<Vehiculo> _vehiculos = [];
  bool _isLoading = false;
  String? _error;
  bool _isFetching = false; // Previene llamadas concurrentes
  
  // Pagination
  static const int pageSize = 30;
  int _currentPage = 0;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  
  // Cache de alerts para evitar recalcular en cada acceso
  int? _cachedAlertsCount;

  FleetProvider(this._repository);

  List<Vehiculo> get vehiculos => _vehiculos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;
  
  /// Obtiene vehículos paginados para lazy loading
  List<Vehiculo> get vehiculosPaginados {
    final endIndex = (_currentPage + 1) * pageSize;
    final actualEndIndex = endIndex > _vehiculos.length ? _vehiculos.length : endIndex;
    return _vehiculos.sublist(0, actualEndIndex);
  }
  
  /// Carga más vehículos cuando el usuario hace scroll
  Future<void> loadMoreVehiculos() async {
    if (_isLoadingMore || !_hasMoreData || _vehiculos.isEmpty) return;
    
    _isLoadingMore = true;
    notifyListeners();
    
    // Pequeño delay para UX
    await Future.delayed(const Duration(milliseconds: 100));
    
    _currentPage++;
    _isLoadingMore = false;
    
    // Verificar si hay más datos
    final endIndex = (_currentPage + 1) * pageSize;
    if (endIndex >= _vehiculos.length) {
      _hasMoreData = false;
    }
    
    notifyListeners();
  }
  
  /// Resetear pagination
  void resetPagination() {
    _currentPage = 0;
    _hasMoreData = true;
    _isLoadingMore = false;
    _cachedAlertsCount = null;
  }

  int get alertsCount {
    // Retornar cache si existe
    if (_cachedAlertsCount != null) return _cachedAlertsCount!;
    
    int count = 0;
    final now = DateTime.now();
    // Usar año actual para comparación eficiente de fechas
    final nowYear = now.year;
    final nowMonth = now.month;
    final nowDay = now.day;
    
    for (var v in _vehiculos) {
      bool hasAlert = false;
      
      // Optimización: comparar solo componentes de fecha necesarios
      final soat = v.fechaVencimientoSoat;
      if (soat != null && 
          (soat.year < nowYear || 
           (soat.year == nowYear && soat.month < nowMonth) ||
           (soat.year == nowYear && soat.month == nowMonth && soat.day < nowDay))) {
        hasAlert = true;
      }
      
      if (!hasAlert) {
        final tecno = v.fechaVencimientoTecnomecanica;
        if (tecno != null && 
            (tecno.year < nowYear || 
             (tecno.year == nowYear && tecno.month < nowMonth) ||
             (tecno.year == nowYear && tecno.month == nowMonth && tecno.day < nowDay))) {
          hasAlert = true;
        }
      }
      
      if (!hasAlert && v.kilometrajeProximoMantenimiento != null) {
        if (v.kilometrajeActual >= v.kilometrajeProximoMantenimiento!) {
          hasAlert = true;
        }
      }
      
      if (!hasAlert && v.horometroProximoMantenimiento != null) {
        if (v.horometroActual >= v.horometroProximoMantenimiento!) {
          hasAlert = true;
        }
      }
      
      if (hasAlert) count++;
    }
    
    _cachedAlertsCount = count;
    return count;
  }
  
  /// Invalidar cache de alerts cuando se actualizan los datos
  void _invalidateAlertsCache() {
    _cachedAlertsCount = null;
  }

  Future<void> fetchVehiculos() async {
    // Prevenir llamadas concurrentes
    if (_isFetching) {
      debugPrint('FleetProvider: fetchVehiculos() ignorado - ya hay una petición en curso');
      return;
    }

    _isFetching = true;
    _isLoading = true;
    _error = null;
    resetPagination();
    notifyListeners();

    try {
      _vehiculos = await _repository.getVehiculos();
      _isLoading = false;
      _isFetching = false;
      _invalidateAlertsCache();
      notifyListeners();


    } catch (e) {
      _isFetching = false;
      debugPrint('Error obteniendo vehículos de API: $e. Intentando local...');
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
            _invalidateAlertsCache();
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
    if (query.isEmpty) return fetchVehiculos();

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vehiculos = await _repository.buscarVehiculos(query);
      _invalidateAlertsCache();
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
        await fetchVehiculoDetalle(id);
        _invalidateAlertsCache();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createVehicle(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.createVehicle(data);
      if (success) {
        await fetchVehiculos();
        _invalidateAlertsCache();
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

