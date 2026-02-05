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

    // Incrementamos a versión 6 para incluir cache de Checklists y Combustible
    return await openDatabase(
      path,
      version: 6,
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
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createVehiculosTable(db);
    await _createProductosTable(db);
    await _createSyncQueueTable(db);
    await _createOrdenesTrabajoTable(db);
    await _createChecklistsTable(db);
    await _createCombustibleTable(db);
  }

  Future<void> _createVehiculosTable(Database db) async {
    await db.execute('''
      CREATE TABLE vehiculos (
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
        last_updated TEXT
      )
    ''');
  }

  Future<void> _createProductosTable(Database db) async {
    // Schema alineado con product_model.dart
    await db.execute('''
      CREATE TABLE productos (
        producto_id INTEGER PRIMARY KEY,
        categoria_id INTEGER,
        producto_sku TEXT,
        producto_nombre TEXT,
        producto_unidad_medida TEXT,
        producto_stock_actual REAL,
        producto_alerta_stock_minimo REAL,
        producto_precio_costo REAL,
        producto_ubicacion TEXT,
        categoria TEXT, 
        last_updated TEXT
      )
    ''');
  }

  Future<void> _createSyncQueueTable(Database db) async {
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        endpoint TEXT,
        method TEXT,
        payload TEXT,
        image_path TEXT,
        created_at TEXT,
        attempts INTEGER DEFAULT 0
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

    return await db.insert('sync_queue', {
      'endpoint': endpoint,
      'method': method,
      'payload': payloadStr,
      'image_path': imagePath,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await database;
    return await db.query('sync_queue', orderBy: 'created_at ASC');
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

  // Métodos de utilidad: Órdenes de Trabajo (Cache Offline)
  Future<void> _createOrdenesTrabajoTable(Database db) async {
    await db.execute('''
      CREATE TABLE ordenes_trabajo (
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
      batch.insert('ordenes_trabajo', {
        'id': o['id'],
        'vehiculo_id': o['vehiculo_id'],
        'prioridad': o['prioridad'],
        'estado': o['estado'],
        'descripcion': o['descripcion'],
        'full_json': jsonEncode(o),
        'last_updated': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
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
      CREATE TABLE checklists (
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

  Future<void> saveChecklists(List<dynamic> checklistsJson) async {
    final db = await database;
    final batch = db.batch();
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
      CREATE TABLE combustible (
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
      batch.insert('combustible', {
        'id': l['id'],
        'vehiculo_id': l['vehiculo_id'],
        'fecha': l['fecha_registro'], // Assuming the API returns this field
        'cantidad_galones': l['cantidad_galones'],
        'valor_total': l['valor_total'],
        'full_json': jsonEncode(l),
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
}
