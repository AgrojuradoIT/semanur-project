import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl {
    // Prioridad: 1) Variable de entorno, 2) Valor hardcoded producción, 3) Default localhost
    String? envUrl = dotenv.env['API_URL'];
    
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // Fallback hardcoded para producción (evita problemas si .env no carga)
    const String productionUrl = 'https://backsm.agrojurado.com/api';
    
    if (kDebugMode) {
      // En debug, usar localhost para desarrollo
      return 'http://10.0.2.2:8000/api'; // Android emulator
    }
    
    // En release, siempre usar producción
    return productionUrl;
  }

  // Auth
  static const String login = '/login';
  static const String logout = '/logout';
  static const String refresh = '/refresh';
  static const String logoutAll = '/logout-all';
  static const String user = '/user';

  // Inventario
  static const String productos = '/productos';
  static const String buscarProductos = '/productos/buscar';
  static const String importarProductos = '/productos/import';

  // Órdenes de Trabajo
  static const String ordenesTrabajo = '/ordenes-trabajo';
}
