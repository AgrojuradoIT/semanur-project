import 'package:frontend/features/inventory/data/models/product_model.dart';

class MovimientoInventario {
  final int id;
  final int productoId;
  final int usuarioId;
  final String tipo; // ingreso, salida
  final double cantidad;
  final String motivo;
  final String? referenciaType;
  final int? referenciaId;
  final String? notas;
  final DateTime createdAt;
  final Producto? producto;
  final String? usuarioNombre;

  MovimientoInventario({
    required this.id,
    required this.productoId,
    required this.usuarioId,
    required this.tipo,
    required this.cantidad,
    required this.motivo,
    this.referenciaType,
    this.referenciaId,
    this.notas,
    required this.createdAt,
    this.producto,
    this.usuarioNombre,
  });

  factory MovimientoInventario.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return MovimientoInventario(
      id: parseInt(json['transaccion_id']) ?? 0,
      productoId: parseInt(json['producto_id']) ?? 0,
      usuarioId: parseInt(json['usuario_id']) ?? 0,
      tipo: json['transaccion_tipo'],
      cantidad: (json['transaccion_cantidad'] is num)
          ? json['transaccion_cantidad'].toDouble()
          : double.parse(json['transaccion_cantidad'].toString()),
      motivo: json['transaccion_motivo'] ?? '',
      referenciaType: json['transaccion_referencia_type'],
      referenciaId: parseInt(json['transaccion_referencia_id']),
      notas: json['transaccion_notas'],
      createdAt: DateTime.parse(json['created_at']),
      producto: json['producto'] != null
          ? Producto.fromJson(json['producto'])
          : null,
      usuarioNombre: json['usuario'] != null ? json['usuario']['name'] : null,
    );
  }
}
