import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/database/database_helper.dart';
import 'package:dio/dio.dart';
import 'package:frontend/core/constants/api_constants.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

class InventoryRepository {
  final ApiClient _apiClient;

  InventoryRepository(this._apiClient);

  Future<List<Producto>> getProductos() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.productos);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        // Preparar para guardar en BD
        List<Map<String, dynamic>> productsToSave = [];
        for (var item in data) {
          // Flatten categories if needed, but DatabaseHelper handles json encoding of 'categoria' field.
          // We need to match table columns: producto_id, categoria_id, producto_sku...
          // Assuming the API returns matching keys mostly.

          productsToSave.add({
            'producto_id': item['id'],
            'categoria_id': item['categoria_id'], // Puede ser null
            'producto_sku': item['sku'],
            'producto_nombre': item['nombre'],
            'producto_unidad_medida': item['unidad_medida'],
            'producto_stock_actual': item['stock_actual'],
            'producto_alerta_stock_minimo': item['stock_minimo'],
            'producto_precio_costo': item['precio_costo'],
            'producto_ubicacion': item['ubicacion'],
            'categoria': item['categoria'], // Object or null
            'last_updated': DateTime.now().toIso8601String(),
          });
        }
        await DatabaseHelper().saveProductos(productsToSave);

        return data.map((json) => Producto.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      // Offline fallback
      if (e is DioException &&
          (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionError ||
              e.error.toString().contains('SocketException'))) {
        final cachedData = await DatabaseHelper().getProductos();

        // Mapear de BD a Modelo
        return cachedData.map((row) {
          return Producto(
            id: row['producto_id'],
            categoriaId: row['categoria_id'],
            sku: row['producto_sku'],
            nombre: row['producto_nombre'],
            unidadMedida: row['producto_unidad_medida'],
            stockActual: (row['producto_stock_actual'] as num).toDouble(),
            alertaStockMinimo: (row['producto_alerta_stock_minimo'] as num)
                .toDouble(),
            precioCosto: (row['producto_precio_costo'] as num).toDouble(),
            ubicacion: row['producto_ubicacion'],
            categoria: row['categoria'] != null
                ? Categoria.fromJson(row['categoria'])
                : null,
          );
        }).toList();
      }
      throw Exception('Error al cargar productos: $e');
    }
  }

  Future<List<Producto>> buscarProductos(String query) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.buscarProductos,
        queryParameters: {'q': query},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Producto.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error al buscar productos: $e');
    }
  }

  Future<Producto> getProducto(int id) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.productos}/$id',
      );
      if (response.statusCode == 200) {
        return Producto.fromJson(response.data);
      }
      throw Exception('Producto no encontrado');
    } catch (e) {
      throw Exception('Error al cargar detalle del producto: $e');
    }
  }
}
