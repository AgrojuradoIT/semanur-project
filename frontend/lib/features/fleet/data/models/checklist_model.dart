import 'dart:convert';

class ChecklistPreoperacional {
  final int id;
  final int vehiculoId;
  final int empleadoId;
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
    required this.empleadoId,
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

    String parseString(dynamic value, {String fallback = ''}) {
      if (value == null) return fallback;
      if (value is String) return value;
      return value.toString();
    }

    String? parseOptionalString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      return value.toString();
    }

    String? parseVehiculoPlaca(Map<String, dynamic> data) {
      final vehiculo = data['vehiculo'];
      if (vehiculo is Map && vehiculo['placa'] != null) {
        return vehiculo['placa'].toString();
      }
      final direct = data['vehiculo_placa'] ?? data['placa'];
      return parseOptionalString(direct);
    }

    String? parseUsuarioNombre(Map<String, dynamic> data) {
      final usuario = data['usuario'];
      if (usuario is Map && usuario['name'] != null) {
        return usuario['name'].toString();
      }
      final direct = data['usuario_nombre'] ??
          data['nombre_usuario'] ??
          data['user_name'];
      return parseOptionalString(direct);
    }

    DateTime parseDate(dynamic value) {
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.now();
    }

    Map<String, dynamic> parseChecklistData(dynamic value) {
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      if (value is String && value.isNotEmpty) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is Map) {
            return Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      }
      return {};
    }

    return ChecklistPreoperacional(
      id: parseInt(json['id']) ?? 0,
      vehiculoId: parseInt(json['vehiculo_id']) ?? 0,
      empleadoId: parseInt(json['empleado_id']) ?? 0,
      fecha: parseDate(json['fecha'] ?? json['fecha_registro'] ?? json['created_at']),
      horometroActual: json['horometro_actual'] != null
          ? double.parse(json['horometro_actual'].toString())
          : null,
      checklistData: parseChecklistData(json['checklist_data']),
      observaciones: parseOptionalString(json['observaciones']),
      estado: parseString(json['estado'], fallback: 'pendiente'),
      vehiculoPlaca: parseVehiculoPlaca(json),
      usuarioNombre: parseUsuarioNombre(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehiculo_id': vehiculoId,
      'empleado_id': empleadoId,
      'fecha': fecha.toIso8601String(),
      'horometro_actual': horometroActual,
      'checklist_data': checklistData,
      'observaciones': observaciones,
      'estado': estado,
      'vehiculo': vehiculoPlaca != null ? {'placa': vehiculoPlaca} : null,
      'usuario': usuarioNombre != null ? {'name': usuarioNombre} : null,
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
