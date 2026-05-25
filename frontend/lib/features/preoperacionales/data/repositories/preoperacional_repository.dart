import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/core/database/database_helper.dart';
import 'package:frontend/core/network/api_client.dart';
import '../datasources/preoperacional_remote_data_source.dart';
import '../datasources/preoperacional_local_data_source.dart';
import '../models/preoperacional_template_model.dart';
import '../models/preoperacional_semana_model.dart';

class PreoperacionalRepository {
  final PreoperacionalRemoteDataSource _remote;
  final PreoperacionalLocalDataSource _local;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  PreoperacionalRepository(ApiClient apiClient)
      : _remote = PreoperacionalRemoteDataSource(apiClient),
        _local = PreoperacionalLocalDataSource();

  // -- Templates (remote only, don't change often) --

  Future<List<PreoperacionalTemplate>> getTemplates({
    String? tipoVehiculo,
  }) async {
    return _remote.getTemplates(tipoVehiculo: tipoVehiculo);
  }

  // -- Semanas (remote first, fallback to cache) --

  Future<PreoperacionalSemana> getOrCreateSemana({
    required int vehiculoId,
    required int inspectorId,
    DateTime? semanaInicio,
    int? templateId,
  }) async {
    try {
      // Try remote first
      return await _remote.createSemana(
        vehiculoId: vehiculoId,
        templateId: templateId,
        inspectorId: inspectorId,
        semanaInicio: semanaInicio ?? DateTime.now(),
      );
    } on DioException catch (e) {
      if (_isOfflineError(e)) {
        // Offline: return cached if available
        final cached = await _local.getCachedSemanas();
        final existing = cached.where(
          (s) => s.vehiculoId == vehiculoId && s.inspectorId == inspectorId,
        );
        if (existing.isNotEmpty) {
          return existing.first;
        }
      }
      throw Exception('Error creating/fetching semana: ${e.message}');
    } catch (e) {
      throw Exception('Error creating/fetching semana: $e');
    }
  }

  Future<PreoperacionalSemana> getSemana(int id) async {
    try {
      // Try remote first
      final semana = await _remote.getSemana(id);
      // Cache for offline access
      await _local.cacheSemana(semana);
      return semana;
    } on DioException catch (e) {
      if (_isOfflineError(e)) {
        // Offline: fallback to cache
        final cached = await _local.getCachedSemana(id);
        if (cached != null) return cached;
      }
      throw Exception('Error fetching semana: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching semana: $e');
    }
  }

  // -- Daily Form (offline-first with sync queue) --

  /// Saves daily form responses to local cache for offline support.
  /// Enqueues to the global sync queue for later sync.
  Future<void> submitDailyFormOffline({
    required int semanaId,
    required String diaSemana,
    required List<Map<String, dynamic>> respuestas,
    String? observacionesDia,
  }) async {
    final now = DateTime.now();

    // Cache each response locally
    for (final respuesta in respuestas) {
      await _local.cacheDailyResponse(
        semanaId: semanaId,
        itemId: respuesta['item_id'] as int,
        diaSemana: diaSemana,
        fecha: now,
        estado: respuesta['estado'] as String,
        observacion: respuesta['observacion'] as String?,
        fotoPath: respuesta['foto_path'] as String?,
        dailyFormId: respuesta['daily_form_id'] as int?,
      );
    }

    // Enqueue to global sync queue
    await _dbHelper.addToSyncQueue(
      endpoint: '/v2/preoperacionales/semanas/$semanaId/dias/$diaSemana',
      method: 'POST',
      payload: {
        'respuestas': respuestas,
        'observaciones_dia': observacionesDia,
      },
    );
  }

  /// Submits daily form directly to remote API (online mode).
  Future<PreoperacionalSemana> submitDailyFormOnline({
    required int semanaId,
    required String diaSemana,
    required List<Map<String, dynamic>> respuestas,
    String? observacionesDia,
  }) async {
    final semana = await _remote.submitDailyForm(
      semanaId: semanaId,
      diaSemana: diaSemana,
      respuestas: respuestas,
      observacionesDia: observacionesDia,
    );
    // Cache updated semana
    await _local.cacheSemana(semana);
    return semana;
  }

  // -- Sync (drains local cache to remote API) --

  /// Drains unsynced responses from local cache to remote API.
  /// Called by SyncProvider or manually when connectivity is restored.
  Future<void> syncPendingResponses() async {
    final unsynced = await _local.getUnsyncedResponses();
    if (unsynced.isEmpty) return;

    // Group by semanaId + diaSemana for batch submission
    final Map<String, List<Map<String, dynamic>>> batches = {};
    final Map<String, List<int>> localIdsMap = {};

    for (final response in unsynced) {
      final semanaId = response['semana_id'] as int;
      final diaSemana = response['dia_semana'] as String;
      final key = '$semanaId|$diaSemana';

      batches.putIfAbsent(key, () => []);
      batches[key]!.add({
        'item_id': response['item_id'],
        'estado': response['estado'],
        'observacion': response['observacion'],
        'foto_path': response['foto_path'],
        if (response['daily_form_id'] != null)
          'daily_form_id': response['daily_form_id'],
      });

      localIdsMap.putIfAbsent(key, () => []);
      localIdsMap[key]!.add(response['id'] as int);
    }

    // Submit each batch
    for (final entry in batches.entries) {
      final parts = entry.key.split('|');
      final semanaId = int.parse(parts[0]);
      final diaSemana = parts[1];
      final localIds = localIdsMap[entry.key]!;

      try {
        await _remote.submitDailyForm(
          semanaId: semanaId,
          diaSemana: diaSemana,
          respuestas: entry.value,
        );

        // Mark all responses in this batch as synced
        for (final localId in localIds) {
          await _local.markResponseSynced(localId);
        }
      } on DioException catch (e) {
        debugPrint(
          'PreoperacionalRepository: Sync failed for semana $semanaId/$diaSemana: ${e.message}',
        );
        // Don't mark as synced — will retry on next sync cycle
        rethrow;
      }
    }

    // Clean up synced responses
    await _local.clearSyncedResponses();
  }

  // -- Pendientes Hoy (remote only) --

  Future<List<Map<String, dynamic>>> getPendientesHoy({
    DateTime? fecha,
  }) async {
    return _remote.getPendientesHoy(fecha: fecha);
  }

  // -- Fuera de Servicio (remote only) --

  Future<void> markFueraServicio({
    required int semanaId,
    required String motivo,
  }) async {
    try {
      final semana = await _remote.markFueraServicio(
        semanaId: semanaId,
        motivo: motivo,
      );
      // Update cached semana
      await _local.cacheSemana(semana);
    } catch (e) {
      throw Exception('Error marking fuera de servicio: $e');
    }
  }

  // -- Cached queries (for offline UI) --

  Future<List<PreoperacionalSemana>> getCachedSemanas() async {
    return _local.getCachedSemanas();
  }

  Future<List<Map<String, dynamic>>> getCachedResponsesForDay({
    required int semanaId,
    required String diaSemana,
  }) async {
    return _local.getCachedResponsesForDay(
      semanaId: semanaId,
      diaSemana: diaSemana,
    );
  }

  // -- Helpers --

  bool _isOfflineError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.error.toString().contains('SocketException');
  }
}
