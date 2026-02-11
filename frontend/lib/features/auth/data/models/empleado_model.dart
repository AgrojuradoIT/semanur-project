class Empleado {
  final int id;
  final String nombres;
  final String apellidos;
  final String? documento;
  final String? telefono;
  final String? direccion;
  final String? cargo;
  final String? dependencia;
  final String? licenciaConduccion;
  final String? categoriaLicencia;
  final DateTime? vencimientoLicencia;
  final String? fotoUrl;
  final int? userId;
  final String estado;

  final String? resumenProfesional;

  Empleado({
    required this.id,
    required this.nombres,
    this.apellidos = '',
    this.documento,
    this.telefono,
    this.direccion,
    this.cargo,
    this.dependencia,
    this.licenciaConduccion,
    this.categoriaLicencia,
    this.vencimientoLicencia,
    this.fotoUrl,
    this.userId,
    this.estado = 'activo',
    this.resumenProfesional,
  });

  String get nombreCompleto => '$nombres $apellidos'.trim();

  factory Empleado.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return Empleado(
      id: parseInt(json['id']) ?? 0,
      nombres: json['nombres'] ?? '',
      apellidos: json['apellidos'] ?? '',
      documento: json['documento'],
      telefono: json['telefono'],
      direccion: json['direccion'],
      cargo: json['cargo'],
      dependencia: json['dependencia'],
      licenciaConduccion: json['licencia_conduccion'],
      categoriaLicencia: json['categoria_licencia'],
      vencimientoLicencia: json['vencimiento_licencia'] != null
          ? DateTime.tryParse(json['vencimiento_licencia'])
          : null,
      fotoUrl: json['foto_url'],
      userId: parseInt(json['user_id']),
      estado: json['estado'] ?? 'activo',
      resumenProfesional: json['resumen_profesional'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombres': nombres,
      'apellidos': apellidos,
      'documento': documento,
      'telefono': telefono,
      'direccion': direccion,
      'cargo': cargo,
      'dependencia': dependencia,
      'licencia_conduccion': licenciaConduccion,
      'categoria_licencia': categoriaLicencia,
      'vencimiento_licencia': vencimientoLicencia?.toIso8601String().split(
        'T',
      )[0],
      'foto_url': fotoUrl,
      'user_id': userId,
      'estado': estado,
      'resumen_profesional': resumenProfesional,
    };
  }
}
