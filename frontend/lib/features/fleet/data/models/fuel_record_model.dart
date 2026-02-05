class RegistroCombustible {
  final int id;
  final int vehiculoId;
  final int usuarioId;
  final DateTime fecha;
  final double cantidadGalones;
  final double valorTotal;
  final double? horometroActual;
  final double? kilometrajeActual;
  final String? estacionServicio;
  final String? notas;
  final String? vehiculoPlaca;
  final String? usuarioNombre;

  RegistroCombustible({
    required this.id,
    required this.vehiculoId,
    required this.usuarioId,
    required this.fecha,
    required this.cantidadGalones,
    required this.valorTotal,
    this.horometroActual,
    this.kilometrajeActual,
    this.estacionServicio,
    this.notas,
    this.vehiculoPlaca,
    this.usuarioNombre,
  });

  factory RegistroCombustible.fromJson(Map<String, dynamic> json) {
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

    return RegistroCombustible(
      id: parseInt(json['registro_id']) ?? 0,
      vehiculoId: parseInt(json['vehiculo_id']) ?? 0,
      usuarioId: parseInt(json['usuario_id']) ?? 0,
      fecha: DateTime.parse(json['fecha']),
      cantidadGalones: parseDouble(json['cantidad_galones']),
      valorTotal: parseDouble(json['valor_total']),
      horometroActual: json['horometro_actual'] != null
          ? parseDouble(json['horometro_actual'])
          : null,
      kilometrajeActual: json['kilometraje_actual'] != null
          ? parseDouble(json['kilometraje_actual'])
          : null,
      estacionServicio: json['estacion_servicio'],
      notas: json['notas'],
      vehiculoPlaca: json['vehiculo'] != null
          ? json['vehiculo']['placa']
          : null,
      usuarioNombre: json['usuario'] != null ? json['usuario']['name'] : null,
    );
  }
}
