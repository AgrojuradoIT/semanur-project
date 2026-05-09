class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String type; // 'info', 'warning', 'error', 'success' (UI display)
  final String alertType; // 'stock_bajo', 'inventory_alert', 'work_order', 'fleet_alert', 'general'
  final String? relacionadoId; // ID del recurso relacionado (producto, OT, vehículo)
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.type = 'info',
    this.alertType = 'general',
    this.relacionadoId,
    this.isRead = false,
  });
}
