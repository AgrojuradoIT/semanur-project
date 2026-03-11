import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:frontend/core/services/notification_service.dart';
import 'package:frontend/core/database/database_helper.dart';
import 'package:frontend/features/fleet/data/models/vehicle_model.dart';

const fetchBackground = "fetchBackground";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case fetchBackground:
        try {
          // Inicializar dependencias mínimas para background
          if (Platform.isWindows || Platform.isLinux) {
            sqfliteFfiInit();
            databaseFactory = databaseFactoryFfi;
          }

          // Inicializar notificaciones (necesario para enviar alertas)
          await NotificationService().init();

          // Consultar vehículos vencidos en DB local
          final vehicles = await _getLocalVehicles();

          if (vehicles.isNotEmpty) {
            final now = DateTime.now();
            final sevenDaysFromNow = now.add(const Duration(days: 7));
            int alertCount = 0;

            for (var v in vehicles) {
              bool hasAlert = false;

              // SOAT
              if (v.fechaVencimientoSoat != null) {
                if (v.fechaVencimientoSoat!.isBefore(now) ||
                    v.fechaVencimientoSoat!.isBefore(sevenDaysFromNow)) {
                  hasAlert = true;
                }
              }

              // Tecno
              if (!hasAlert && v.fechaVencimientoTecnomecanica != null) {
                if (v.fechaVencimientoTecnomecanica!.isBefore(now) ||
                    v.fechaVencimientoTecnomecanica!.isBefore(
                      sevenDaysFromNow,
                    )) {
                  hasAlert = true;
                }
              }

              // Mantenimiento
              if (!hasAlert &&
                  v.kilometrajeProximoMantenimiento != null &&
                  v.kilometrajeActual >= v.kilometrajeProximoMantenimiento!) {
                hasAlert = true;
              }

              if (!hasAlert &&
                  v.horometroProximoMantenimiento != null &&
                  v.horometroActual >= v.horometroProximoMantenimiento!) {
                hasAlert = true;
              }

              if (hasAlert) alertCount++;
            }

            if (alertCount > 0) {
              await NotificationService().showNotification(
                id: 9999, // ID fijo para resumen background
                title: 'Atención: Documentos y Mantenimientos',
                body:
                    'Tienes $alertCount vehículos con alertas pendientes. Revisa la flota.',
                payload: 'fleet_screen',
              );
            }
          }
        } catch (e) {
          debugPrint("Error en tarea background: $e");
          return Future.value(false);
        }
        break;
    }
    return Future.value(true);
  });
}

Future<List<Vehiculo>> _getLocalVehicles() async {
  try {
    // Usamos una instancia fresca de DatabaseHelper o acceso directo
    // Nota: DatabaseHelper usa path_provider que requiere inicialización de binding
    // En background task de Android a veces path_provider falla si no se inicializa bien
    // Pero Workmanager maneja el Dart environment.

    final dbHelper = DatabaseHelper();
    final data = await dbHelper.getVehiculos();
    return data.map((json) => Vehiculo.fromJson(json)).toList();
  } catch (e) {
    debugPrint("Error leyendo DB local en background: $e");
    return [];
  }
}
