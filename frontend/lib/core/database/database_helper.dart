import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, "semanur_offline.db");

    return await openDatabase(
      path,
      version: 19,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE vehiculos ADD COLUMN horometro_actual REAL',
      );
      await db.execute(
        'ALTER TABLE vehiculos ADD COLUMN kilometraje_actual REAL',
      );
      await db.execute(
        'ALTER TABLE vehiculos ADD COLUMN horometro_proximo_mantenimiento REAL',
      );
      await db.execute(
        'ALTER TABLE vehiculos ADD COLUMN kilometraje_proximo_mantenimiento REAL',
      );
    }
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS vehiculos');
      await _createVehiculosTable(db);
    }
    if (oldVersion < 4) {
      // Recrear tabla productos para incluir campos faltantes y soportar JSON
      await db.execute('DROP TABLE IF EXISTS productos');
      await _createProductosTable(db);
    }
    if (oldVersion < 5) {
      await _createOrdenesTrabajoTable(db);
    }
    if (oldVersion < 6) {
      await _createChecklistsTable(db);
      await _createCombustibleTable(db);
    }
    if (oldVersion < 7) {
      await _createSesionTrabajoLocalTable(db);
    }
    if (oldVersion < 9) {
      await _createBodegasTable(db);
      await _createBodegaProductoTable(db);
      // Agregar columna operador_asignado_id a vehiculos si existe la tabla
      try {
        await db.execute(
          'ALTER TABLE vehiculos ADD COLUMN operador_asignado_id INTEGER',
        );
      } catch (e) {
        debugPrint(
          'Error adding column operador_asignado_id (might already exist or table missing): $e',
        );
      }
    }
    if (oldVersion < 10) {
      try {
        await db.execute(
          'ALTER TABLE vehiculos ADD COLUMN mecanico_asignado_id INTEGER',
        );
      } catch (e) {
        debugPrint('Error adding column mecanico_asignado_id: $e');
      }
    }
    if (oldVersion < 11) {
      await _createUsersTable(db);
    }
    if (oldVersion < 12) {
      await _createEmpleadosTable(db);
    }
    if (oldVersion < 13) {
      try {
        await db.execute(
          "ALTER TABLE sync_queue ADD COLUMN status TEXT DEFAULT 'queued'",
        );
      } catch (e) {
        debugPrint('Error adding sync_queue.status: $e');
      }
      try {
        await db.execute('ALTER TABLE sync_queue ADD COLUMN last_attempt_at TEXT');
      } catch (e) {
        debugPrint('Error adding sync_queue.last_attempt_at: $e');
      }
      try {
        await db.execute('ALTER TABLE sync_queue ADD COLUMN next_retry_at TEXT');
      } catch (e) {
        debugPrint('Error adding sync_queue.next_retry_at: $e');
      }
      try {
        await db.execute('ALTER TABLE sync_queue ADD COLUMN last_error TEXT');
      } catch (e) {
        debugPrint('Error adding sync_queue.last_error: $e');
      }
      try {
        await db.execute(
          "UPDATE sync_queue SET status = 'queued' WHERE status IS NULL OR status = ''",
        );
        await db.execute(
          'UPDATE sync_queue SET next_retry_at = created_at WHERE next_retry_at IS NULL',
        );
      } catch (e) {
        debugPrint('Error backfilling sync_queue retry fields: $e');
      }
      await _createSyncDeadLetterTable(db);
    }
    if (oldVersion < 14) {
      try {
        await db.execute(
          'ALTER TABLE sesion_trabajo_local ADD COLUMN empleado_id INTEGER',
        );
        // Migración simple: si tenemos un user_id local, intentamos mantenerlo o marcar para actualización
        await db.execute(
          'UPDATE sesion_trabajo_local SET empleado_id = user_id WHERE empleado_id IS NULL',
        );
      } catch (e) {
        debugPrint('Error upgrading to v14 (empleado_id in sessions): $e');
      }
    }
    if (oldVersion < 15) {
      await _createNotificationsTable(db);
    }
    if (oldVersion < 16) {
      try {
        await db.execute('ALTER TABLE productos ADD COLUMN capacidad_maxima REAL');
      } catch (e) {
        debugPrint('Error adding column capacidad_maxima to productos: $e');
      }
    }
    if (oldVersion < 17) {
      // Forzar que capacidad_maxima exista (fix para BD corruptas)
      try {
        final cols = await db.rawQuery("PRAGMA table_info(productos)");
        final hasCol = cols.any((c) => c['name'] == 'capacidad_maxima');
        if (!hasCol) {
          await db.execute('ALTER TABLE productos ADD COLUMN capacidad_maxima REAL');
        }
      } catch (e) {
        debugPrint('v17 migration: recreating productos table: $e');
        await db.execute('DROP TABLE IF EXISTS productos');
        await _createProductosTable(db);
      }
    }
    if (oldVersion < 18) {
      // Versión 18: Tabla productos con capacidad_maxima explícita
      // Recrear tabla para asegurar schema correcto
      debugPrint('v18 migration: recreating productos table with explicit capacidad_maxima');
      await db.execute('DROP TABLE IF EXISTS productos');
      await _createProductosTable(db);
    }
    if (oldVersion < 19) {
      // Versión 19: agregar server_id a notificaciones para sync bidireccional
      try {
        await db.execute(
          'ALTER TABLE notificaciones ADD COLUMN server_id INTEGER',
        );
        debugPrint('v19 migration: server_id added to notificaciones');
      } catch (e) {
        debugPrint('v19 migration error (server_id): $e');
      }
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createVehiculosTable(db);
    await _createProductosTable(db);
    await _createSyncQueueTable(db);
    await _createSyncDeadLetterTable(db);
    await _createOrdenesTrabajoTable(db);
    await _createChecklistsTable(db);
    await _createCombustibleTable(db);
    await _createSesionTrabajoLocalTable(db);
    await _createBodegasTable(db);
    await _createBodegaProductoTable(db);
    await _createUsersTable(db);
    await _createEmpleadosTable(db);
    await _createNotificationsTable(db);
  }

  Future<void> _createNotificationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notificaciones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        tipo TEXT,
        titulo TEXT,
        mensaje TEXT,
        relacionado_id TEXT,
        fecha_creacion TEXT,
        fecha_leido TEXT,
        fecha_proximo_recordatorio TEXT,
        estado TEXT DEFAULT 'pendiente'
      )
    ''');
  }

  // Métodos de utilidad: Notificaciones
  Future<int> saveNotification({
    required String tipo,
    required String titulo,
    required String mensaje,
    String? relacionadoId,
    String? fechaProximoRecordatorio,
    int? serverId,
  }) async {
    final db = await database;
    return await db.insert('notificaciones', {
      'server_id': serverId,
      'tipo': tipo,
      'titulo': titulo,
      'mensaje': mensaje,
      'relacionado_id': relacionadoId,
      'fecha_creacion': DateTime.now().toIso8601String(),
      'fecha_proximo_recordatorio': fechaProximoRecordatorio,
      'estado': 'pendiente',
    });
  }

  Future<void> deleteNotification(int localId) async {
    final db = await database;
    await db.delete('notificaciones', where: 'id = ?', whereArgs: [localId]);
  }

  Future<void> deleteAllNotifications() async {
    final db = await database;
    await db.delete('notificaciones');
  }

  Future<int?> getServerIdForLocalNotification(int localId) async {
    final db = await database;
    final results = await db.query(
      'notificaciones',
      columns: ['server_id'],
      where: 'id = ?',
      whereArgs: [localId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first['server_id'] as int?;
  }

  Future<List<Map<String, dynamic>>> getUnreadNotifications() async {
    final db = await database;
    return await db.query(
      'notificaciones',
      where: "estado = 'pendiente'",
      orderBy: 'fecha_creacion DESC',
    );
  }

  Future<Map<String, dynamic>?> getNotificationById(int id) async {
    final db = await database;
    final results = await db.query(
      'notificaciones',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<void> markNotificationAsRead(int id) async {
    final db = await database;
    await db.update(
      'notificaciones',
      {
        'estado': 'leido',
        'fecha_leido': DateTime.now().toIso8601String(),
        'fecha_proximo_recordatorio': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getDueNotifications() async {
    final db = await database;
    final String now = DateTime.now().toIso8601String();
    return await db.query(
      'notificaciones',
      where: "estado = 'pendiente' AND fecha_proximo_recordatorio <= ?",
      whereArgs: [now],
    );
  }

  /// Verifica si ya existe una notificación del mismo tipo y recurso creada hoy.
  /// Evita emitir push duplicadas del SO.
  Future<bool> hasNotificationToday({
    required String tipo,
    String? relacionadoId,
  }) async {
    final db = await database;
    final hoy = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    
    String where;
    List<dynamic> whereArgs;
    
    if (relacionadoId != null) {
      where = "tipo = ? AND relacionado_id = ? AND fecha_creacion LIKE ?";
      whereArgs = [tipo, relacionadoId, '$hoy%'];
    } else {
      where = "tipo = ? AND relacionado_id IS NULL AND fecha_creacion LIKE ?";
      whereArgs = [tipo, '$hoy%'];
    }
    
    final results = await db.query(
      'notificaciones',
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );
    return results.isNotEmpty;
  }

  Future<void> updateNotificationReminder(int id, String nextDate) async {
    final db = await database;
    await db.update(
      'notificaciones',
      {'fecha_proximo_recordatorio': nextDate},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> _createVehiculosTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vehiculos (
        vehiculo_id INTEGER PRIMARY KEY,
        placa TEXT,
        marca TEXT,
        modelo TEXT,
        tipo TEXT,
        foto_url TEXT,
        horometro_actual REAL,
        horometro_proximo_mantenimiento REAL,
        kilometraje_actual REAL,
        kilometraje_proximo_mantenimiento REAL,
        fecha_vencimiento_soat TEXT,
        fecha_vencimiento_tecnomecanica TEXT,
        operador_asignado_id INTEGER,
        mecanico_asignado_id INTEGER,
        last_updated TEXT
      )
    ''');
  }

  Future<void> _createProductosTable(Database db) async {
    // Schema alineado con product_model.dart
    await db.execute('''
      CREATE TABLE IF NOT EXISTS productos (
        producto_id INTEGER PRIMARY KEY,
        categoria_id INTEGER,
        producto_sku TEXT,
        producto_nombre TEXT,
        producto_unidad_medida TEXT,
        producto_stock_actual REAL,
        producto_alerta_stock_minimo REAL,
        capacidad_maxima REAL,
        producto_precio_costo REAL,
        producto_ubicacion TEXT,
        categoria TEXT,
        last_updated TEXT
      )
    ''');
  }

  Future<void> _createSyncQueueTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        endpoint TEXT,
        method TEXT,
        payload TEXT,
        image_path TEXT,
        created_at TEXT,
        attempts INTEGER DEFAULT 0,
        status TEXT DEFAULT 'queued',
        last_attempt_at TEXT,
        next_retry_at TEXT,
        last_error TEXT
      )
    ''');
  }

  Future<void> _createSyncDeadLetterTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_dead_letter (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        original_queue_id INTEGER,
        endpoint TEXT,
        method TEXT,
        payload TEXT,
        image_path TEXT,
        attempts INTEGER,
        last_error TEXT,
        status_code INTEGER,
        failed_at TEXT,
        created_at TEXT
      )
    ''');
  }

  // Métodos de utilidad: Vehículos
  Future<void> saveVehiculos(List<Map<String, dynamic>> vehiculos) async {
    final db = await database;
    final batch = db.batch();
    for (var v in vehiculos) {
      batch.insert(
        'vehiculos',
        v,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getVehiculos() async {
    final db = await database;
    return await db.query('vehiculos');
  }

  // Métodos de utilidad: Productos
  Future<void> saveProductos(List<Map<String, dynamic>> productos) async {
    final db = await database;
    final batch = db.batch();
    for (var p in productos) {
      // Clonar mapa para no modificar el original de la app
      final Map<String, dynamic> row = Map<String, dynamic>.from(p);

      // Convertir objeto categoria a JSON String si existe
      if (row['categoria'] != null && row['categoria'] is! String) {
        row['categoria'] = jsonEncode(row['categoria']);
      }

      batch.insert(
        'productos',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteProductos() async {
    final db = await database;
    await db.delete('productos');
    debugPrint('DatabaseHelper: Productos eliminados de la caché');
  }

  Future<List<Map<String, dynamic>>> getProductos() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query('productos');

    // Decodificar categoria JSON string a Map
    return result.map((row) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(row);
      if (map['categoria'] != null && map['categoria'] is String) {
        try {
          map['categoria'] = jsonDecode(map['categoria']);
        } catch (e) {
          // Si falla, dejamos como null o string
          debugPrint('Error decoding category json: $e');
        }
      }
      return map;
    }).toList();
  }

  // Métodos de utilidad: Sync Queue
  Future<int> addToSyncQueue({
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
    String? imagePath,
  }) async {
    final db = await database;
    final String payloadStr = jsonEncode(payload);
    final String now = DateTime.now().toIso8601String();

    return await db.insert('sync_queue', {
      'endpoint': endpoint,
      'method': method,
      'payload': payloadStr,
      'image_path': imagePath,
      'created_at': now,
      'status': 'queued',
      'attempts': 0,
      'next_retry_at': now,
    });
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await database;
    return await db.query(
      'sync_queue',
      where: "COALESCE(status, 'queued') IN ('queued','retrying')",
      orderBy: 'created_at ASC',
    );
  }

  Future<int> getPendingSyncCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as total FROM sync_queue WHERE COALESCE(status, 'queued') IN ('queued','retrying')",
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getDueSyncQueue() async {
    final db = await database;
    final String now = DateTime.now().toIso8601String();
    return await db.query(
      'sync_queue',
      where:
          "COALESCE(status, 'queued') IN ('queued','retrying') AND (next_retry_at IS NULL OR next_retry_at <= ?)",
      whereArgs: [now],
      orderBy: 'created_at ASC',
    );
  }

  Future<void> removeFromSyncQueue(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementSyncAttempts(int id) async {
    final db = await database;
    await db.execute(
      'UPDATE sync_queue SET attempts = attempts + 1 WHERE id = ?',
      [id],
    );
  }

  Future<void> markSyncAttemptFailed({
    required int id,
    required String nextRetryAt,
    required String error,
  }) async {
    final db = await database;
    await db.execute(
      '''
      UPDATE sync_queue
      SET
        attempts = attempts + 1,
        status = 'retrying',
        last_attempt_at = ?,
        next_retry_at = ?,
        last_error = ?
      WHERE id = ?
      ''',
      [
        DateTime.now().toIso8601String(),
        nextRetryAt,
        error,
        id,
      ],
    );
  }

  Future<void> moveQueueItemToDeadLetter({
    required Map<String, dynamic> item,
    required String error,
    int? statusCode,
  }) async {
    final db = await database;

    await db.insert('sync_dead_letter', {
      'original_queue_id': item['id'],
      'endpoint': item['endpoint'],
      'method': item['method'],
      'payload': item['payload'],
      'image_path': item['image_path'],
      'attempts': item['attempts'] ?? 0,
      'last_error': error,
      'status_code': statusCode,
      'failed_at': DateTime.now().toIso8601String(),
      'created_at': item['created_at'],
    });
  }

  Future<List<Map<String, dynamic>>> getDeadLetterQueue() async {
    final db = await database;
    return await db.query('sync_dead_letter', orderBy: 'failed_at DESC');
  }

  Future<void> retryAllDeadLetter() async {
    final db = await database;
    final dead = await db.query('sync_dead_letter', orderBy: 'id ASC');
    if (dead.isEmpty) return;

    final batch = db.batch();
    final String now = DateTime.now().toIso8601String();
    for (final item in dead) {
      batch.insert('sync_queue', {
        'endpoint': item['endpoint'],
        'method': item['method'],
        'payload': item['payload'],
        'image_path': item['image_path'],
        'created_at': item['created_at'] ?? now,
        'attempts': 0,
        'status': 'queued',
        'last_attempt_at': null,
        'next_retry_at': now,
        'last_error': null,
      });
    }
    batch.delete('sync_dead_letter');
    await batch.commit(noResult: true);
  }

  // Métodos de utilidad: Órdenes de Trabajo (Cache Offline)
  Future<void> _createOrdenesTrabajoTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ordenes_trabajo (
        id INTEGER PRIMARY KEY,
        vehiculo_id INTEGER,
        prioridad TEXT,
        estado TEXT,
        descripcion TEXT,
        full_json TEXT, -- Almacenamos todo el objeto para reconstrucción fácil
        last_updated TEXT
      )
    ''');
  }

  Future<void> saveOrdenesTrabajo(List<dynamic> ordenesJson) async {
    final db = await database;
    final batch = db.batch();

    // Opcional: Limpiar tabla para no dejar basura vieja, o usar replace.
    // Usaremos replace.

    for (var o in ordenesJson) {
      final map = Map<String, dynamic>.from(o as Map);
      final orderId = map['orden_trabajo_id'] ?? map['id'];
      if (orderId == null) {
        continue;
      }

      batch.insert('ordenes_trabajo', {
        'id': orderId,
        'vehiculo_id': map['vehiculo_id'],
        'prioridad': map['prioridad'],
        'estado': map['estado'],
        'descripcion': map['descripcion'],
        'full_json': jsonEncode(map),
        'last_updated': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Guarda una orden de trabajo individual en caché (para detalle)
  Future<void> saveOrdenTrabajoLocal(Map<String, dynamic> ordenJson) async {
    final db = await database;
    final map = Map<String, dynamic>.from(ordenJson);
    final orderId = map['orden_trabajo_id'] ?? map['id'];
    
    if (orderId == null) return;

    await db.insert(
      'ordenes_trabajo',
      {
        'id': orderId,
        'vehiculo_id': map['vehiculo_id'],
        'prioridad': map['prioridad'],
        'estado': map['estado'],
        'descripcion': map['descripcion'],
        'full_json': jsonEncode(map),
        'last_updated': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getOrdenesTrabajo({int? id}) async {
    final db = await database;

    String? where;
    List<dynamic>? whereArgs;

    if (id != null) {
      where = 'id = ?';
      whereArgs = [id];
    }

    final results = await db.query(
      'ordenes_trabajo',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'id DESC',
    );

    return results.map((row) {
      // Reconstruir desde el JSON completo
      final String jsonStr = row['full_json'] as String;
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    }).toList();
  }

  // Métodos de utilidad: Checklists
  Future<void> _createChecklistsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS checklists (
        id INTEGER PRIMARY KEY,
        vehiculo_id INTEGER,
        fecha TEXT,
        tipo TEXT,
        estado TEXT,
        full_json TEXT,
        last_updated TEXT
      )
    ''');
  }

  Future<void> saveChecklists(
    List<dynamic> checklistsJson, {
    int? vehiculoId,
  }) async {
    final db = await database;
    final batch = db.batch();
    if (vehiculoId != null) {
      await db.delete('checklists', where: 'vehiculo_id = ?', whereArgs: [vehiculoId]);
    } else {
      await db.delete('checklists');
    }
    for (var c in checklistsJson) {
      batch.insert('checklists', {
        'id': c['id'],
        'vehiculo_id': c['vehiculo_id'],
        'fecha': c['fecha'],
        'tipo': c['tipo'],
        'estado': c['estado'],
        'full_json': jsonEncode(c),
        'last_updated': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getChecklists({int? vehiculoId}) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (vehiculoId != null) {
      where = 'vehiculo_id = ?';
      whereArgs = [vehiculoId];
    }

    final results = await db.query(
      'checklists',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'fecha DESC',
    );

    return results.map((row) {
      final String jsonStr = row['full_json'] as String;
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    }).toList();
  }

  // Métodos de utilidad: Combustible
  Future<void> _createCombustibleTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS combustible (
        id INTEGER PRIMARY KEY,
        vehiculo_id INTEGER,
        fecha TEXT,
        cantidad_galones REAL,
        valor_total REAL,
        full_json TEXT,
        last_updated TEXT
      )
    ''');
  }

  Future<void> saveCombustibleLogs(List<dynamic> logsJson) async {
    final db = await database;
    final batch = db.batch();
    for (var l in logsJson) {
      final map = Map<String, dynamic>.from(l as Map);
      final logId = map['registro_id'] ?? map['id'];
      if (logId == null) {
        continue;
      }

      batch.insert('combustible', {
        'id': logId,
        'vehiculo_id': map['vehiculo_id'],
        'fecha': map['fecha'] ?? map['fecha_registro'] ?? map['created_at'],
        'cantidad_galones': map['cantidad_galones'],
        'valor_total': map['valor_total'],
        'full_json': jsonEncode(map),
        'last_updated': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCombustibleLogs({
    int? vehiculoId,
  }) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (vehiculoId != null) {
      where = 'vehiculo_id = ?';
      whereArgs = [vehiculoId];
    }

    final results = await db.query(
      'combustible',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'fecha DESC',
    );

    return results.map((row) {
      final String jsonStr = row['full_json'] as String;
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    }).toList();
  }

  // Métodos de utilidad: Sesiones Offline
  Future<void> _createSesionTrabajoLocalTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sesion_trabajo_local (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT, -- ID local si no ha sincronizado
        server_id INTEGER, -- ID servidor si ya sincronizó pero sigue activa
        user_id INTEGER, -- Mantener por compatibilidad local temporal
        empleado_id INTEGER,
        orden_trabajo_id INTEGER,
        fecha_inicio TEXT,
        fecha_fin TEXT, -- Null si activa
        notas TEXT,
        is_synced INTEGER DEFAULT 1 -- 1 si ya está en servidor, 0 si pendiente
      )
    ''');
  }

  Future<void> saveActiveSessionLocal(
    Map<String, dynamic> session, {
    bool isSynced = true,
  }) async {
    final db = await database;
    // Solo puede haber una activa, limpiamos cualquier otra activa por si acaso
    await db.delete('sesion_trabajo_local', where: 'fecha_fin IS NULL');

    await db.insert('sesion_trabajo_local', {
      'server_id': session['sesion_id'],
      'user_id': session['user_id'] ?? session['empleado_id'],
      'empleado_id': session['empleado_id'],
      'orden_trabajo_id': session['orden_trabajo_id'],
      'fecha_inicio': session['fecha_inicio'],
      'fecha_fin': null,
      'notas': null,
      'is_synced': isSynced ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getActiveSessionLocal() async {
    final db = await database;
    final results = await db.query(
      'sesion_trabajo_local',
      where: 'fecha_fin IS NULL',
      limit: 1,
    );

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<void> closeActiveSessionLocal(String fechaFin, {String? notas}) async {
    final db = await database;
    await db.update('sesion_trabajo_local', {
      'fecha_fin': fechaFin,
      'notas': notas,
    }, where: 'fecha_fin IS NULL');
  }

  // Métodos de utilidad: Bodegas e Inventario
  Future<void> _createBodegasTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bodegas (
        bodega_id INTEGER PRIMARY KEY,
        nombre TEXT,
        descripcion TEXT,
        tipo TEXT, -- estandar, recuperacion
        last_updated TEXT
      )
    ''');
  }

  Future<void> _createBodegaProductoTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bodega_producto (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bodega_id INTEGER,
        producto_id INTEGER,
        cantidad REAL,
        last_updated TEXT,
        UNIQUE(bodega_id, producto_id)
      )
    ''');
  }

  Future<void> saveBodegas(List<dynamic> bodegasJson) async {
    final db = await database;
    final batch = db.batch();
    for (var b in bodegasJson) {
      batch.insert('bodegas', {
        'bodega_id': b['bodega_id'],
        'nombre': b['nombre'],
        'descripcion': b['descripcion'],
        'tipo': b['tipo'],
        'last_updated': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getBodegas() async {
    final db = await database;
    return await db.query('bodegas');
  }

  Future<void> saveInventarioBodegas(List<dynamic> inventarioJson) async {
    final db = await database;
    final batch = db.batch();

    // Opcional: limpiar inventario viejo si es una carga completa
    // await db.delete('bodega_producto');

    for (var item in inventarioJson) {
      batch.insert('bodega_producto', {
        'bodega_id': item['bodega_id'],
        'producto_id': item['producto_id'],
        'cantidad': item['cantidad'],
        'last_updated': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getInventarioProducto(
    int productoId,
  ) async {
    final db = await database;
    // Join para traer info de la bodega (especialmente el tipo)
    return await db.rawQuery(
      '''
      SELECT bp.*, b.nombre as bodega_nombre, b.tipo as bodega_tipo 
      FROM bodega_producto bp
      INNER JOIN bodegas b ON bp.bodega_id = b.bodega_id
      WHERE bp.producto_id = ?
    ''',
      [productoId],
    );
  }

  // Métodos de utilidad: Empleados
  Future<void> _createEmpleadosTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS empleados (
        id INTEGER PRIMARY KEY,
        nombres TEXT,
        apellidos TEXT,
        documento TEXT,
        telefono TEXT,
        direccion TEXT,
        cargo TEXT,
        licencia_conduccion TEXT,
        categoria_licencia TEXT,
        vencimiento_licencia TEXT,
        foto_url TEXT,
        user_id INTEGER,
        estado TEXT,
        last_updated TEXT
      )
    ''');
  }

  Future<void> saveEmpleados(List<dynamic> empleadosJson) async {
    final db = await database;
    final batch = db.batch();
    for (var e in empleadosJson) {
      batch.insert('empleados', {
        'id': e['id'],
        'nombres': e['nombres'],
        'apellidos': e['apellidos'],
        'documento': e['documento'],
        'telefono': e['telefono'],
        'direccion': e['direccion'],
        'cargo': e['cargo'],
        'licencia_conduccion': e['licencia_conduccion'],
        'categoria_licencia': e['categoria_licencia'],
        'vencimiento_licencia': e['vencimiento_licencia'],
        'foto_url': e['foto_url'],
        'user_id': e['user_id'],
        'estado': e['estado'],
        'last_updated': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getEmpleados() async {
    final db = await database;
    return await db.query('empleados', orderBy: 'nombres ASC');
  }

  // Métodos de utilidad: Usuarios y Asignaciones
  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users');
  }

  Future<void> saveUsers(List<dynamic> usersJson) async {
    final db = await database;
    final batch = db.batch();
    for (var u in usersJson) {
      // Adaptar campos si es necesario o guardar direct json
      // Asumimos que el json viene compatible con model User
      // User model: id, name, email, role, phone, license_number, cargo
      batch.insert('users', {
        'id': u['id'],
        'name': u['name'],
        'email': u['email'],
        'role': u['role'],
        'phone': u['phone'],
        'license_number': u['license_number'],
        'cargo': u['cargo'],
        'last_updated': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY,
        name TEXT,
        email TEXT,
        role TEXT,
        phone TEXT,
        license_number TEXT,
        cargo TEXT,
        last_updated TEXT
      )
    ''');
  }

  Future<void> updateVehicleOperator(int vehiculoId, int operatorId) async {
    final db = await database;
    await db.update(
      'vehiculos',
      {
        'operador_asignado_id': operatorId,
        'last_updated': DateTime.now().toIso8601String(),
      },
      where: 'vehiculo_id = ?',
      whereArgs: [vehiculoId],
    );
  }
}
