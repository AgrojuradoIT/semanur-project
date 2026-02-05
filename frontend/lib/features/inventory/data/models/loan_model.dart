import 'package:frontend/features/inventory/data/models/product_model.dart';

class PrestamoHerramienta {
  final int id;
  final int productoId;
  final int mecanicoId;
  final int adminId;
  final double cantidad;
  final DateTime fechaPrestamo;
  final DateTime? fechaDevolucion;
  final String estado; // prestado, devuelto, dañado, perdido
  final String? notas;
  final Producto? producto;
  final String? mecanicoNombre;
  final String? adminNombre;

  PrestamoHerramienta({
    required this.id,
    required this.productoId,
    required this.mecanicoId,
    required this.adminId,
    required this.cantidad,
    required this.fechaPrestamo,
    this.fechaDevolucion,
    required this.estado,
    this.notas,
    this.producto,
    this.mecanicoNombre,
    this.adminNombre,
  });

  factory PrestamoHerramienta.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return PrestamoHerramienta(
      id: parseInt(json['prestamo_id']) ?? 0,
      productoId: parseInt(json['producto_id']) ?? 0,
      mecanicoId: parseInt(json['mecanico_id']) ?? 0,
      adminId: parseInt(json['admin_id']) ?? 0,
      cantidad: (json['prestamo_cantidad'] is num)
          ? json['prestamo_cantidad'].toDouble()
          : double.parse(json['prestamo_cantidad'].toString()),
      fechaPrestamo: DateTime.parse(json['fecha_prestamo']),
      fechaDevolucion: json['fecha_devolucion'] != null
          ? DateTime.parse(json['fecha_devolucion'])
          : null,
      estado: json['estado'] ?? 'prestado',
      notas: json['notas'],
      producto: json['producto'] != null
          ? Producto.fromJson(json['producto'])
          : null,
      mecanicoNombre: json['mecanico'] != null
          ? json['mecanico']['name']
          : null,
      adminNombre: json['admin'] != null ? json['admin']['name'] : null,
    );
  }
}
