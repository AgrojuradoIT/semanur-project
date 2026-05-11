import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../network/api_client.dart';

enum SyncStatus { online, offline, syncing }

class SyncProvider extends ChangeNotifier {
  static const int _maxAttempts = 5;
  static const int _baseBackoffSeconds = 30;
  static const int _maxBackoffSeconds = 3600;

  final ApiClient _apiClient;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  SyncStatus _status = SyncStatus.online;
  int _pendingCount = 0;
  int _failedCount = 0;
  bool _isProcessing = false;
  bool _isInitialSyncCompleted = false;
  String? _lastSyncError;

  SyncStatus get status => _status;
  int get pendingCount => _pendingCount;
  int get failedCount => _failedCount;
  bool get isProcessing => _isProcessing;
  bool get isInitialSyncCompleted => _isInitialSyncCompleted;
  String? get lastSyncError => _lastSyncError;

  SyncProvider(this._apiClient) {
    _initConnectivityListener();
    _checkInitialConnectivity();
    _updateSyncCounters();
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (results.every((r) => r == ConnectivityResult.none)) {
      _status = SyncStatus.offline;
      notifyListeners();
    }
  }

  void _initConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.every((r) => r == ConnectivityResult.none)) {
        _status = SyncStatus.offline;
      } else {
        _status = SyncStatus.online;
        if (_pendingCount > 0) {
          syncNow();
        }
      }
      notifyListeners();
    });
  }

  Future<void> _updateSyncCounters() async {
    _pendingCount = await _dbHelper.getPendingSyncCount();
    _failedCount = (await _dbHelper.getDeadLetterQueue()).length;
    notifyListeners();
  }

  Future<void> addToQueue({
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
    String? imagePath,
  }) async {
    await _dbHelper.addToSyncQueue(
      endpoint: endpoint,
      method: method,
      payload: payload,
      imagePath: imagePath,
    );
    await _updateSyncCounters();
  }

  Future<void> retryFailedNow() async {
    await _dbHelper.retryAllDeadLetter();
    await _updateSyncCounters();
    await syncNow();
  }

  Future<void> syncNow() async {
    if (_isProcessing) return;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.every((r) => r == ConnectivityResult.none)) return;

    _isProcessing = true;
    _status = SyncStatus.syncing;
    notifyListeners();

    try {
      final queue = await _dbHelper.getDueSyncQueue();

      for (final item in queue) {
        final result = await _processQueueItem(item);

        if (result.success) {
          await _dbHelper.removeFromSyncQueue(item['id'] as int);
          _lastSyncError = null;
          continue;
        }

        final int currentAttempts = (item['attempts'] as int? ?? 0) + 1;
        final bool shouldMoveToDeadLetter =
            !result.retryable || currentAttempts >= _maxAttempts;

        if (shouldMoveToDeadLetter) {
          await _dbHelper.moveQueueItemToDeadLetter(
            item: {
              ...item,
              'attempts': currentAttempts,
            },
            error: result.errorMessage,
            statusCode: result.statusCode,
          );
          await _dbHelper.removeFromSyncQueue(item['id'] as int);
          _lastSyncError =
              'Registro enviado a cola de fallidos: ${result.errorMessage}';
          continue;
        }

        final Duration delay = _calculateBackoff(currentAttempts);
        final String nextRetryAt =
            DateTime.now().add(delay).toIso8601String();

        await _dbHelper.markSyncAttemptFailed(
          id: item['id'] as int,
          nextRetryAt: nextRetryAt,
          error: result.errorMessage,
        );

        _lastSyncError = result.errorMessage;

        // Error transitorio: detenemos lote y esperamos proximo ciclo para
        // evitar saturar API o red inestable.
        break;
      }
    } finally {
      await _updateSyncCounters();
      _isProcessing = false;
      _status = SyncStatus.online;
      notifyListeners();
    }
  }

  Duration _calculateBackoff(int attempts) {
    final int exponent = attempts <= 0 ? 0 : attempts - 1;
    final int seconds = (_baseBackoffSeconds * math.pow(2, exponent)).toInt();
    return Duration(seconds: seconds.clamp(_baseBackoffSeconds, _maxBackoffSeconds));
  }

  Future<_SyncProcessResult> _processQueueItem(Map<String, dynamic> item) async {
    try {
      final String method = (item['method'] ?? '').toString().toUpperCase();
      String endpoint = (item['endpoint'] ?? '').toString();

      endpoint = endpoint.replaceAll(RegExp(r'^/?api/'), '/');
      if (!endpoint.startsWith('/')) endpoint = '/$endpoint';

      if (endpoint.contains('movimientos-inventario')) {
        endpoint = '/movimientos';
      } else if (endpoint.contains('checklist-preoperacional')) {
        endpoint = '/checklists';
      }

      final dynamic decoded = jsonDecode(item['payload'] as String? ?? '{}');
      final Map<String, dynamic> payload = decoded is Map<String, dynamic>
          ? Map<String, dynamic>.from(decoded)
          : {};

      if (endpoint == '/movimientos') {
        payload.putIfAbsent('transaccion_tipo', () => payload['tipo']);
        payload.putIfAbsent('transaccion_cantidad', () => payload['cantidad']);
        payload.putIfAbsent('transaccion_motivo', () => payload['motivo']);
        payload.putIfAbsent(
          'transaccion_referencia_id',
          () => payload['referencia_id'],
        );
        payload.putIfAbsent(
          'transaccion_referencia_type',
          () => payload['referencia_type'],
        );
        payload.putIfAbsent('transaccion_notas', () => payload['notas']);
      }

      final String? imagePath = item['image_path'] as String?;
      late final Response response;

      if (imagePath != null && imagePath.isNotEmpty) {
        final formData = FormData.fromMap(payload);
        formData.files.add(
          MapEntry('foto_evidencia', await MultipartFile.fromFile(imagePath)),
        );
        response = await _apiClient.dio.post(endpoint, data: formData);
      } else {
        switch (method) {
          case 'POST':
            response = await _apiClient.dio.post(endpoint, data: payload);
            break;
          case 'PATCH':
            response = await _apiClient.dio.patch(endpoint, data: payload);
            break;
          case 'PUT':
            response = await _apiClient.dio.put(endpoint, data: payload);
            break;
          case 'DELETE':
            response = await _apiClient.dio.delete(endpoint, data: payload);
            break;
          default:
            return const _SyncProcessResult(
              success: false,
              retryable: false,
              errorMessage: 'Metodo HTTP no soportado en cola',
            );
        }
      }

      final bool ok = response.statusCode == 200 || response.statusCode == 201;
      if (!ok) {
        return _SyncProcessResult(
          success: false,
          retryable: false,
          errorMessage: 'Respuesta no exitosa: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      return const _SyncProcessResult(success: true, retryable: false);
    } on DioException catch (e) {
      final int? statusCode = e.response?.statusCode;
      final String msg =
          e.response?.data?['message']?.toString() ?? e.message ?? 'Error de conexion';

      return _SyncProcessResult(
        success: false,
        retryable: _isRetryableDioError(e),
        errorMessage: 'Fallo subida: $msg',
        statusCode: statusCode,
      );
    } catch (e) {
      return _SyncProcessResult(
        success: false,
        retryable: false,
        errorMessage: 'Error inesperado: $e',
      );
    }
  }

  bool _isRetryableDioError(DioException e) {
    final int? status = e.response?.statusCode;

    if (status != null) {
      if (status == 408 || status == 429) return true;
      if (status >= 500) return true;
      if (status == 401 || status == 403 || status == 404 || status == 422) {
        return false;
      }
      return false;
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return true;
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
        return false;
    }
  }

  void setInitialSyncStatus(bool completed, {String? error}) {
    _isInitialSyncCompleted = completed;
    _lastSyncError = error;
    notifyListeners();
  }
}

class _SyncProcessResult {
  final bool success;
  final bool retryable;
  final String errorMessage;
  final int? statusCode;

  const _SyncProcessResult({
    required this.success,
    required this.retryable,
    this.errorMessage = '',
    this.statusCode,
  });
}
