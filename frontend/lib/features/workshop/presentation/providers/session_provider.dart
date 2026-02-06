import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:frontend/core/network/api_client.dart';
import '../../data/models/session_model.dart';
import 'package:frontend/core/providers/sync_provider.dart';
import 'package:frontend/core/database/database_helper.dart';

class SessionProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final SyncProvider _syncProvider;

  SessionTrabajo? _activeSession;
  bool _isLoading = false;
  String? _error;

  SessionProvider(this._apiClient, {SyncProvider? syncProvider})
    : _syncProvider =
          syncProvider ?? SyncProvider(ApiClient()); // Fallback or required?
  // Actually main.dart will provide it. Let's make it required to avoid issues.

  SessionTrabajo? get activeSession => _activeSession;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchActiveSession() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/sesiones-trabajo/active');
      if (response.data != null) {
        _activeSession = SessionTrabajo.fromJson(response.data);
        // Cachear localmente para consistencia (opcional, pero útil)
        await DatabaseHelper().saveActiveSessionLocal(
          response.data,
          isSynced: true,
        );
      } else {
        _activeSession = null;
        // Si servidor dice null, limpiar local también
        await DatabaseHelper().closeActiveSessionLocal(
          DateTime.now().toIso8601String(),
        );
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Offline implementation
      if (_syncProvider.status == SyncStatus.offline ||
          e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('socket')) {
        try {
          final localData = await DatabaseHelper().getActiveSessionLocal();
          if (localData != null) {
            try {
              _activeSession = SessionTrabajo(
                id:
                    localData['server_id'] ??
                    localData['local_id'], // fallback ID
                userId: localData['user_id'] ?? 0,
                ordenTrabajoId: localData['orden_trabajo_id'],
                fechaInicio: DateTime.parse(localData['fecha_inicio']),
                fechaFin: null,
                notas: null,
              );
            } catch (parseError) {
              debugPrint('Error parseando sesión local: $parseError');
              _activeSession = null;
            }
          } else {
            _activeSession = null;
          }
          _isLoading = false;
          notifyListeners();
          return;
        } catch (dbError) {
          debugPrint('Error leyendo sesion local: $dbError');
        }
      }

      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> startSession(int ordenTrabajoId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        '/sesiones-trabajo/start',
        data: {'orden_trabajo_id': ordenTrabajoId},
      );

      _activeSession = SessionTrabajo.fromJson(response.data['session']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Offline implementation
      if (_syncProvider.status == SyncStatus.offline ||
          e is DioException &&
              (e.type == DioExceptionType.connectionTimeout ||
                  e.type == DioExceptionType.connectionError ||
                  e.error.toString().contains('SocketException'))) {
        final now = DateTime.now();
        // 1. Guardar en DB local (Optimistic UI)
        final tempSession = {
          'sesion_id': null, // No tenemos ID del server aún
          'user_id': 0, // Placeholder
          'orden_trabajo_id': ordenTrabajoId,
          'fecha_inicio': now.toIso8601String(),
        };
        await DatabaseHelper().saveActiveSessionLocal(
          tempSession,
          isSynced: false,
        );

        // 2. Establecer activeSession en memoria
        _activeSession = SessionTrabajo(
          id: 0, // ID Temporal
          userId: 0,
          ordenTrabajoId: ordenTrabajoId,
          fechaInicio: now,
        );

        // 3. Agregar a Cola de Sincronización
        // IMPORTANTE: Endpoint sin prefijo /api duplicado
        await _syncProvider.addToQueue(
          endpoint: '/sesiones-trabajo/start',
          method: 'POST',
          payload: {'orden_trabajo_id': ordenTrabajoId},
        );

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> stopSession(int sessionId, {String? notas}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiClient.dio.post(
        '/sesiones-trabajo/$sessionId/stop',
        data: {'notas': notas},
      );

      _activeSession = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Offline implementation
      if (_syncProvider.status == SyncStatus.offline ||
          e is DioException &&
              (e.type == DioExceptionType.connectionTimeout ||
                  e.type == DioExceptionType.connectionError ||
                  e.error.toString().contains('SocketException'))) {
        final now = DateTime.now();
        await DatabaseHelper().closeActiveSessionLocal(
          now.toIso8601String(),
          notas: notas,
        );

        _activeSession = null;

        // IMPORTANTE: Endpoint sin prefijo /api duplicado
        // Usar sessionId 0 si es offline puro puede fallar en backend si no se maneja
        // pero la cola de sync lo intentará.
        await _syncProvider.addToQueue(
          endpoint: '/sesiones-trabajo/$sessionId/stop',
          method: 'POST',
          payload: {'notas': notas},
        );

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
