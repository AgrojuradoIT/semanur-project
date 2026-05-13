import 'package:flutter/foundation.dart';
import 'package:frontend/core/services/notification_service.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/notifications/data/models/notification_item.dart';
import 'package:uuid/uuid.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final NotificationService _notificationService = NotificationService();
  final List<NotificationItem> _notifications = [];

  /// Recibe ApiClient por constructor para evitar instancias sueltas.
  NotificationProvider({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Sincroniza las notificaciones desde el servidor MySQL.
  Future<void> syncFromServer() async {
    try {
      final response = await _apiClient.dio.get('/notifications');

      if (response.statusCode == 200 && response.data?['success'] == true) {
        final List<dynamic> serverNotifs = response.data['data'];
        _notifications.clear();

        for (var n in serverNotifs) {
          _notifications.add(NotificationItem(
            id: n['id'].toString(),
            title: n['titulo'] ?? '',
            body: n['mensaje'] ?? '',
            timestamp: DateTime.tryParse(n['created_at'] ?? '') ?? DateTime.now(),
            type: _mapPrioridadToType(n['prioridad']),
            alertType: n['tipo'] ?? 'general',
            relacionadoId: n['relacionado_id']?.toString(),
            isRead: n['leida'] == true || n['fecha_leido'] != null,
          ));
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error sincronizando notificaciones desde servidor: $e");
    }
  }

  String _mapPrioridadToType(dynamic prioridad) {
    switch (prioridad?.toString()) {
      case 'alta':
        return 'error';
      case 'media':
        return 'warning';
      case 'baja':
        return 'info';
      default:
        return 'info';
    }
  }

  void addNotification({
    required String title,
    required String body,
    String type = 'info',
    String alertType = 'general',
    String? relacionadoId,
    bool showSystemNotification = false,
  }) {
    // Evitar duplicados: misma alerta (mismo tipo + recurso) en el mismo día
    final hoy = DateTime.now();
    final isDuplicate = _notifications.any(
      (n) =>
          n.alertType == alertType &&
          n.relacionadoId == relacionadoId &&
          n.timestamp.year == hoy.year &&
          n.timestamp.month == hoy.month &&
          n.timestamp.day == hoy.day,
    );

    if (isDuplicate) return;

    final notification = NotificationItem(
      id: const Uuid().v4(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
      alertType: alertType,
      relacionadoId: relacionadoId,
    );

    _notifications.insert(0, notification);
    notifyListeners();

    if (showSystemNotification) {
      _notificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        type: alertType,
        relacionadoId: relacionadoId,
      );
    }
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;

    _notifications[index].isRead = true;
    notifyListeners();

    // Sincronizar con servidor
    _markAsReadOnServer(id);
  }

  Future<void> _markAsReadOnServer(String id) async {
    try {
      await _apiClient.dio.post('/notifications/$id/read');
    } catch (e) {
      debugPrint("Error marcando notificación como leída en servidor: $e");
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();

    _markAllAsReadOnServer();
  }

  Future<void> _markAllAsReadOnServer() async {
    try {
      await _apiClient.dio.post('/notifications/read-all');
    } catch (e) {
      debugPrint("Error marcando todas como leídas en servidor: $e");
    }
  }

  /// Elimina una notificación del servidor y la quita de la lista en memoria.
  Future<void> deleteNotification(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;

    // Optimistic: remover de UI primero
    final removed = _notifications.removeAt(index);
    notifyListeners();

    try {
      await _apiClient.dio.delete('/notifications/$id');
    } catch (e) {
      // Rollback si falla
      _notifications.insert(index, removed);
      notifyListeners();
      debugPrint("Error eliminando notificación en servidor: $e");
    }
  }

  /// Elimina todas las notificaciones leídas del servidor.
  Future<void> deleteReadNotifications() async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    final removed = _notifications.where((n) => n.isRead).toList();

    if (removed.isEmpty) return;

    _notifications.clear();
    _notifications.addAll(unread);
    notifyListeners();

    try {
      await _apiClient.dio.delete('/notifications/read');
    } catch (e) {
      // Rollback
      _notifications.addAll(removed);
      notifyListeners();
      debugPrint("Error eliminando notificaciones leídas: $e");
    }
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}
