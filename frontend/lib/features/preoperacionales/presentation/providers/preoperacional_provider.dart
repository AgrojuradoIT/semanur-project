import 'package:flutter/foundation.dart';
import 'package:frontend/features/preoperacionales/data/models/preoperacional_template_model.dart';
import 'package:frontend/features/preoperacionales/data/models/preoperacional_semana_model.dart';
import 'package:frontend/features/preoperacionales/data/repositories/preoperacional_repository.dart';

class PreoperacionalProvider extends ChangeNotifier {
  final PreoperacionalRepository _repository;

  // State
  List<PreoperacionalTemplate> _templates = [];
  PreoperacionalSemana? _currentSemana;
  List<PreoperacionalSemana> _semanas = [];
  List<Map<String, dynamic>> _pendientesHoy = [];
  bool _isLoading = false;
  String? _error;

  PreoperacionalProvider(this._repository);

  // Getters
  List<PreoperacionalTemplate> get templates => _templates;
  PreoperacionalSemana? get currentSemana => _currentSemana;
  List<PreoperacionalSemana> get semanas => _semanas;
  List<Map<String, dynamic>> get pendientesHoy => _pendientesHoy;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Loads templates, optionally filtered by vehicle type.
  Future<void> loadTemplates({String? tipoVehiculo}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _templates = await _repository.getTemplates(tipoVehiculo: tipoVehiculo);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error cargando plantillas: $e';
      notifyListeners();
    }
  }

  /// Loads or creates the current week for a vehicle/inspector pair.
  Future<void> loadOrCreateSemana({
    required int vehiculoId,
    required int inspectorId,
    int? templateId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentSemana = await _repository.getOrCreateSemana(
        vehiculoId: vehiculoId,
        inspectorId: inspectorId,
        templateId: templateId,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error cargando semana: $e';
      notifyListeners();
    }
  }

  /// Loads a specific semana by ID.
  Future<void> loadSemana(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentSemana = await _repository.getSemana(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error cargando semana: $e';
      notifyListeners();
    }
  }

  /// Submits the daily form online.
  Future<void> submitDailyForm({
    required int semanaId,
    required String diaSemana,
    required List<Map<String, dynamic>> respuestas,
    String? observacionesDia,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentSemana = await _repository.submitDailyFormOnline(
        semanaId: semanaId,
        diaSemana: diaSemana,
        respuestas: respuestas,
        observacionesDia: observacionesDia,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error guardando formulario: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Submits the daily form offline (saved locally for later sync).
  Future<void> submitDailyFormOffline({
    required int semanaId,
    required String diaSemana,
    required List<Map<String, dynamic>> respuestas,
    String? observacionesDia,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.submitDailyFormOffline(
        semanaId: semanaId,
        diaSemana: diaSemana,
        respuestas: respuestas,
        observacionesDia: observacionesDia,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error guardando offline: $e';
      notifyListeners();
    }
  }

  /// Syncs all pending offline responses to the remote API.
  Future<void> syncPending() async {
    try {
      await _repository.syncPendingResponses();
      notifyListeners();
    } catch (e) {
      debugPrint('PreoperacionalProvider: Sync failed: $e');
      _error = 'Error sincronizando: $e';
      notifyListeners();
    }
  }

  /// Loads pending items for today.
  Future<void> loadPendientesHoy({DateTime? fecha}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pendientesHoy = await _repository.getPendientesHoy(fecha: fecha);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error cargando pendientes: $e';
      notifyListeners();
    }
  }

  /// Loads weeks, optionally filtered by year/number.
  Future<void> loadSemanas({int? semanaAnio, int? semanaNumero}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use cached semanas as primary source (loaded from repo operations)
      _semanas = await _repository.getCachedSemanas();
      if (semanaAnio != null) {
        _semanas = _semanas.where((s) => s.semanaAnio == semanaAnio).toList();
      }
      if (semanaNumero != null) {
        _semanas = _semanas.where((s) => s.semanaNumero == semanaNumero).toList();
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error cargando semanas: $e';
      notifyListeners();
    }
  }

  /// Marks the current week as out of service.
  Future<void> markFueraServicio({
    required int semanaId,
    required String motivo,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.markFueraServicio(semanaId: semanaId, motivo: motivo);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error marcando fuera de servicio: $e';
      notifyListeners();
    }
  }

  /// Clears current state (e.g., when switching vehicles).
  void reset() {
    _currentSemana = null;
    _templates = [];
    _error = null;
    notifyListeners();
  }
}
