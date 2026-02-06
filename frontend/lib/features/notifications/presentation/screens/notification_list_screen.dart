import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationListScreen extends StatelessWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Marcar todo como leido al salir (o al entrar, depende de preferencia UX)
    // Lo haremos al construir la pantalla o con un botón "Marcar todo"

    return Scaffold(
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
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Borrar todo',
            onPressed: () {
              context.read<NotificationProvider>().clearAll();
            },
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
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  // Implementar borrar individual si se desea
                  // Por ahora solo UI visual
                },
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
                        color: _getColorForType(
                          item.type,
                        ).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForType(item.type),
                        color: _getColorForType(item.type),
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: GoogleFonts.oswald(
                        fontWeight: item.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
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
                        Text(
                          timeago.format(item.timestamp, locale: 'es'),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textGray,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      provider.markAsRead(item.id);
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

  IconData _getIconForType(String type) {
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
