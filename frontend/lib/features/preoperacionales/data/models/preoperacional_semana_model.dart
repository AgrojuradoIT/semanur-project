import 'dart:convert';

import 'preoperacional_template_model.dart';

class PreoperacionalSemana {
  final int id;
  final int vehiculoId;
  final int templateId;
  final int inspectorId;
  final DateTime semanaInicio;
  final DateTime semanaFin;
  final int semanaNumero;
  final int semanaAnio;
  final String? vehiculoMarca;
  final String? vehiculoModelo;
  final String vehiculoPlaca;
  final Map<String, dynamic>? conductorSnapshot;
  final Map<String, dynamic>? documentosVehiculoSnapshot;
  final bool fueraDeServicio;
  final String? motivoFueraServicio;
  final String? observacionesGenerales;
  final String estado;
  final String inspectorNombre;
  final String? inspectorCargo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PreoperacionalTemplate? template;
  final List<PreoperacionalDailyForm> dailyForms;

  PreoperacionalSemana({
    required this.id,
    required this.vehiculoId,
    required this.templateId,
    required this.inspectorId,
    required this.semanaInicio,
    required this.semanaFin,
    required this.semanaNumero,
    required this.semanaAnio,
    this.vehiculoMarca,
    this.vehiculoModelo,
    required this.vehiculoPlaca,
    this.conductorSnapshot,
    this.documentosVehiculoSnapshot,
    required this.fueraDeServicio,
    this.motivoFueraServicio,
    this.observacionesGenerales,
    required this.estado,
    required this.inspectorNombre,
    this.inspectorCargo,
    required this.createdAt,
    required this.updatedAt,
    this.template,
    this.dailyForms = const [],
  });

  factory PreoperacionalSemana.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    bool parseBool(dynamic value, {bool fallback = false}) {
      if (value == null) return fallback;
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) {
        final lower = value.toLowerCase();
        return lower == 'true' || lower == '1' || lower == 'yes';
      }
      return fallback;
    }

    DateTime parseDate(dynamic value, {DateTime? fallback}) {
      if (value is String && value.isNotEmpty) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      return fallback ?? DateTime.now();
    }

    Map<String, dynamic>? parseSnapshot(dynamic value) {
      if (value == null) return null;
      if (value is Map) return Map<String, dynamic>.from(value);
      if (value is String && value.isNotEmpty) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } catch (_) {}
      }
      return null;
    }

    String parseString(dynamic value, {String fallback = ''}) {
      if (value == null) return fallback;
      if (value is String) return value;
      return value.toString();
    }

    final dailyFormsJson = json['daily_forms'] ?? json['formularios_diarios'];
    List<PreoperacionalDailyForm> dailyForms = [];
    if (dailyFormsJson is List) {
      dailyForms = dailyFormsJson
          .map((d) => PreoperacionalDailyForm.fromJson(d))
          .toList();
    }

    PreoperacionalTemplate? template;
    final templateJson = json['template'];
    if (templateJson != null && templateJson is Map) {
      template = PreoperacionalTemplate.fromJson(
        Map<String, dynamic>.from(templateJson),
      );
    }

    // Handle nested vehiculo data for placa/marca/modelo
    String vehiculoPlaca = parseString(json['vehiculo_placa']);
    String? vehiculoMarca = json['vehiculo_marca']?.toString();
    String? vehiculoModelo = json['vehiculo_modelo']?.toString();

    final vehiculoJson = json['vehiculo'];
    if (vehiculoJson is Map) {
      if (vehiculoPlaca.isEmpty) {
        vehiculoPlaca = parseString(vehiculoJson['placa']);
      }
      vehiculoMarca ??= vehiculoJson['marca']?.toString();
      vehiculoModelo ??= vehiculoJson['modelo']?.toString();
    }

    // Handle nested inspector data
    String inspectorNombre = parseString(json['inspector_nombre']);
    String? inspectorCargo = json['inspector_cargo']?.toString();

    final inspectorJson = json['inspector'];
    if (inspectorJson is Map) {
      if (inspectorNombre.isEmpty) {
        inspectorNombre = parseString(
          inspectorJson['nombre'] ??
              inspectorJson['nombres'] ??
              inspectorJson['name'],
        );
      }
      inspectorCargo ??= inspectorJson['cargo']?.toString();
    }

    return PreoperacionalSemana(
      id: parseInt(json['id']) ?? 0,
      vehiculoId: parseInt(json['vehiculo_id']) ?? 0,
      templateId: parseInt(json['template_id']) ?? 0,
      inspectorId: parseInt(json['inspector_id']) ?? 0,
      semanaInicio: parseDate(json['semana_inicio']),
      semanaFin: parseDate(json['semana_fin']),
      semanaNumero: parseInt(json['semana_numero']) ?? 0,
      semanaAnio: parseInt(json['semana_anio']) ?? 0,
      vehiculoMarca: vehiculoMarca,
      vehiculoModelo: vehiculoModelo,
      vehiculoPlaca: vehiculoPlaca,
      conductorSnapshot: parseSnapshot(json['conductor_snapshot']),
      documentosVehiculoSnapshot: parseSnapshot(
        json['documentos_vehiculo_snapshot'],
      ),
      fueraDeServicio: parseBool(json['fuera_de_servicio']),
      motivoFueraServicio: json['motivo_fuera_servicio']?.toString(),
      observacionesGenerales: json['observaciones_generales']?.toString(),
      estado: parseString(json['estado'], fallback: 'pendiente'),
      inspectorNombre: inspectorNombre,
      inspectorCargo: inspectorCargo,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      template: template,
      dailyForms: dailyForms,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehiculo_id': vehiculoId,
      'template_id': templateId,
      'inspector_id': inspectorId,
      'semana_inicio': semanaInicio.toIso8601String(),
      'semana_fin': semanaFin.toIso8601String(),
      'semana_numero': semanaNumero,
      'semana_anio': semanaAnio,
      'vehiculo_placa': vehiculoPlaca,
      'vehiculo_marca': vehiculoMarca,
      'vehiculo_modelo': vehiculoModelo,
      'conductor_snapshot': conductorSnapshot,
      'documentos_vehiculo_snapshot': documentosVehiculoSnapshot,
      'fuera_de_servicio': fueraDeServicio,
      'motivo_fuera_servicio': motivoFueraServicio,
      'observaciones_generales': observacionesGenerales,
      'estado': estado,
      'inspector_nombre': inspectorNombre,
      'inspector_cargo': inspectorCargo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'template': template?.toJson(),
      'daily_forms': dailyForms.map((d) => d.toJson()).toList(),
    };
  }

  /// Returns true if all daily forms are completed
  bool get isCompletado =>
      dailyForms.isNotEmpty &&
      dailyForms.every((df) => df.completado);

  /// Returns true if at least one daily form is completed
  bool get enProgreso => dailyForms.any((df) => df.completado);

  /// Returns the number of completed daily forms
  int get completedDays =>
      dailyForms.where((df) => df.completado).length;
}

