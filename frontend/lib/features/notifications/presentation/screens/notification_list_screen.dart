import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/semanur_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:frontend/features/notifications/data/models/notification_item.dart';
import 'package:frontend/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:frontend/features/inventory/presentation/screens/product_detail_screen.dart';
import 'package:frontend/features/inventory/data/models/product_model.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/workshop/presentation/screens/work_order_list_screen.dart';
import 'package:frontend/features/fleet/presentation/screens/vehicle_list_screen.dart';
import 'package:frontend/features/fleet/presentation/screens/vehicle_resume_screen.dart';
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
    // Sincronizar con MySQL al abrir la pantalla
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
                        _getIconForAlertType(item.alertType, item.type),
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
                      _navigateTo(context, item);
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

  bool _canNavigate(String alertType) {
    return alertType != 'general';
  }

  void _navigateTo(BuildContext context, NotificationItem item) {
    switch (item.alertType) {
      case 'stock_bajo':
      case 'inventory_alert':
        _navigateToProducto(context, item.relacionadoId);
        break;

      case 'work_order':
      case 'orden_trabajo':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WorkOrderListScreen()),
        );
        break;

      case 'fleet_alert':
      case 'vencimiento_soat':
      case 'vencimiento_tecnomecanica':
      case 'mantenimiento_preventivo':
        // relacionadoId = 'vehiculoId|placa'
        final partes = item.relacionadoId?.split('|');
        final vehiculoId = int.tryParse(partes?.first ?? '');
        final placa = partes != null && partes.length > 1 ? partes[1] : 'VH';

        if (vehiculoId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VehicleResumeScreen(
                vehiculoId: vehiculoId,
                placa: placa,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VehicleListScreen()),
          );
        }
        break;

      default:
        break;
    }
  }

  /// Navega al detalle del producto por su ID desde la API.
  Future<void> _navigateToProducto(BuildContext context, String? relacionadoId) async {
    final int? productoId = int.tryParse(relacionadoId ?? '');
    if (productoId == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen()));
      return;
    }

    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get('/productos/$productoId');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map<String, dynamic>
            ? response.data
            : response.data['data'] ?? response.data;
        final producto = Producto.fromJson(data);
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductDetailScreen(producto: producto)),
          );
        }
        return;
      }
    } catch (e) {
      debugPrint("Error buscando producto para notificación in-app: $e");
    }

    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen()));
    }
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
        // Fallback por tipo UI
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
