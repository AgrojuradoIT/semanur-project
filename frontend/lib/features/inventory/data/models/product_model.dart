import 'category_model.dart';

class Producto {
  final int id;
  final int? categoriaId;
  final String sku;
  final String nombre;
  final String? unidadMedida;
  final double stockActual;
  final double alertaStockMinimo;
  final double? capacidadMaxima;
  final double? precioCosto;
  final String? ubicacion;
  final Categoria? categoria;

  Producto({
    required this.id,
    this.categoriaId,
    required this.sku,
    required this.nombre,
    this.unidadMedida,
    required this.stockActual,
    required this.alertaStockMinimo,
    this.capacidadMaxima,
    this.precioCosto,
    this.ubicacion,
    this.categoria,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    try {
      return Producto(
        id: parseInt(json['producto_id']) ?? 0,
        categoriaId: parseInt(json['categoria_id']),
        sku: json['producto_sku'] ?? '',
        nombre: json['producto_nombre'] ?? '',
        unidadMedida: json['producto_unidad_medida'],
        stockActual: parseDouble(json['producto_stock_actual']),
        alertaStockMinimo: parseDouble(json['producto_alerta_stock_minimo']),
        capacidadMaxima: json['capacidad_maxima'] != null
            ? parseDouble(json['capacidad_maxima'])
            : null,
        precioCosto: json['producto_precio_costo'] != null
            ? parseDouble(json['producto_precio_costo'])
            : null,
        ubicacion: json['producto_ubicacion'],
        categoria: json['categoria'] != null
            ? Categoria.fromJson(json['categoria'])
            : null,
      );
    } catch (e, stack) {
      print('ERROR PARSEANDO PRODUCTO ${json['producto_nombre']}: $e');
      print(stack);
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'producto_id': id,
      'categoria_id': categoriaId,
      'producto_sku': sku,
      'producto_nombre': nombre,
      'producto_unidad_medida': unidadMedida,
      'producto_stock_actual': stockActual,
      'producto_alerta_stock_minimo': alertaStockMinimo,
      'capacidad_maxima': capacidadMaxima,
      'producto_precio_costo': precioCosto,
      'producto_ubicacion': ubicacion,
      'categoria': categoria?.toJson(),
    };
  }
}
