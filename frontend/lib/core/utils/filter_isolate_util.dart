import 'package:flutter/foundation.dart';
import '../features/inventory/data/models/product_model.dart';

/// Filtra una lista de productos en un isolate separado
/// Esto evita bloquear el UI cuando se filtran grandes listas
Future<List<Producto>> filterProductosAsync(
  List<Producto> productos,
  String query,
  String? categoria,
  bool lowStockOnly,
) async {
  return await compute(_filterProductos, (
    productos: productos,
    query: query.toLowerCase(),
    categoria: categoria?.toLowerCase(),
    lowStockOnly: lowStockOnly,
  ));
}

/// Función que se ejecuta en el isolate
List<Producto> _filterProductos(({
  List<Producto> productos,
  String query,
  String? categoria,
  bool lowStockOnly,
}) params) {
  final productos = params.productos;
  final query = params.query;
  final categoria = params.categoria;
  final lowStockOnly = params.lowStockOnly;
  
  return productos.where((p) {
    // Filtro por búsqueda de texto
    bool matchesQuery = query.isEmpty ||
        p.nombre.toLowerCase().contains(query) ||
        p.sku.toLowerCase().contains(query) ||
        (p.categoria?.nombre.toLowerCase().contains(query) ?? false);
    
    // Filtro por categoría
    bool matchesCategory = categoria == null ||
        (p.categoria?.nombre.toLowerCase() == categoria);
    
    // Filtro por stock bajo
    bool matchesLowStock = !lowStockOnly ||
        p.stockActual <= p.alertaStockMinimo;
    
    return matchesQuery && matchesCategory && matchesLowStock;
  }).toList();
}

/// Filtra y ordena productos en un isolate
Future<List<Producto>> filterAndSortProductosAsync(
  List<Producto> productos,
  String query,
  String? categoria,
  bool lowStockOnly,
  String sortBy,
  bool ascending,
) async {
  return await compute(_filterAndSort, (
    productos: productos,
    query: query.toLowerCase(),
    categoria: categoria?.toLowerCase(),
    lowStockOnly: lowStockOnly,
    sortBy: sortBy,
    ascending: ascending,
  ));
}

List<Producto> _filterAndSort(({
  List<Producto> productos,
  String query,
  String? categoria,
  bool lowStockOnly,
  String sortBy,
  bool ascending,
}) params) {
  var result = _filterProductos((
    productos: params.productos,
    query: params.query,
    categoria: params.categoria,
    lowStockOnly: params.lowStockOnly,
  ));
  
  // Ordenar
  result.sort((a, b) {
    int comparison;
    switch (params.sortBy.toLowerCase()) {
      case 'nombre':
        comparison = a.nombre.compareTo(b.nombre);
        break;
      case 'sku':
        comparison = a.sku.compareTo(b.sku);
        break;
      case 'stock':
        comparison = a.stockActual.compareTo(b.stockActual);
        break;
      case 'precio':
        comparison = (a.precioCosto ?? 0).compareTo(b.precioCosto ?? 0);
        break;
      default:
        comparison = a.nombre.compareTo(b.nombre);
    }
    return params.ascending ? comparison : -comparison;
  });
  
  return result;
}
