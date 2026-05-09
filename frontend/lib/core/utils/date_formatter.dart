import 'package:timezone/timezone.dart' as tz;

/// Formatea una fecha mostrando SIEMPRE la hora de Bogotá (America/Bogota UTC-5)
/// sin importar el timezone del dispositivo
String formatFechaBogota(DateTime dateTime, {String format = 'dd/MM/yyyy HH:mm'}) {
  // Obtener timezone de Bogotá
  final bogotaTz = tz.getLocation('America/Bogota');
  
  // Crear TZDateTime en Bogotá
  final tzDateTime = tz.TZDateTime.from(dateTime, bogotaTz);
  
  // Formatear mostrando la hora de Bogotá
  return tzDateTime.toString().substring(0, 16); // YYYY-MM-DD HH:MM
}

/// Formatea una fecha mostrando SIEMPRE la hora de Bogotá
String formatFechaBogotaConFormato(DateTime dateTime, String pattern) {
  // Obtener timezone de Bogotá
  final bogotaTz = tz.getLocation('America/Bogota');
  
  // Crear TZDateTime en Bogotá
  final tzDateTime = tz.TZDateTime.from(dateTime, bogotaTz);
  
  // Usar el timezone de Bogotá para formatear
  return _formatWithPattern(tzDateTime, pattern);
}

String _formatWithPattern(tz.TZDateTime dateTime, String pattern) {
  final year = dateTime.year.toString().padLeft(4, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final second = dateTime.second.toString().padLeft(2, '0');
  
  return pattern
      .replaceAll('yyyy', year)
      .replaceAll('MM', month)
      .replaceAll('dd', day)
      .replaceAll('HH', hour)
      .replaceAll('mm', minute)
      .replaceAll('ss', second);
}
