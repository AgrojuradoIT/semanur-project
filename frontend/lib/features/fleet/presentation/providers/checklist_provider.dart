import 'package:flutter/foundation.dart';
import 'package:frontend/features/fleet/data/models/checklist_model.dart';
import 'package:frontend/features/fleet/data/repositories/checklist_repository.dart';
import 'package:frontend/core/providers/sync_provider.dart';

class ChecklistProvider extends ChangeNotifier {
  final ChecklistRepository _repository;
  final SyncProvider _syncProvider;

  List<ChecklistPreoperacional> _checklists = [];
  bool _isLoading = false;
  String? _error;

  ChecklistProvider(this._repository, this._syncProvider);

  List<ChecklistPreoperacional> get checklists => _checklists;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchChecklists({int? vehiculoId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _checklists = await _repository.getChecklists(vehiculoId: vehiculoId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> registrarChecklist(
    ChecklistPreoperacional checklist, {
    String? localImagePath,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1) Intentar envío directo
      final success = await _repository.createChecklist(
        checklist,
        localImagePath: localImagePath,
      );
      if (success) {
        await fetchChecklists(vehiculoId: checklist.vehiculoId);
      }
      return success;
    } catch (e) {
      // 2) Si falla, verificar si es offline y encolar
      if (_syncProvider.status == SyncStatus.offline ||
          e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('socket')) {
        await _syncProvider.addToQueue(
          endpoint: '/api/checklist-preoperacional',
          method: 'POST',
          payload: checklist.toJson(),
          imagePath: localImagePath,
        );

        // Retornamos true para que la UI crea que "se guardó" (modo optimista)
        // Opcional: Podríamos retornar false pero manejarlo diferente en UI
        return true;
      }

      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
