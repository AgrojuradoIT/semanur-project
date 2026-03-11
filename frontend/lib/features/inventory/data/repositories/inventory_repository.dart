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
        // Handle paginated response {data: [...], meta: {...}} or legacy array
        final List<dynamic> data;
        if (response.data is Map) {
          data = response.data['data'] ?? [];
        } else {
          data = response.data;
        }

        int? toIntOrNull(dynamic value) {
          if (value == null) return null;
          if (value is int) return value;
          return int.tryParse(value.toString());
        }

        double toDoubleOrDefault(dynamic value, double defaultValue) {
          if (value == null) return defaultValue;
          if (value is num) return value.toDouble();
          return double.tryParse(value.toString()) ?? defaultValue;
        }

        // Preparar para guardar en BD (alineado con backend actual y compat legacy)
        List<Map<String, dynamic>> productsToSave = [];
        for (var item in data) {
          final map = Map<String, dynamic>.from(item as Map);

          productsToSave.add({
            'producto_id': toIntOrNull(map['producto_id'] ?? map['id']),
            'categoria_id': toIntOrNull(map['categoria_id']),
            'producto_sku': map['producto_sku'] ?? map['sku'] ?? '',
            'producto_nombre': map['producto_nombre'] ?? map['nombre'] ?? '',
            'producto_unidad_medida':
                map['producto_unidad_medida'] ?? map['unidad_medida'] ?? 'unidad',
            'producto_stock_actual':
                toDoubleOrDefault(map['producto_stock_actual'] ?? map['stock_actual'], 0),
            'producto_alerta_stock_minimo': toDoubleOrDefault(
              map['producto_alerta_stock_minimo'] ?? map['stock_minimo'],
              5,
            ),
            'producto_precio_costo':
                toDoubleOrDefault(map['producto_precio_costo'] ?? map['precio_costo'], 0),
            'producto_ubicacion': map['producto_ubicacion'] ?? map['ubicacion'],
            'categoria': map['categoria'],
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
        double toDoubleOrZero(dynamic value) {
          if (value == null) return 0.0;
          if (value is num) return value.toDouble();
          return double.tryParse(value.toString()) ?? 0.0;
        }

        int? toIntOrNull(dynamic value) {
          if (value == null) return null;
          if (value is int) return value;
          return int.tryParse(value.toString());
        }

        return cachedData.map((row) {
          final dynamic categoriaRaw = row['categoria'];
          final Map<String, dynamic>? categoriaMap = categoriaRaw is Map
              ? Map<String, dynamic>.from(categoriaRaw)
              : null;

          return Producto(
            id: toIntOrNull(row['producto_id']) ?? 0,
            categoriaId: toIntOrNull(row['categoria_id']),
            sku: row['producto_sku']?.toString() ?? '',
            nombre: row['producto_nombre']?.toString() ?? '',
            unidadMedida: row['producto_unidad_medida']?.toString(),
            stockActual: toDoubleOrZero(row['producto_stock_actual']),
            alertaStockMinimo: toDoubleOrZero(
              row['producto_alerta_stock_minimo'],
            ),
            precioCosto: row['producto_precio_costo'] != null
                ? toDoubleOrZero(row['producto_precio_costo'])
                : null,
            ubicacion: row['producto_ubicacion']?.toString(),
            categoria: categoriaMap != null
                ? Categoria.fromJson(categoriaMap)
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

  Future<Map<String, dynamic>> importProductos(
    String filePath, {
    bool skipDuplicates = false,
  }) async {
    try {
      String fileName = filePath.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(filePath, filename: fileName),
        "skip_duplicates": skipDuplicates,
      });

      final response = await _apiClient.dio.post(
        ApiConstants.importarProductos,
        data: formData,
      );

      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return e.response?.data; // Return duplicates info
      }
      throw Exception('Error importando productos: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> updateProducto(int id, Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.productos}/$id',
        data: payload,
      );
      return response.data;
    } catch (e) {
      throw Exception('Error al actualizar producto: $e');
    }
  }

  Future<Map<String, dynamic>> deleteProducto(int id) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiConstants.productos}/$id',
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        return e.response?.data ?? {'message': 'No se puede eliminar'};
      }
      throw Exception('Error al eliminar producto: ${e.message}');
    }
  }
}
