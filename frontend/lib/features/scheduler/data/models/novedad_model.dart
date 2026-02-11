class Novedad {
  final int? id;
  final DateTime fecha;
  final int empleadoId;
  final int? vehiculoId;
  final String descripcion;
  final String prioridad;
  final bool pausarActividad;
  final int? ordenTrabajoId;

  Novedad({
    this.id,
    required this.fecha,
    required this.empleadoId,
    this.vehiculoId,
    required this.descripcion,
    this.prioridad = 'Normal',
    this.pausarActividad = false,
    this.ordenTrabajoId,
  });

  factory Novedad.fromJson(Map<String, dynamic> json) {
    return Novedad(
      id: json['id'],
      fecha: DateTime.parse(json['fecha']),
      empleadoId: json['empleado_id'],
      vehiculoId: json['vehiculo_id'],
      descripcion: json['descripcion'] ?? '',
      prioridad: json['prioridad'] ?? 'Normal',
      pausarActividad:
          json['pausar_actividad'] == 1 || json['pausar_actividad'] == true,
      ordenTrabajoId: json['orden_trabajo_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String().split('T')[0],
      'empleado_id': empleadoId,
      'vehiculo_id': vehiculoId,
      'descripcion': descripcion,
      'prioridad': prioridad,
      'pausar_actividad': pausarActividad,
      'orden_trabajo_id': ordenTrabajoId,
    };
  }
}
