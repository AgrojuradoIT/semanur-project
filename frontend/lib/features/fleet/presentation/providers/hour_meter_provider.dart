import 'package:flutter/foundation.dart';
import '../../data/models/hour_meter_record_model.dart';
import '../../data/repositories/hour_meter_repository.dart';

class HorometroProvider extends ChangeNotifier {
  final HorometroRepository _repository;
  List<RegistroHorometro> _registros = [];
  bool _isLoading = false;
  String? _error;

  HorometroProvider(this._repository);

  List<RegistroHorometro> get registros => _registros;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRegistros(int vehiculoId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _registros = await _repository.getRegistros(vehiculoId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> registrarHorometro({
    required int vehiculoId,
    required double valorNuevo,
    String? notas,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.registrarHorometro(
        vehiculoId: vehiculoId,
        valorNuevo: valorNuevo,
        notas: notas,
      );
      if (success) {
        await fetchRegistros(vehiculoId);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
