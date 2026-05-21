import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:frontend/core/database/database_helper.dart';
import '../models/preoperacional_semana_model.dart';

class PreoperacionalLocalDataSource {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // -- Table creation (call from DatabaseHelper migration) --

  static const String tableCachedResponses = 'preoperacional_cached_responses';
  static const String tableCachedSemanas = 'preoperacional_cached_semanas';

  static String createCachedResponsesTable() {
    return '''
      CREATE TABLE IF NOT EXISTS $tableCachedResponses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        semana_id INTEGER NOT NULL,
        daily_form_id INTEGER,
        item_id INTEGER NOT NULL,
        dia_semana TEXT NOT NULL,
        fecha TEXT NOT NULL,
        estado TEXT NOT NULL,
        observacion TEXT,
        foto_path TEXT,
        synced INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''';
  }

  static String createCachedSemanasTable() {
    return '''
      CREATE TABLE IF NOT EXISTS $tableCachedSemanas (
        semana_id INTEGER PRIMARY KEY,
        vehiculo_id INTEGER NOT NULL,
        template_id INTEGER,
        inspector_id INTEGER,
        semana_inicio TEXT,
        semana_fin TEXT,
        semana_numero INTEGER,
        semana_anio INTEGER,
        vehiculo_placa TEXT,
        full_json TEXT,
        estado TEXT DEFAULT 'pendiente',
        last_updated TEXT NOT NULL
      )
    ''';
  }

  // -- Cached Responses (offline queue) --

  Future<void> cacheDailyResponse({
    required int semanaId,
    required int itemId,
    required String diaSemana,
    required DateTime fecha,
    required String estado,
    String? observacion,
    String? fotoPath,
    int? dailyFormId,
  }) async {
    final db = await _dbHelper.database;
    await db.insert(tableCachedResponses, {
      'semana_id': semanaId,
      'daily_form_id': dailyFormId,
      'item_id': itemId,
      'dia_semana': diaSemana,
      'fecha': fecha.toIso8601String(),
      'estado': estado,
      'observacion': observacion,
      'foto_path': fotoPath,
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getCachedResponsesForDay({
    required int semanaId,
    required String diaSemana,
  }) async {
    final db = await _dbHelper.database;
    return await db.query(
      tableCachedResponses,
      where: 'semana_id = ? AND dia_semana = ?',
      whereArgs: [semanaId, diaSemana],
      orderBy: 'item_id ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedResponses() async {
    final db = await _dbHelper.database;
    return await db.query(
      tableCachedResponses,
      where: 'synced = 0',
      orderBy: 'created_at ASC',
    );
  }

  Future<void> markResponseSynced(int localId) async {
    final db = await _dbHelper.database;
    await db.update(
      tableCachedResponses,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> clearSyncedResponses() async {
    final db = await _dbHelper.database;
    await db.delete(
      tableCachedResponses,
      where: 'synced = 1',
    );
  }

  // -- Cached Semanas (offline instances) --

  Future<void> cacheSemana(PreoperacionalSemana semana) async {
    final db = await _dbHelper.database;
    await db.insert(
      tableCachedSemanas,
      {
        'semana_id': semana.id,
        'vehiculo_id': semana.vehiculoId,
        'template_id': semana.templateId,
        'inspector_id': semana.inspectorId,
        'semana_inicio': semana.semanaInicio.toIso8601String(),
        'semana_fin': semana.semanaFin.toIso8601String(),
        'semana_numero': semana.semanaNumero,
        'semana_anio': semana.semanaAnio,
        'vehiculo_placa': semana.vehiculoPlaca,
        'full_json': jsonEncode(semana.toJson()),
        'estado': semana.estado,
        'last_updated': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<PreoperacionalSemana?> getCachedSemana(int semanaId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      tableCachedSemanas,
      where: 'semana_id = ?',
      whereArgs: [semanaId],
      limit: 1,
    );

    if (results.isEmpty) return null;

    try {
      final String jsonStr = results.first['full_json'] as String;
      return PreoperacionalSemana.fromJson(jsonDecode(jsonStr));
    } catch (e) {
      debugPrint(
        'PreoperacionalLocalDataSource: Error parsing cached semana: $e',
      );
      return null;
    }
  }

  Future<List<PreoperacionalSemana>> getCachedSemanas() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      tableCachedSemanas,
      orderBy: 'last_updated DESC',
    );

    return results
        .map((row) {
          try {
            final String jsonStr = row['full_json'] as String;
            return PreoperacionalSemana.fromJson(jsonDecode(jsonStr));
          } catch (e) {
            debugPrint(
              'PreoperacionalLocalDataSource: Error parsing cached semana: $e',
            );
            return null;
          }
        })
        .whereType<PreoperacionalSemana>()
        .toList();
  }

  Future<void> deleteCachedSemana(int semanaId) async {
    final db = await _dbHelper.database;
    await db.delete(
      tableCachedSemanas,
      where: 'semana_id = ?',
      whereArgs: [semanaId],
    );
  }

  Future<void> clearAllCachedData() async {
    final db = await _dbHelper.database;
    await db.delete(tableCachedResponses);
    await db.delete(tableCachedSemanas);
  }
}
