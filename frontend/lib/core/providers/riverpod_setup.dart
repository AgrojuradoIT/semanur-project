/// Riverpod Providers - Groundwork for future migration
/// 
/// Este archivo prepara la migración futura de Provider a Riverpod.
/// Los providers actuales de ChangeNotifier pueden migrarse gradualmente.
/// 
/// Para usar Riverpod:
/// 1. Agregar dependencias:
///    dependencies:
///      flutter_riverpod: ^2.4.0
///      riverpod_annotation: ^2.3.0
///    
///    dev_dependencies:
///      riverpod_generator: ^2.3.0
///      build_runner: ^2.4.0
/// 
/// 2. Reemplazar MultiProvider con ProviderScope
/// 3. Migrar cada ChangeNotifier a NotifierProvider o StateNotifierProvider
/// 
/// Ejemplo de migración:
/// 
/// ANTES (Provider):
/// ```dart
/// ChangeNotifierProvider(create: (_) => InventoryProvider(repository))
/// ```
/// 
/// DESPUÉS (Riverpod):
/// ```dart
/// @riverpod
/// class Inventory extends _$Inventory {
///   @override
///   Future<List<Producto>> build() async => [];
///   
///   Future<void> fetchProductos() async {
///     state = const AsyncValue.loading();
///     state = await AsyncValue.guard(() => 
///       ref.read(inventoryRepositoryProvider).getProductos()
///     );
///   }
/// }
/// ```

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================================
// PROVIDERS DE INFRAESTRUCTURA (para migrar primero)
// ============================================================================

/// Provider para ApiClient (singleton)
final apiClientProvider = Provider<ApiClient>((ref) {
  throw UnimplementedError('Implementar cuando se migre a Riverpod');
});

/// Provider para DatabaseHelper (singleton)
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  throw UnimplementedError('Implementar cuando se migre a Riverpod');
});

// ============================================================================
// PROVIDERS DE REPOSITORIOS (para migrar segundo)
// ============================================================================

/// Repository provider pattern
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return InventoryRepository(apiClient);
});

final fleetRepositoryProvider = Provider<FleetRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FleetRepository(apiClient);
});

final workshopRepositoryProvider = Provider<WorkshopRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WorkOrderRepository(apiClient);
});

// ============================================================================
// PROVIDERS DE ESTADO (para migrar último - UI)
// ============================================================================

/// Ejemplo de cómo migrar InventoryProvider a Riverpod
final inventoryProvider = StateNotifierProvider<InventoryNotifier, InventoryState>((ref) {
  throw UnimplementedError('Implementar cuando se migre a Riverpod');
  // final repository = ref.watch(inventoryRepositoryProvider);
  // return InventoryNotifier(repository);
});

/// Estado inmutable para InventoryProvider
class InventoryState {
  final List<Producto> productos;
  final bool isLoading;
  final String? error;
  final bool lowStockOnly;
  final int currentPage;
  final bool hasMoreData;
  
  const InventoryState({
    this.productos = const [],
    this.isLoading = false,
    this.error,
    this.lowStockOnly = false,
    this.currentPage = 1,
    this.hasMoreData = true,
  });
  
  InventoryState copyWith({
    List<Producto>? productos,
    bool? isLoading,
    String? error,
    bool? lowStockOnly,
    int? currentPage,
    bool? hasMoreData,
  }) {
    return InventoryState(
      productos: productos ?? this.productos,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lowStockOnly: lowStockOnly ?? this.lowStockOnly,
      currentPage: currentPage ?? this.currentPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
    );
  }
}

/// Notifier para InventoryProvider
class InventoryNotifier extends StateNotifier<InventoryState> {
  InventoryNotifier(this._repository) : super(const InventoryState());
  
  final InventoryRepository _repository;
  
  // Métodos similares a InventoryProvider actual
  Future<void> fetchProductos({bool lowStock = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    // Implementación...
  }
  
  Future<void> loadMoreProductos() async {
    // Implementación para server-side pagination
  }
  
  void resetPagination() {
    state = state.copyWith(currentPage: 1, hasMoreData: true);
  }
  
  int get alertsCount {
    // Cálculo cacheado de alertas
    return 0;
  }
}

// ============================================================================
// SELECTORS (optimización de rebuilds)
// ============================================================================

/// Selector para obtener solo productos filtrados (evita rebuilds innecesarios)
final filteredProductosProvider = Provider<List<Producto>>((ref) {
  final inventoryState = ref.watch(inventoryProvider);
  final filter = ref.watch(inventoryFilterProvider);
  
  // Filtrado optimizado
  return inventoryState.productos.where((p) {
    // Lógica de filtrado
    return true;
  }).toList();
});

/// Selector para filtro de inventario
final inventoryFilterProvider = StateProvider<InventoryFilter>((ref) {
  return const InventoryFilter();
});

class InventoryFilter {
  final String query;
  final String? categoria;
  final bool lowStockOnly;
  final String sortBy;
  final bool ascending;
  
  const InventoryFilter({
    this.query = '',
    this.categoria,
    this.lowStockOnly = false,
    this.sortBy = 'nombre',
    this.ascending = true,
  });
  
  InventoryFilter copyWith({
    String? query,
    String? categoria,
    bool? lowStockOnly,
    String? sortBy,
    bool? ascending,
  }) {
    return InventoryFilter(
      query: query ?? this.query,
      categoria: categoria ?? this.categoria,
      lowStockOnly: lowStockOnly ?? this.lowStockOnly,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
    );
  }
}

// ============================================================================
// COMBINED PROVIDERS (para datos relacionados)
// ============================================================================

/// Provider combinado para dashboard (inventario + flota + talleres)
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final inventory = ref.watch(inventoryProvider);
  final fleet = ref.watch(fleetProvider);
  final workshop = ref.watch(workshopProvider);
  
  return DashboardStats(
    totalProductos: inventory.productos.length,
    totalVehiculos: fleet.vehiculos.length,
    alertasInventario: inventory.alertsCount,
    alertasFlota: fleet.alertsCount,
    ordenesAbiertas: workshop.ordenes.where((o) => o.estado == 'abierta').length,
  );
});

class DashboardStats {
  final int totalProductos;
  final int totalVehiculos;
  final int alertasInventario;
  final int alertasFlota;
  final int ordenesAbiertas;
  
  DashboardStats({
    required this.totalProductos,
    required this.totalVehiculos,
    required this.alertasInventario,
    required this.alertasFlota,
    required this.ordenesAbiertas,
  });
}
