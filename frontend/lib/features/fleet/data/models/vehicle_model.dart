import 'package:frontend/features/workshop/data/models/work_order_model.dart';
import 'package:frontend/features/inventory/data/models/movement_model.dart';

class Vehiculo {
  final int id;
  final String placa;
  final String tipo;
  final String marca;
  final String modelo;
  final double horometroActual;
  final double? horometroProximoMantenimiento;
  final double kilometrajeActual;
  final double? kilometrajeProximoMantenimiento;
  final DateTime? fechaVencimientoSoat;
  final DateTime? fechaVencimientoTecnomecanica;
  final List<OrdenTrabajo>? ordenesTrabajo;
  final List<MovimientoInventario>? movimientosDirectos;

  Vehiculo({
    required this.id,
    required this.placa,
    required this.tipo,
    required this.marca,
    required this.modelo,
    this.horometroActual = 0,
    this.horometroProximoMantenimiento,
    this.kilometrajeActual = 0,
    this.kilometrajeProximoMantenimiento,
    this.fechaVencimientoSoat,
    this.fechaVencimientoTecnomecanica,
    this.ordenesTrabajo,
    this.movimientosDirectos,
  });

  factory Vehiculo.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return Vehiculo(
      id: parseInt(json['vehiculo_id']) ?? 0,
      placa: json['placa'] ?? '',
      tipo: json['tipo'] ?? '',
      marca: json['marca'] ?? '',
      modelo: json['modelo'] ?? '',
      horometroActual: (json['horometro_actual'] is num)
          ? json['horometro_actual'].toDouble()
          : double.parse(json['horometro_actual']?.toString() ?? '0'),
      horometroProximoMantenimiento:
          (json['horometro_proximo_mantenimiento'] != null)
          ? (json['horometro_proximo_mantenimiento'] is num
                ? json['horometro_proximo_mantenimiento'].toDouble()
                : double.parse(
                    json['horometro_proximo_mantenimiento'].toString(),
                  ))
          : null,
      kilometrajeActual: (json['kilometraje_actual'] is num)
          ? json['kilometraje_actual'].toDouble()
          : double.parse(json['kilometraje_actual']?.toString() ?? '0'),
      kilometrajeProximoMantenimiento:
          (json['kilometraje_proximo_mantenimiento'] != null)
          ? (json['kilometraje_proximo_mantenimiento'] is num
                ? json['kilometraje_proximo_mantenimiento'].toDouble()
                : double.parse(
                    json['kilometraje_proximo_mantenimiento'].toString(),
                  ))
          : null,
      fechaVencimientoSoat: json['fecha_vencimiento_soat'] != null
          ? DateTime.tryParse(json['fecha_vencimiento_soat'])
          : null,
      fechaVencimientoTecnomecanica:
          json['fecha_vencimiento_tecnomecanica'] != null
          ? DateTime.tryParse(json['fecha_vencimiento_tecnomecanica'])
          : null,
      ordenesTrabajo: json['ordenes_trabajo'] != null
          ? (json['ordenes_trabajo'] as List)
                .map((o) => OrdenTrabajo.fromJson(o))
                .toList()
          : null,
      movimientosDirectos: json['movimientos_directos'] != null
          ? (json['movimientos_directos'] as List)
                .map((m) => MovimientoInventario.fromJson(m))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehiculo_id': id,
      'placa': placa,
      'tipo': tipo,
      'marca': marca,
      'modelo': modelo,
      'horometro_actual': horometroActual,
      'horometro_proximo_mantenimiento': horometroProximoMantenimiento,
      'kilometraje_actual': kilometrajeActual,
      'kilometraje_proximo_mantenimiento': kilometrajeProximoMantenimiento,
      'fecha_vencimiento_soat': fechaVencimientoSoat?.toIso8601String().split(
        'T',
      )[0],
      'fecha_vencimiento_tecnomecanica': fechaVencimientoTecnomecanica
          ?.toIso8601String()
          .split('T')[0],
    };
  }
}
