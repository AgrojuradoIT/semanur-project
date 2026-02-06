import 'package:flutter/foundation.dart';
import 'package:frontend/core/services/notification_service.dart';
import 'package:frontend/features/notifications/data/models/notification_item.dart';
import 'package:uuid/uuid.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final List<NotificationItem> _notifications = [];

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void addNotification({
    required String title,
    required String body,
    String type = 'info',
    bool showSystemNotification = false,
  }) {
    // Evitar duplicados recientes (simple debounce por contenido)
    final isDuplicate = _notifications.any(
      (n) =>
          n.title == title &&
          n.body == body &&
          DateTime.now().difference(n.timestamp).inMinutes < 60,
    );

    if (isDuplicate) return;

    final notification = NotificationItem(
      id: const Uuid().v4(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
    );

    _notifications.insert(0, notification);
    notifyListeners();

    if (showSystemNotification) {
      _notificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
      );
    }
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}
