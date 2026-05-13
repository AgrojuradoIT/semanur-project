import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:frontend/features/inventory/presentation/screens/product_detail_screen.dart';
import 'package:frontend/features/inventory/data/models/product_model.dart';
import 'package:frontend/features/workshop/presentation/screens/work_order_list_screen.dart';
import 'package:frontend/features/fleet/presentation/screens/vehicle_list_screen.dart';
import 'package:frontend/features/fleet/presentation/screens/vehicle_resume_screen.dart';

/// Centraliza toda la lógica de navegación disparada por notificaciones.
/// Usado tanto desde push del SO (NotificationService) como desde la UI in-app.
///
/// [context] es opcional: si se pasa, usa Navigator.push directamente.
/// Si es null, usa navigatorKey.currentState (modo background/push).
class NotificationNavigator {
  NotificationNavigator._();

  /// Navega a la pantalla correspondiente al tipo de notificación.
  /// Retorna [true] si la navegación fue posible, [false] si el tipo es desconocido.
  static Future<bool> navigateTo({
    required String? alertType,
    required String? relacionadoId,
    BuildContext? context,
    NavigatorState? navigatorState,
  }) async {
    final nav = navigatorState ?? _resolveNavigator(context);
    if (nav == null) return false;

    switch (alertType) {
      case 'inventory_alert':
      case 'stock_bajo':
        await _navigateToProducto(nav, relacionadoId);
        return true;

      case 'work_order':
      case 'orden_trabajo':
        nav.push(
          MaterialPageRoute(builder: (_) => const WorkOrderListScreen()),
        );
        return true;

      case 'fleet_alert':
      case 'vencimiento_soat':
      case 'vencimiento_tecnomecanica':
      case 'mantenimiento_preventivo':
        _navigateToFlota(nav, relacionadoId);
        return true;

      default:
        if (kDebugMode) {
          debugPrint('[NotificationNavigator] Tipo desconocido: $alertType');
        }
        return false;
    }
  }

  static void _navigateToFlota(NavigatorState nav, String? relacionadoId) {
    // relacionadoId = 'vehiculoId|placa'
    final partes = relacionadoId?.split('|');
    final vehiculoId = int.tryParse(partes?.first ?? '');
    final placa = (partes != null && partes.length > 1) ? partes[1] : 'VH';

    if (vehiculoId != null) {
      nav.push(
        MaterialPageRoute(
          builder: (_) => VehicleResumeScreen(
            vehiculoId: vehiculoId,
            placa: placa,
          ),
        ),
      );
    } else {
      nav.push(
        MaterialPageRoute(builder: (_) => const VehicleListScreen()),
      );
    }
  }

  /// Navega al detalle del producto por su ID desde la API.
  /// Fallback a la lista general si el producto no se encuentra.
  static Future<void> _navigateToProducto(
    NavigatorState nav,
    String? relacionadoId,
  ) async {
    final int? productoId = int.tryParse(relacionadoId ?? '');
    if (productoId == null) {
      nav.push(MaterialPageRoute(builder: (_) => const InventoryScreen()));
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
        nav.push(
          MaterialPageRoute(builder: (_) => ProductDetailScreen(producto: producto)),
        );
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationNavigator] Error buscando producto $productoId: $e');
      }
    }

    // Fallback a lista general
    nav.push(MaterialPageRoute(builder: (_) => const InventoryScreen()));
  }

  /// Resuelve el NavigatorState desde un BuildContext si está disponible.
  static NavigatorState? _resolveNavigator(BuildContext? context) {
    if (context != null) {
      return Navigator.of(context);
    }
    return null;
  }
}
