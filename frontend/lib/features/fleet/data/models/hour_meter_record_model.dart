import 'package:frontend/features/auth/data/models/user_model.dart';

class RegistroHorometro {
  final int id;
  final int vehiculoId;
  final double valorAnterior;
  final double valorNuevo;
  final int usuarioId;
  final String? notas;
  final DateTime createdAt;
  final User? usuario;

  RegistroHorometro({
    required this.id,
    required this.vehiculoId,
    required this.valorAnterior,
    required this.valorNuevo,
    required this.usuarioId,
    this.notas,
    required this.createdAt,
    this.usuario,
  });

  factory RegistroHorometro.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return RegistroHorometro(
      id: parseInt(json['registro_horometro_id']) ?? 0,
      vehiculoId: parseInt(json['vehiculo_id']) ?? 0,
      valorAnterior: (json['valor_anterior'] is num)
          ? json['valor_anterior'].toDouble()
          : double.parse(json['valor_anterior'].toString()),
      valorNuevo: (json['valor_nuevo'] is num)
          ? json['valor_nuevo'].toDouble()
          : double.parse(json['valor_nuevo'].toString()),
      usuarioId: parseInt(json['usuario_id']) ?? 0,
      notas: json['notas'],
      createdAt: DateTime.parse(json['created_at']),
      usuario: json['usuario'] != null ? User.fromJson(json['usuario']) : null,
    );
  }
}
