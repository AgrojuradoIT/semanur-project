import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../data/models/programacion_model.dart';
import '../../data/repositories/programacion_repository.dart';

class ProgramacionProvider with ChangeNotifier {
  final ProgramacionRepository _repository;

  List<Programacion> _programacion = [];
  bool _isLoading = false;
  String? _error;

  ProgramacionProvider(this._repository);

  List<Programacion> get programacion => _programacion;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchWeekSchedule(DateTime date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Calcular inicio y fin de semana (Lunes a Domingo)
      // DateTime.weekday: 1=Mon, 7=Sun
      final start = date.subtract(Duration(days: date.weekday - 1));
      final end = start.add(const Duration(days: 6));

      _programacion = await _repository.getProgramacion(start, end);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<String?> createProgramacion({
    required DateTime fecha,
    required int empleadoId,
    int? vehiculoId,
    required String labor,
    String? ubicacion,
    bool crearOT = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.createProgramacion({
        'fecha': fecha.toIso8601String().split('T')[0],
        'empleado_id': empleadoId,
        'vehiculo_id': vehiculoId,
        'labor': labor,
        'ubicacion': ubicacion,
        'crear_orden_trabajo': crearOT,
      });

      return null; // Success
    } catch (e) {
      debugPrint('Error creating programacion: $e');
      _isLoading = false;
      notifyListeners();
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map) {
          if (data['errors'] != null) {
            final errors = data['errors'] as Map;
            return errors.values.map((e) => (e as List).join('\n')).join('\n');
          }
          if (data['message'] != null) {
            return data['message'].toString();
          }
        }
        return e.message ?? e.toString();
      }
      return e.toString();
    }
  }

  Future<String?> createProgramacionMultiple({
    required List<DateTime> fechas,
    required int empleadoId,
    int? vehiculoId,
    required String labor,
    String? ubicacion,
    bool crearOT = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Create all tasks in parallel using Future.wait
      await Future.wait(
        fechas.map(
          (fecha) => _repository.createProgramacion({
            'fecha': fecha.toIso8601String().split('T')[0],
            'empleado_id': empleadoId,
            'vehiculo_id': vehiculoId,
            'labor': labor,
            'ubicacion': ubicacion,
            'crear_orden_trabajo': crearOT,
          }),
        ),
      );

      // Refetch schedule for the week of the first date (assuming all are in same week or close)
      if (fechas.isNotEmpty) {
        await fetchWeekSchedule(fechas.first);
      } else {
        _isLoading = false;
        notifyListeners();
      }
      return null; // Success
    } catch (e) {
      debugPrint('Error creating programacion multiple: $e');
      _isLoading = false;
      notifyListeners();
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map) {
          if (data['errors'] != null) {
            final errors = data['errors'] as Map;
            return errors.values.map((v) => (v as List).join('\n')).join('\n');
          }
          if (data['message'] != null) {
            return data['message'].toString();
          }
        }
        return e.message ?? e.toString();
      }
      return e.toString();
    }
  }

  Future<String?> reportarNovedad({
    required DateTime fecha,
    required int empleadoId,
    int? vehiculoId,
    required String descripcion,
    String? prioridad,
    bool? pausarActividad,
    String? localImagePath,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.reportarNovedad({
        'fecha': fecha.toIso8601String().split('T')[0],
        'empleado_id': empleadoId,
        'vehiculo_id': vehiculoId,
        'descripcion': descripcion,
        'prioridad': prioridad,
        'pausar_actividad': (pausarActividad == true) ? 1 : 0,
      }, localImagePath: localImagePath);

      await fetchWeekSchedule(fecha);
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Error reporting novedad: $e');
      _isLoading = false;
      notifyListeners();
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map) {
          if (data['errors'] != null) {
            final errors = data['errors'] as Map;
            return errors.values.map((v) => (v as List).join('\n')).join('\n');
          }
          if (data['message'] != null) {
            return data['message'].toString();
          }
        }
        return e.message ?? e.toString();
      }
      return e.toString();
    }
  }

  Future<String?> deleteProgramacion(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.deleteProgramacion(id);
      // Remove from local list to avoid refetch if possible, or just refetch
      _programacion.removeWhere((p) => p.id == id);
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Error deleting programacion: $e');
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> updateProgramacion({
    required int id,
    required DateTime fecha,
    required int empleadoId,
    int? vehiculoId,
    required String labor,
    String? ubicacion,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.updateProgramacion(id, {
        'fecha': fecha.toIso8601String().split('T')[0],
        'empleado_id': empleadoId,
        'vehiculo_id': vehiculoId,
        'labor': labor,
        'ubicacion': ubicacion,
      });

      // Refetch to ensure sync
      await fetchWeekSchedule(fecha);
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Error updating programacion: $e');
      _isLoading = false;
      notifyListeners();
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map) {
          if (data['errors'] != null) {
            final errors = data['errors'] as Map;
            return errors.values.map((v) => (v as List).join('\n')).join('\n');
          }
          if (data['message'] != null) {
            return data['message'].toString();
          }
        }
        return e.message ?? e.toString();
      }
      return e.toString();
    }
  }
}
