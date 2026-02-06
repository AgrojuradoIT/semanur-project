import 'package:flutter/foundation.dart';
import 'package:frontend/features/fleet/data/models/checklist_model.dart';
import 'package:frontend/features/fleet/data/repositories/checklist_repository.dart';
import 'package:frontend/core/providers/sync_provider.dart';
import 'package:frontend/core/database/database_helper.dart';

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

      // Cachear localmente
      try {
        final checklistsMap = _checklists.map((c) => c.toJson()).toList();
        await DatabaseHelper().saveChecklists(checklistsMap);
      } catch (cacheError) {
        debugPrint('Error cacheando checklists: $cacheError');
      }
    } catch (e) {
      debugPrint('Error obteniendo checklists: $e. Intentando local...');
      // Fallback local
      try {
        final localData = await DatabaseHelper().getChecklists(
          vehiculoId: vehiculoId,
        );
        if (localData.isNotEmpty) {
          _checklists = localData
              .map((json) {
                try {
                  return ChecklistPreoperacional.fromJson(json);
                } catch (parseError) {
                  debugPrint('Error parseando checklist local: $parseError');
                  return null;
                }
              })
              .whereType<ChecklistPreoperacional>()
              .toList();

          if (_checklists.isNotEmpty) {
            _isLoading = false;
            notifyListeners();
            return;
          }
        }
      } catch (dbError) {
        debugPrint('Error leyendo DB local checklists: $dbError');
      }

      _isLoading = false;
      _error = 'No se pudo conectar y no hay datos locales.';
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
          endpoint: '/checklists', // Corrected from /checklist-preoperacional
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
