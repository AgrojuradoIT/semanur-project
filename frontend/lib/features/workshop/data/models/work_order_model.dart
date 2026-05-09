import 'package:frontend/features/fleet/data/models/vehicle_model.dart';
import 'package:frontend/features/inventory/data/models/movement_model.dart';
import 'package:frontend/features/auth/data/models/empleado_model.dart';
import 'package:frontend/features/workshop/data/models/session_model.dart';
import 'package:timezone/timezone.dart' as tz;

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
  final Empleado? mecanico;
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
      fechaInicio: _parseDateTime(json['fecha_inicio']),
      fechaFin: json['fecha_fin'] != null
          ? _parseDateTime(json['fecha_fin'])
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
          ? Empleado.fromJson(json['mecanico'])
          : null,
    );
  }

  /// Parsea fecha ISO 8601 de la API (viene en America/Bogota UTC-5)
  /// Usamos timezone package para mantener la hora correcta de Bogotá
  static DateTime _parseDateTime(String dateString) {
    // Parsear la fecha ISO 8601
    final dateTime = DateTime.parse(dateString);
    
    // Obtener timezone de Bogotá
    final bogota = tz.getLocation('America/Bogota');
    
    // Crear TZDateTime en Bogotá - esto mantiene la hora local de Bogotá
    final tzDateTime = tz.TZDateTime.from(dateTime, bogota);
    
    // Convertir a DateTime normal pero manteniendo la hora de Bogotá
    // Esto es importante para que al formatear muestre la hora correcta
    return DateTime(
      tzDateTime.year,
      tzDateTime.month,
      tzDateTime.day,
      tzDateTime.hour,
      tzDateTime.minute,
      tzDateTime.second,
      tzDateTime.millisecond,
      tzDateTime.microsecond,
    );
  }

  /// Obtiene la fecha de inicio formateada para mostrar (timezone Bogotá)
  String get fechaInicioString {
    return _formatDateTime(fechaInicio);
  }

  /// Obtiene la fecha de fin formateada para mostrar (timezone Bogotá)
  String? get fechaFinString {
    return fechaFin != null ? _formatDateTime(fechaFin!) : null;
  }

  /// Formatea una fecha en formato dd/MM/yyyy hh:mm A
  String _formatDateTime(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
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
