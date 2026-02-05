import 'package:flutter/foundation.dart';
import '../../data/models/fuel_record_model.dart';
import '../../data/repositories/fuel_repository.dart';

class FuelProvider extends ChangeNotifier {
  final FuelRepository _repository;
  List<RegistroCombustible> _registros = [];
  bool _isLoading = false;
  String? _error;

  FuelProvider(this._repository);

  List<RegistroCombustible> get registros => _registros;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRegistros({int? vehiculoId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _registros = await _repository.getRegistros(vehiculoId: vehiculoId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> registrarTanqueo({
    required int vehiculoId,
    required double cantidad,
    required double valor,
    double? horometro,
    double? kilometraje,
    String? estacion,
    String? notas,
    int? productoId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.crearRegistro(
        vehiculoId: vehiculoId,
        cantidadGalones: cantidad,
        valorTotal: valor,
        horometro: horometro,
        kilometraje: kilometraje,
        estacion: estacion,
        notas: notas,
        productoId: productoId,
      );
      if (success) {
        await fetchRegistros(vehiculoId: vehiculoId);
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
