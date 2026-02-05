import 'package:flutter/foundation.dart';
import 'package:frontend/core/network/api_client.dart';
import '../../data/models/session_model.dart';
import 'package:dio/dio.dart';

class SessionProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  SessionTrabajo? _activeSession;
  bool _isLoading = false;
  String? _error;

  SessionProvider(this._apiClient);

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
      } else {
        _activeSession = null;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
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
    } on DioException catch (e) {
      _isLoading = false;
      _error = e.response?.data['message'] ?? e.message;
      notifyListeners();
      return false;
    } catch (e) {
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
    } on DioException catch (e) {
      _isLoading = false;
      _error = e.response?.data['message'] ?? e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
