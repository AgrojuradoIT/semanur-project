import 'package:flutter/foundation.dart';
import '../../data/models/checklist_model.dart';
import '../../data/repositories/checklist_repository.dart';

import 'package:frontend/core/providers/sync_provider.dart';

class ChecklistProvider extends ChangeNotifier {
  final ChecklistRepository _repository;
  // final SyncProvider? _syncProvider; // Unused for now

  List<Checklist> _checklists = [];
  List<ChecklistResponse> _history = [];
  bool _isLoading = false;
  String? _error;

  ChecklistProvider(this._repository, [SyncProvider? syncProvider]);

  List<Checklist> get checklists => _checklists;
  List<ChecklistResponse> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchChecklists({String? tipoVehiculo}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _checklists = await _repository.getChecklists(tipoVehiculo: tipoVehiculo);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> submitChecklist(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.submitResponse(data);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchHistory({int? vehiculoId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _history = await _repository.getHistory(vehiculoId: vehiculoId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
}
