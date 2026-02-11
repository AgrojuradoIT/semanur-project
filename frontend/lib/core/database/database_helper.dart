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
      version: 12,
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
    if (oldVersion < 8) {
      await _createAnalyticsTable(db);
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
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createVehiculosTable(db);
    await _createProductosTable(db);
    await _createSyncQueueTable(db);
    await _createOrdenesTrabajoTable(db);
    await _createChecklistsTable(db);
    await _createCombustibleTable(db);
    await _createSesionTrabajoLocalTable(db);
    await _createAnalyticsTable(db);
    await _createBodegasTable(db);
    await _createBodegaProductoTable(db);
    await _createUsersTable(db);
    await _createEmpleadosTable(db);
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

  // Métodos de utilidad: Sesiones Offline
  Future<void> _createSesionTrabajoLocalTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sesion_trabajo_local (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT, -- ID local si no ha sincronizado
        server_id INTEGER, -- ID servidor si ya sincronizó pero sigue activa
        user_id INTEGER,
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
    // O asumimos que la app maneja una sola sesión por usuario
    // Borrar sesiones activas previas para garantizar consistencia local
    await db.delete('sesion_trabajo_local', where: 'fecha_fin IS NULL');

    await db.insert('sesion_trabajo_local', {
      'server_id': session['sesion_id'], // Puede ser null o provisional
      'user_id': session['user_id'],
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

  // Métodos de utilidad: Analytics Cache
  Future<void> _createAnalyticsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS analytics_cache (
        key TEXT PRIMARY KEY,
        data TEXT,
        last_updated TEXT
      )
    ''');
  }

  Future<void> saveAnalyticsCache(String key, dynamic data) async {
    final db = await database;
    await db.insert('analytics_cache', {
      'key': key,
      'data': jsonEncode(data),
      'last_updated': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<dynamic> getAnalyticsCache(String key) async {
    final db = await database;
    final results = await db.query(
      'analytics_cache',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (results.isNotEmpty) {
      return jsonDecode(results.first['data'] as String);
    }
    return null;
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
        dependencia TEXT,
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
        'dependencia': e['dependencia'],
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
      // User model: id, name, email, role, phone, license_number, cargo, dependencia
      batch.insert('users', {
        'id': u['id'],
        'name': u['name'],
        'email': u['email'],
        'role': u['role'],
        'phone': u['phone'],
        'license_number': u['license_number'],
        'cargo': u['cargo'],
        'dependencia': u['dependencia'],
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
        dependencia TEXT,
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
