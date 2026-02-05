class ChecklistPreoperacional {
  final int id;
  final int vehiculoId;
  final int usuarioId;
  final DateTime fecha;
  final double? horometroActual;
  final Map<String, dynamic> checklistData;
  final String? observaciones;
  final String estado;
  final String? vehiculoPlaca;
  final String? usuarioNombre;

  final String? fotoEvidencia;

  ChecklistPreoperacional({
    required this.id,
    required this.vehiculoId,
    required this.usuarioId,
    required this.fecha,
    this.horometroActual,
    required this.checklistData,
    this.observaciones,
    required this.estado,
    this.vehiculoPlaca,
    this.usuarioNombre,
    this.fotoEvidencia,
  });

  factory ChecklistPreoperacional.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return ChecklistPreoperacional(
      id: parseInt(json['id']) ?? 0,
      vehiculoId: parseInt(json['vehiculo_id']) ?? 0,
      usuarioId: parseInt(json['usuario_id']) ?? 0,
      fecha: DateTime.parse(json['fecha']),
      horometroActual: json['horometro_actual'] != null
          ? double.parse(json['horometro_actual'].toString())
          : null,
      checklistData: Map<String, dynamic>.from(json['checklist_data']),
      observaciones: json['observaciones'],
      estado: json['estado'],
      vehiculoPlaca: json['vehiculo']?['placa'],
      usuarioNombre: json['usuario']?['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehiculo_id': vehiculoId,
      'horometro_actual': horometroActual,
      'checklist_data': checklistData,
      'observaciones': observaciones,
      'estado': estado,
    };
  }

  bool get hasAlert {
    if (estado.toLowerCase() != 'aprobado') return true;
    // Also check if any item in checklistData is false (assuming false = bad)
    // The current logic in screen uses true=Good, false=Bad
    if (checklistData.containsValue(false)) return true;
    return false;
  }
}
