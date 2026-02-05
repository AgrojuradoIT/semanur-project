import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl {
    return dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000/api';
  }

  // Auth
  static const String login = '/login';
  static const String logout = '/logout';
  static const String user = '/user';

  // Inventario
  static const String productos = '/productos';
  static const String buscarProductos = '/productos/buscar';

  // Órdenes de Trabajo
  static const String ordenesTrabajo = '/ordenes-trabajo';
}
