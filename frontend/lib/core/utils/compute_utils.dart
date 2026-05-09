import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Parsea una lista de JSON a Map en un isolate separado
Future<List<Map<String, dynamic>>> parseJsonListAsync(String jsonString) async {
  return await compute(_parseJsonList, jsonString);
}

Map<String, dynamic> _parseJsonList(String jsonString) {
  return json.decode(jsonString) as Map<String, dynamic>;
}

/// Parsea un producto JSON en un isolate separado
Future<Map<String, dynamic>?> parseProductoJsonAsync(Map<String, dynamic> json) async {
  return await compute(_parseProductoJson, json);
}

Map<String, dynamic>? _parseProductoJson(Map<String, dynamic> json) {
  // Simplemente retornamos el json ya que Producto.fromJson lo procesará
  return json;
}

/// Filtra una lista de productos en un isolate separado
Future<List<Map<String, dynamic>>> filterProductosAsync(
  List<Map<String, dynamic>> productos,
  String query,
) async {
  return await compute(_filterProductos, (productos, query));
}

List<Map<String, dynamic>> _filterProductos(
  (List<Map<String, dynamic>>, String) params,
) {
  final (productos, query) = params;
  final lowerQuery = query.toLowerCase();
  
  return productos.where((p) {
    final nombre = (p['producto_nombre'] ?? '').toString().toLowerCase();
    final sku = (p['producto_sku'] ?? '').toString().toLowerCase();
    final categoria = (p['categoria']?['categoria_nombre'] ?? '').toString().toLowerCase();
    
    return nombre.contains(lowerQuery) || 
           sku.contains(lowerQuery) || 
           categoria.contains(lowerQuery);
  }).toList();
}
