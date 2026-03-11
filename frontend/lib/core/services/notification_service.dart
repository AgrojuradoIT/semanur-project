import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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

  Future<void> init() async {
    tz.initializeTimeZones();

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
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Manejar cuando se toca la notificacion.
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

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
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
      payload: payload,
    );
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
