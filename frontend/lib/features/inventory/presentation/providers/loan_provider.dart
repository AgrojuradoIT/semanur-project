import 'package:flutter/foundation.dart';
import '../../data/models/loan_model.dart';
import '../../data/repositories/loan_repository.dart';

class LoanProvider extends ChangeNotifier {
  final LoanRepository _repository;
  List<PrestamoHerramienta> _prestamos = [];
  bool _isLoading = false;
  String? _error;

  LoanProvider(this._repository);

  List<PrestamoHerramienta> get prestamos => _prestamos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPrestamos({String? estado}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _prestamos = await _repository.getPrestamos(estado: estado);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> registrarPrestamo({
    required int productoId,
    required int mecanicoId,
    required double cantidad,
    String? notas,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.crearPrestamo(
        productoId: productoId,
        mecanicoId: mecanicoId,
        cantidad: cantidad,
        notas: notas,
      );
      if (success) {
        await fetchPrestamos();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> devolverHerramienta(
    int id,
    String estado, {
    String? notas,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.devolverPrestamo(
        id,
        estado,
        notas: notas,
      );
      if (success) {
        await fetchPrestamos();
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
