class Checklist {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? tipoVehiculo;
  final bool activo;
  final List<ChecklistItem> items;

  Checklist({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.tipoVehiculo,
    required this.activo,
    required this.items,
  });

  factory Checklist.fromJson(Map<String, dynamic> json) {
    return Checklist(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      tipoVehiculo: json['tipo_vehiculo'],
      activo: json['activo'] == 1 || json['activo'] == true,
      items:
          (json['items'] as List?)
              ?.map((i) => ChecklistItem.fromJson(i))
              .toList() ??
          [],
    );
  }
}

class ChecklistItem {
  final int id;
  final int checklistId;
  final String pregunta;
  final String tipoRespuesta; // 'cumple_falla', 'texto', 'numero'
  final int orden;
  final bool esCritico;

  ChecklistItem({
    required this.id,
    required this.checklistId,
    required this.pregunta,
    required this.tipoRespuesta,
    required this.orden,
    required this.esCritico,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'],
      checklistId: json['lista_chequeo_id'],
      pregunta: json['pregunta'],
      tipoRespuesta: json['tipo_respuesta'],
      orden: json['orden'],
      esCritico: json['es_critico'] == 1 || json['es_critico'] == true,
    );
  }
}

class ChecklistResponse {
  final int id;
  final int checklistId;
  final int vehiculoId;
  final int operadorId;
  final DateTime fecha;
  final Map<String, dynamic> respuestas;
  final String estado;
  final String? observaciones;

  ChecklistResponse({
    required this.id,
    required this.checklistId,
    required this.vehiculoId,
    required this.operadorId,
    required this.fecha,
    required this.respuestas,
    required this.estado,
    this.observaciones,
  });

  factory ChecklistResponse.fromJson(Map<String, dynamic> json) {
    return ChecklistResponse(
      id: json['id'],
      checklistId: json['lista_chequeo_id'],
      vehiculoId: json['vehiculo_id'],
      operadorId: json['operador_id'],
      fecha: DateTime.parse(json['fecha']),
      respuestas: Map<String, dynamic>.from(json['respuestas']),
      estado: json['estado'],
      observaciones: json['observaciones_generales'],
    );
  }
}
