import 'package:frontend/features/auth/data/models/user_model.dart';

class SessionTrabajo {
  final int id;
  final int userId;
  final int ordenTrabajoId;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String? notas;
  final User? user;

  SessionTrabajo({
    required this.id,
    required this.userId,
    required this.ordenTrabajoId,
    required this.fechaInicio,
    this.fechaFin,
    this.notas,
    this.user,
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
      userId: parseInt(json['user_id']) ?? 0,
      ordenTrabajoId: parseInt(json['orden_trabajo_id']) ?? 0,
      fechaInicio: DateTime.parse(json['fecha_inicio']),
      fechaFin: json['fecha_fin'] != null
          ? DateTime.parse(json['fecha_fin'])
          : null,
      notas: json['notas'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sesion_id': id,
      'user_id': userId,
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