class PreoperacionalDailyForm {
  final int id;
  final int semanaId;
  final String diaSemana;
  final DateTime fecha;
  final bool completado;
  final String? observacionesDia;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PreoperacionalFormResponse>? responses;

  PreoperacionalDailyForm({
    required this.id,
    required this.semanaId,
    required this.diaSemana,
    required this.fecha,
    required this.completado,
    this.observacionesDia,
    required this.createdAt,
    required this.updatedAt,
    this.responses,
  });

  factory PreoperacionalDailyForm.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    bool parseBool(dynamic value, {bool fallback = false}) {
      if (value == null) return fallback;
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) {
        final lower = value.toLowerCase();
        return lower == 'true' || lower == '1' || lower == 'yes';
      }
      return fallback;
    }

    DateTime parseDate(dynamic value, {DateTime? fallback}) {
      if (value is String && value.isNotEmpty) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      return fallback ?? DateTime.now();
    }

    final responsesJson = json['responses'] ?? json['respuestas'];
    List<PreoperacionalFormResponse>? responses;
    if (responsesJson is List && responsesJson.isNotEmpty) {
      responses = responsesJson
          .map((r) => PreoperacionalFormResponse.fromJson(r))
          .toList();
    }

    return PreoperacionalDailyForm(
      id: parseInt(json['id']) ?? 0,
      semanaId: parseInt(json['semana_id']) ??
          parseInt(json['preoperacional_semana_id']) ??
          0,
      diaSemana: json['dia_semana']?.toString() ?? '',
      fecha: parseDate(json['fecha']),
      completado: parseBool(json['completado']),
      observacionesDia: json['observaciones_dia']?.toString(),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      responses: responses,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'semana_id': semanaId,
      'dia_semana': diaSemana,
      'fecha': fecha.toIso8601String(),
      'completado': completado,
      'observaciones_dia': observacionesDia,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'responses': responses?.map((r) => r.toJson()).toList(),
    };
  }
}

class PreoperacionalFormResponse {
  final int id;
  final int dailyFormId;
  final int itemId;
  final String estado;
  final String? observacion;
  final String? fotoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  PreoperacionalFormResponse({
    required this.id,
    required this.dailyFormId,
    required this.itemId,
    required this.estado,
    this.observacion,
    this.fotoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PreoperacionalFormResponse.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    DateTime parseDate(dynamic value, {DateTime? fallback}) {
      if (value is String && value.isNotEmpty) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      return fallback ?? DateTime.now();
    }

    return PreoperacionalFormResponse(
      id: parseInt(json['id']) ?? 0,
      dailyFormId: parseInt(json['daily_form_id']) ??
          parseInt(json['preoperacional_daily_form_id']) ??
          0,
      itemId: parseInt(json['item_id']) ??
          parseInt(json['preoperacional_template_item_id']) ??
          0,
      estado: json['estado']?.toString() ?? '',
      observacion: json['observacion']?.toString(),
      fotoUrl: json['foto_url']?.toString(),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'daily_form_id': dailyFormId,
      'item_id': itemId,
      'estado': estado,
      'observacion': observacion,
      'foto_url': fotoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Returns true if the response indicates a passing/ok state
  bool get isOk => estado == 'B';

  /// Returns true if the response indicates a failure/bad state
  bool get isFailed =>
      estado == 'M' || estado == 'C' || estado == 'NC' || estado == 'N';

  /// Returns true if the response was skipped or not applicable
  bool get isSkipped => estado == 'A';
}
