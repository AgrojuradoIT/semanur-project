import 'package:frontend/features/fleet/data/models/vehicle_model.dart';
import 'package:frontend/features/inventory/data/models/movement_model.dart';
import 'package:frontend/features/auth/data/models/user_model.dart';
import 'session_model.dart';

class OrdenTrabajo {
  final int id;
  final int vehiculoId;
  final int? mecanicoAsignadoId;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String estado;
  final String prioridad;
  final String descripcion;
  final Vehiculo? vehiculo;
  final List<MovimientoInventario>? movimientosInventario;
  final List<SessionTrabajo>? sesiones;
  final User? mecanico;
  final String? fotoEvidencia;

  OrdenTrabajo({
    required this.id,
    required this.vehiculoId,
    this.mecanicoAsignadoId,
    required this.fechaInicio,
    this.fechaFin,
    required this.estado,
    required this.prioridad,
    required this.descripcion,
    this.vehiculo,
    this.movimientosInventario,
    this.sesiones,
    this.mecanico,
    this.fotoEvidencia,
  });

  factory OrdenTrabajo.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return OrdenTrabajo(
      id: parseInt(json['orden_trabajo_id']) ?? 0,
      vehiculoId: parseInt(json['vehiculo_id']) ?? 0,
      mecanicoAsignadoId: parseInt(json['mecanico_asignado_id']),
      fechaInicio: DateTime.parse(json['fecha_inicio']),
      fechaFin: json['fecha_fin'] != null
          ? DateTime.parse(json['fecha_fin'])
          : null,
      estado: json['estado'] ?? 'Abierta',
      prioridad: json['prioridad'] ?? 'Media',
      descripcion: json['descripcion'] ?? '',
      fotoEvidencia: json['foto_evidencia'],
      vehiculo: json['vehiculo'] != null
          ? Vehiculo.fromJson(json['vehiculo'])
          : null,
      movimientosInventario: json['movimientos_inventario'] != null
          ? (json['movimientos_inventario'] as List)
                .map((m) => MovimientoInventario.fromJson(m))
                .toList()
          : null,
      sesiones: json['sesiones'] != null
          ? (json['sesiones'] as List)
                .map((s) => SessionTrabajo.fromJson(s))
                .toList()
          : null,
      mecanico: json['mecanico'] != null
          ? User.fromJson(json['mecanico'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orden_trabajo_id': id,
      'vehiculo_id': vehiculoId,
      'mecanico_asignado_id': mecanicoAsignadoId,
      'fecha_inicio': fechaInicio.toIso8601String(),
      'fecha_fin': fechaFin?.toIso8601String(),
      'estado': estado,
      'prioridad': prioridad,
      'descripcion': descripcion,
      'vehiculo': vehiculo?.toJson(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrdenTrabajo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
