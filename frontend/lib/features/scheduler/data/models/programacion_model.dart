class Programacion {
  final int id;
  final DateTime fecha;
  final int empleadoId;
  final int? vehiculoId;
  final String labor;
  final String? ubicacion;
  final String estado; // 'pendiente', 'en_progreso', 'pausado', 'completado'
  final int? ordenTrabajoId;
  final bool esNovedad;

  // Relaciones (opcionales, se llenan si vienen en el JSON)
  final dynamic empleado; // User?
  final dynamic vehiculo; // Vehiculo?
  final dynamic ordenTrabajo; // OrdenTrabajo?

  Programacion({
    required this.id,
    required this.fecha,
    required this.empleadoId,
    this.vehiculoId,
    required this.labor,
    this.ubicacion,
    required this.estado,
    this.ordenTrabajoId,
    this.esNovedad = false,
    this.empleado,
    this.vehiculo,
    this.ordenTrabajo,
  });

  factory Programacion.fromJson(Map<String, dynamic> json) {
    return Programacion(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      fecha: DateTime.parse(json['fecha']),
      empleadoId: json['empleado_id'] is int
          ? json['empleado_id']
          : int.tryParse(json['empleado_id'].toString()) ?? 0,
      vehiculoId: json['vehiculo_id'] != null
          ? (json['vehiculo_id'] is int
                ? json['vehiculo_id']
                : int.tryParse(json['vehiculo_id'].toString()))
          : null,
      labor: json['labor'].toString(),
      ubicacion: json['ubicacion']?.toString(),
      estado: json['estado'].toString(),
      ordenTrabajoId: json['orden_trabajo_id'] != null
          ? (json['orden_trabajo_id'] is int
                ? json['orden_trabajo_id']
                : int.tryParse(json['orden_trabajo_id'].toString()))
          : null,
      esNovedad:
          json['es_novedad'] == 1 ||
          json['es_novedad'] == true ||
          json['es_novedad'] == '1',
      empleado: json['empleado'],
      vehiculo: json['vehiculo'],
      ordenTrabajo: json['orden_trabajo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String().split('T')[0],
      'empleado_id': empleadoId,
      'vehiculo_id': vehiculoId,
      'labor': labor,
      'ubicacion': ubicacion,
      'estado': estado,
      'orden_trabajo_id': ordenTrabajoId,
      'es_novedad': esNovedad,
    };
  }
}
