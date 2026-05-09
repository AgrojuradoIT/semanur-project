import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:frontend/core/services/notification_service.dart';
import 'package:frontend/core/network/api_client.dart';
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
          final apiClient = ApiClient();
          await NotificationService().init(apiClient: apiClient);
          
          // Sincronizar nuevas alertas del servidor Laravel
          await NotificationService().syncNotificationsFromServer();

          final dbHelper = DatabaseHelper();

          // 1. Lógica de Re-notificación (cada 3 días si no ha sido atendido)
          final dueNotifications = await dbHelper.getDueNotifications();
          for (var notification in dueNotifications) {
            final int id = notification['id'];
            final String title = notification['titulo'];
            final String body = notification['mensaje'];
            final String type = notification['tipo'];
            final String? relacionadoId = notification['relacionado_id'];

            // Mostrar de nuevo la notificación del sistema
            await NotificationService().showNotification(
              id: id + 20000, // Offset para el sistema
              title: 'Recordatorio: $title',
              body: body,
              type: type,
              relacionadoId: relacionadoId,
            );

            // Actualizar próximo recordatorio (+3 días)
            final String nextDate = DateTime.now()
                .add(const Duration(days: 3))
                .toIso8601String();
            await dbHelper.updateNotificationReminder(id, nextDate);
          }

          // 2. Consultar alertas de flota vencidas en DB local
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
                    v.fechaVencimientoTecnomecanica!.isBefore(sevenDaysFromNow)) {
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
                id: 9999,
                title: 'Atención: Alertas de Flota',
                body: 'Tienes $alertCount vehículos con pendientes. Revisa la flota.',
                type: 'fleet_summary',
                relacionadoId: 'all_fleet',
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
