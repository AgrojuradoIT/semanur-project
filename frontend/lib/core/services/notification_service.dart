import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../main.dart'; // Para navigatorKey
import '../database/database_helper.dart';
import '../network/api_client.dart';
import '../../features/notifications/notification_navigator.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int _dailyReminderMorningId = 1001;
  static const int _dailyReminderAfternoonId = 1002;
  static const String _dailyRemindersConfiguredKey =
      'daily_reminders_configured_v1';

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  ApiClient? _apiClient;

  // Datos de la notificación si la app se abrió desde una
  Map<String, String?>? _pendingNotification;

  Future<void> init({ApiClient? apiClient}) async {
    _apiClient = apiClient;
    tz.initializeTimeZones();

    // Comprobar si la app se lanzó desde una notificación
    final NotificationAppLaunchDetails? launchDetails =
        await _notificationsPlugin.getNotificationAppLaunchDetails();

    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final String? payload = launchDetails?.notificationResponse?.payload;
      if (payload != null) {
        try {
          final int dbId = int.parse(payload);
          final notification = await _dbHelper.getNotificationById(dbId);
          if (notification != null) {
            _pendingNotification = {
              'type': notification['tipo'],
              'relacionadoId': notification['relacionado_id'],
              'dbId': dbId.toString(),
            };
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint("Error parseando launch notification: $payload - $e");
          }
        }
      }
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    const WindowsInitializationSettings initializationSettingsWindows =
        WindowsInitializationSettings(
      appName: 'Semanur HUB',
      appUserModelId: 'com.semanur.hub',
      guid: 'A181F50B-268E-4B9A-AAED-285027D9994C',
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          linux: initializationSettingsLinux,
          windows: initializationSettingsWindows,
        );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          try {
            final int dbId = int.parse(response.payload!);
            final notification = await _dbHelper.getNotificationById(dbId);
            if (notification != null) {
              await markNotificationAsRead(dbId);
              await NotificationNavigator.navigateTo(
                alertType: notification['tipo'],
                relacionadoId: notification['relacionado_id'],
                navigatorState: navigatorKey.currentState,
              );
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint("Error al procesar click de notificacion: $e");
            }
          }
        }
      },
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();

    await ensureDailyRemindersConfiguredOnce();
  }

  /// Sincronizar notificaciones desde el servidor MySQL.
  /// Fuente principal de push del SO (generadas por el scheduler 7am/2pm).
  Future<void> syncNotificationsFromServer() async {
    if (_apiClient == null) return;
    final token = await _storage.read(key: 'auth_token');
    if (token == null || token.isEmpty) return;

    try {
      final response = await _apiClient!.dio.get('/notifications?unread_only=1');

      if (response.statusCode == 200 && response.data?['success'] == true) {
        final List<dynamic> serverNotifications = response.data['data'];

        for (var n in serverNotifications) {
          final String tipo = n['tipo'] ?? 'general';
          final String titulo = n['titulo'] ?? '';
          final String mensaje = n['mensaje'] ?? '';
          final String? relId = n['relacionado_id']?.toString();
          final int serverId = n['id'];

          // Deduplicar contra SQLite: solo emitir push si no existe de hoy
          final bool yaExiste = await _dbHelper.hasNotificationToday(
            tipo: tipo,
            relacionadoId: relId,
          );

          if (!yaExiste) {
            final int localNotifyId = 30000 + serverId;
            await showNotification(
              id: localNotifyId,
              title: titulo,
              body: mensaje,
              type: tipo,
              relacionadoId: relId,
              serverId: serverId, // ← ahora se persiste
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error sincronizando notificaciones desde el servidor: $e");
      }
    }
  }

  Future<void> processPendingNotification() async {
    if (_pendingNotification != null) {
      final String? type = _pendingNotification!['type'];
      final String? relacionadoId = _pendingNotification!['relacionadoId'];
      final String? dbIdStr = _pendingNotification!['dbId'];

      if (dbIdStr != null) {
        final int dbId = int.parse(dbIdStr);
        await markNotificationAsRead(dbId);
      }

      await NotificationNavigator.navigateTo(
        alertType: type,
        relacionadoId: relacionadoId,
        navigatorState: navigatorKey.currentState,
      );
      _pendingNotification = null;
    }
  }

  /// Muestra una notificación push del SO y la persiste en SQLite.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? type,
    String? relacionadoId,
    String? payload,
    int? serverId,
  }) async {
    // 1. Persistir en Base de Datos local (con server_id para sync bidireccional)
    final String nextReminder = DateTime.now()
        .add(const Duration(days: 3))
        .toIso8601String();

    final int dbId = await _dbHelper.saveNotification(
      tipo: type ?? 'general',
      titulo: title,
      mensaje: body,
      relacionadoId: relacionadoId,
      fechaProximoRecordatorio: nextReminder,
      serverId: serverId,
    );

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'semanur_alerts',
          'Alertas Semanur',
          channelDescription:
              'Notificaciones de vencimientos y alertas criticas',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: dbId.toString(),
    );
  }

  /// Marca una notificación como leída en SQLite Y en el servidor (si hay server_id).
  Future<void> markNotificationAsRead(int dbId) async {
    await _dbHelper.markNotificationAsRead(dbId);

    // Sincronizar con el servidor usando el server_id guardado en SQLite
    if (_apiClient != null) {
      try {
        final int? serverId =
            await _dbHelper.getServerIdForLocalNotification(dbId);
        if (serverId != null) {
          await _apiClient!.dio.post('/notifications/$serverId/read');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint("Error sincronizando 'leído' con servidor para dbId=$dbId: $e");
        }
      }
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'semanur_scheduled',
          'Alertas Programadas',
          channelDescription: 'Recordatorios de vencimiento de documentos',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleDailyReminders() async {
    await _scheduleDaily(
      id: _dailyReminderMorningId,
      hour: 8,
      title: 'Recordatorio Semanur',
      body: 'Revisa pendientes y sincroniza tu informacion.',
    );

    await _scheduleDaily(
      id: _dailyReminderAfternoonId,
      hour: 15,
      title: 'Recordatorio Semanur',
      body: 'No olvides validar y sincronizar tus registros del dia.',
    );
  }

  Future<void> ensureDailyRemindersConfiguredOnce() async {
    final isConfigured = await _storage.read(key: _dailyRemindersConfiguredKey);
    if (isConfigured == 'true') {
      return;
    }

    await scheduleDailyReminders();
    await _storage.write(key: _dailyRemindersConfiguredKey, value: 'true');
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'semanur_daily',
          'Recordatorios Diarios',
          channelDescription: 'Recordatorios diarios de Semanur',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminders() async {
    await _notificationsPlugin.cancel(id: _dailyReminderMorningId);
    await _notificationsPlugin.cancel(id: _dailyReminderAfternoonId);
    await _storage.delete(key: _dailyRemindersConfiguredKey);
  }
}
