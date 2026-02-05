import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';
import '../network/api_client.dart';
import 'package:dio/dio.dart';

enum SyncStatus { online, offline, syncing }

class SyncProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  SyncStatus _status = SyncStatus.online;
  int _pendingCount = 0;
  bool _isProcessing = false;
  bool _isInitialSyncCompleted = false;
  String? _lastSyncError;

  SyncStatus get status => _status;
  int get pendingCount => _pendingCount;
  bool get isProcessing => _isProcessing;
  bool get isInitialSyncCompleted => _isInitialSyncCompleted;
  String? get lastSyncError => _lastSyncError;

  SyncProvider(this._apiClient) {
    _initConnectivityListener();
    _updatePendingCount();
  }

  void _initConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        _status = SyncStatus.offline;
      } else {
        _status = SyncStatus.online;
        // Si hay red y tenemos pendientes, intentamos sincronizar
        if (_pendingCount > 0) {
          syncNow();
        }
      }
      notifyListeners();
    });
  }

  Future<void> _updatePendingCount() async {
    final queue = await _dbHelper.getSyncQueue();
    _pendingCount = queue.length;
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
    await _updatePendingCount();
  }

  Future<void> syncNow() async {
    if (_isProcessing) return;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return;

    _isProcessing = true;
    _status = SyncStatus.syncing;
    notifyListeners();

    try {
      final queue = await _dbHelper.getSyncQueue();

      for (var item in queue) {
        final success = await _processQueueItem(item);
        if (success) {
          await _dbHelper.removeFromSyncQueue(item['id']);
          await _updatePendingCount();
        } else {
          await _dbHelper.incrementSyncAttempts(item['id']);
          // Si falla uno, detenemos el proceso para no saturar
          break;
        }
      }
    } finally {
      _isProcessing = false;
      _status = SyncStatus.online;
      notifyListeners();
    }
  }

  Future<bool> _processQueueItem(Map<String, dynamic> item) async {
    try {
      final String method = item['method'];
      final String endpoint = item['endpoint'];
      final dynamic payload = jsonDecode(item['payload']);
      final String? imagePath = item['image_path'];

      Response response;

      if (imagePath != null && imagePath.isNotEmpty) {
        // Manejar subida de archivos
        final formData = FormData.fromMap(payload);
        formData.files.add(
          MapEntry('foto_evidencia', await MultipartFile.fromFile(imagePath)),
        );
        response = await _apiClient.dio.post(endpoint, data: formData);
      } else {
        if (method == 'POST') {
          response = await _apiClient.dio.post(endpoint, data: payload);
        } else if (method == 'PATCH') {
          response = await _apiClient.dio.patch(endpoint, data: payload);
        } else if (method == 'PUT') {
          response = await _apiClient.dio.put(endpoint, data: payload);
        } else {
          return false;
        }
      }

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Sync Error: $e');
      return false;
    }
  }

  void setInitialSyncStatus(bool completed, {String? error}) {
    _isInitialSyncCompleted = completed;
    _lastSyncError = error;
    notifyListeners();
  }
}
