import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/semanur_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:frontend/features/notifications/notification_navigator.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().syncFromServer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SemanurScaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          'NOTIFICACIONES',
          style: GoogleFonts.oswald(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Marcar todo como leído',
            onPressed: () {
              context.read<NotificationProvider>().markAllAsRead();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              final provider = context.read<NotificationProvider>();
              if (value == 'delete_read') {
                final confirm = await _showDeleteConfirm(
                  'Eliminar leídas',
                  '¿Eliminar todas las notificaciones ya leídas?',
                );
                if (confirm == true) await provider.deleteReadNotifications();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete_read',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Eliminar leídas'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          final notifications = provider.notifications;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 80,
                    color: AppTheme.textGray.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No tienes notificaciones',
                    style: GoogleFonts.oswald(
                      fontSize: 20,
                      color: AppTheme.textGray,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];
              return Dismissible(
                key: Key(item.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _showDeleteConfirm(
                  'Eliminar notificación',
                  '¿Eliminar esta notificación?',
                ),
                onDismissed: (_) {
                  provider.deleteNotification(item.id);
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete, color: Colors.white),
                      SizedBox(height: 4),
                      Text(
                        'Eliminar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                child: Card(
                  color: item.isRead
                      ? AppTheme.surfaceDark.withValues(alpha: 0.5)
                      : AppTheme.surfaceDark,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: item.isRead
                          ? Colors.transparent
                          : AppTheme.primaryYellow.withValues(alpha: 0.5),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getColorForType(item.type).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForAlertType(item.alertType, item.type),
                        color: _getColorForType(item.type),
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: GoogleFonts.oswald(
                        fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text(
                          item.body,
                          style: const TextStyle(color: AppTheme.textGray),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              timeago.format(item.timestamp, locale: 'es'),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textGray,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            if (_canNavigate(item.alertType))
                              Text(
                                'Ver detalle →',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.primaryYellow,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () {
                      provider.markAsRead(item.id);
                      NotificationNavigator.navigateTo(
                        alertType: item.alertType,
                        relacionadoId: item.relacionadoId,
                        context: context,
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  bool _canNavigate(String alertType) => alertType != 'general';

  Future<bool?> _showDeleteConfirm(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(title, style: GoogleFonts.oswald(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: AppTheme.textGray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'error':
        return Colors.red;
      case 'warning':
        return AppTheme.primaryYellow;
      case 'success':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData _getIconForAlertType(String alertType, String type) {
    switch (alertType) {
      case 'stock_bajo':
        return Icons.inventory_2_outlined;
      case 'inventory_alert':
        return Icons.warning_amber_rounded;
      case 'work_order':
      case 'orden_trabajo':
        return Icons.build_circle_outlined;
      case 'fleet_alert':
      case 'vencimiento_soat':
      case 'vencimiento_tecnomecanica':
      case 'mantenimiento_preventivo':
        return Icons.directions_car_outlined;
      default:
        switch (type) {
          case 'error':
            return Icons.error_outline;
          case 'warning':
            return Icons.warning_amber_rounded;
          case 'success':
            return Icons.check_circle_outline;
          default:
            return Icons.info_outline;
        }
    }
  }
}
