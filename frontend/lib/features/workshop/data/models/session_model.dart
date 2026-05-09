import 'package:frontend/features/auth/data/models/empleado_model.dart';
import 'package:timezone/timezone.dart' as tz;

class SessionTrabajo {
  final int id;
  final int empleadoId;
  final int ordenTrabajoId;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String? notas;
  final Empleado? empleado;

  SessionTrabajo({
    required this.id,
    required this.empleadoId,
    required this.ordenTrabajoId,
    required this.fechaInicio,
    this.fechaFin,
    this.notas,
    this.empleado,
  });

  factory SessionTrabajo.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return SessionTrabajo(
      id: parseInt(json['sesion_id']) ?? 0,
      empleadoId: parseInt(json['empleado_id']) ?? 0,
      ordenTrabajoId: parseInt(json['orden_trabajo_id']) ?? 0,
      fechaInicio: _parseDateTime(json['fecha_inicio']),
      fechaFin: json['fecha_fin'] != null
          ? _parseDateTime(json['fecha_fin'])
          : null,
      notas: json['notas'],
      empleado: json['empleado'] != null ? Empleado.fromJson(json['empleado']) : null,
    );
  }

  /// Parsea fecha ISO 8601 manteniendo la hora de Bogotá
  static DateTime _parseDateTime(String dateString) {
    final dateTime = DateTime.parse(dateString);
    final bogota = tz.getLocation('America/Bogota');
    final tzDateTime = tz.TZDateTime.from(dateTime, bogota);
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

  Map<String, dynamic> toJson() {
    return {
      'sesion_id': id,
      'empleado_id': empleadoId,
      'orden_trabajo_id': ordenTrabajoId,
      'fecha_inicio': fechaInicio.toIso8601String(),
      'fecha_fin': fechaFin?.toIso8601String(),
      'notas': notas,
    };
  }

  Duration get duration {
    final end = fechaFin ?? DateTime.now();
    return end.difference(fechaInicio);
  }
}
