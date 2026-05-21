class PreoperacionalTemplate {
  final int id;
  final String codigo;
  final String nombre;
  final String tipoVehiculo;
  final String? descripcion;
  final String escalaPredeterminada;
  final bool requiereConductor;
  final bool requiereDocumentosVehiculo;
  final bool requiereAprobacion;
  final bool activo;
  final int version;
  final List<PreoperacionalTemplateSection> sections;
  final List<PreoperacionalTemplateItem> items;

  PreoperacionalTemplate({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.tipoVehiculo,
    this.descripcion,
    required this.escalaPredeterminada,
    required this.requiereConductor,
    required this.requiereDocumentosVehiculo,
    required this.requiereAprobacion,
    required this.activo,
    required this.version,
    this.sections = const [],
    this.items = const [],
  });

  factory PreoperacionalTemplate.fromJson(Map<String, dynamic> json) {
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

    final sectionsJson = json['sections'];
    final itemsJson = json['items'];

    List<PreoperacionalTemplateSection> sections = [];
    if (sectionsJson is List) {
      sections = sectionsJson
          .map((s) => PreoperacionalTemplateSection.fromJson(s))
          .toList();
    }

    List<PreoperacionalTemplateItem> items = [];
    if (itemsJson is List) {
      items = itemsJson
          .map((i) => PreoperacionalTemplateItem.fromJson(i))
          .toList();
    }

    // If sections have nested items, flatten them for convenience
    if (items.isEmpty && sections.isNotEmpty) {
      items = sections.expand((s) => s.items).toList();
    }

    return PreoperacionalTemplate(
      id: parseInt(json['id']) ?? 0,
      codigo: json['codigo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      tipoVehiculo: json['tipo_vehiculo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      escalaPredeterminada:
          json['escala_predeterminada']?.toString() ?? 'B_M',
      requiereConductor: parseBool(json['requiere_conductor']),
      requiereDocumentosVehiculo: parseBool(
        json['requiere_documentos_vehiculo'],
      ),
      requiereAprobacion: parseBool(json['requiere_aprobacion']),
      activo: parseBool(json['activo'], fallback: true),
      version: parseInt(json['version']) ?? 1,
      sections: sections,
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'tipo_vehiculo': tipoVehiculo,
      'descripcion': descripcion,
      'escala_predeterminada': escalaPredeterminada,
      'requiere_conductor': requiereConductor,
      'requiere_documentos_vehiculo': requiereDocumentosVehiculo,
      'requiere_aprobacion': requiereAprobacion,
      'activo': activo,
      'version': version,
      'sections': sections.map((s) => s.toJson()).toList(),
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

class PreoperacionalTemplateSection {
  final int id;
  final int templateId;
  final String nombre;
  final String? descripcion;
  final int orden;
  final List<PreoperacionalTemplateItem> items;

  PreoperacionalTemplateSection({
    required this.id,
    required this.templateId,
    required this.nombre,
    this.descripcion,
    required this.orden,
    this.items = const [],
  });

  factory PreoperacionalTemplateSection.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    final itemsJson = json['items'];
    List<PreoperacionalTemplateItem> items = [];
    if (itemsJson is List) {
      items = itemsJson
          .map((i) => PreoperacionalTemplateItem.fromJson(i))
          .toList();
    }

    return PreoperacionalTemplateSection(
      id: parseInt(json['id']) ?? 0,
      templateId: parseInt(json['template_id']) ??
          parseInt(json['preoperacional_template_id']) ??
          0,
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      orden: parseInt(json['orden']) ?? 0,
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'template_id': templateId,
      'nombre': nombre,
      'descripcion': descripcion,
      'orden': orden,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

class PreoperacionalTemplateItem {
  final int id;
  final int templateId;
  final int? sectionId;
  final String? codigo;
  final String pregunta;
  final String tipoRespuesta;
  final List<String>? escalaValores;
  final bool esCritico;
  final bool requiereObservacionSiFalla;
  final int orden;

  PreoperacionalTemplateItem({
    required this.id,
    required this.templateId,
    this.sectionId,
    this.codigo,
    required this.pregunta,
    required this.tipoRespuesta,
    this.escalaValores,
    required this.esCritico,
    required this.requiereObservacionSiFalla,
    required this.orden,
  });

  factory PreoperacionalTemplateItem.fromJson(Map<String, dynamic> json) {
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

    List<String>? parseEscalaValores(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      if (value is String && value.isNotEmpty) {
        try {
          return value.split(',').map((e) => e.trim()).toList();
        } catch (_) {}
      }
      return null;
    }

    return PreoperacionalTemplateItem(
      id: parseInt(json['id']) ?? 0,
      templateId: parseInt(json['template_id']) ??
          parseInt(json['preoperacional_template_id']) ??
          0,
      sectionId: parseInt(json['section_id']) ??
          parseInt(json['preoperacional_template_section_id']),
      codigo: json['codigo']?.toString(),
      pregunta: json['pregunta']?.toString() ?? '',
      tipoRespuesta: json['tipo_respuesta']?.toString() ?? 'escala',
      escalaValores: parseEscalaValores(json['escala_valores']),
      esCritico: parseBool(json['es_critico']),
      requiereObservacionSiFalla: parseBool(
        json['requiere_observacion_si_falla'],
      ),
      orden: parseInt(json['orden']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'template_id': templateId,
      'section_id': sectionId,
      'codigo': codigo,
      'pregunta': pregunta,
      'tipo_respuesta': tipoRespuesta,
      'escala_valores': escalaValores,
      'es_critico': esCritico,
      'requiere_observacion_si_falla': requiereObservacionSiFalla,
      'orden': orden,
    };
  }
}
