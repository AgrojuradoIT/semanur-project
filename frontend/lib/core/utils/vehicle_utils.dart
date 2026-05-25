/// Utility functions to determine vehicle/machinery classification.
///
/// Business rules for Semanur Zomac S.A.S.:
///   - MACHINERY (Yellow): Tractors, Excavators, Bulldozers, Retros → Hourmeter-based
///   - ROAD VEHICLES: Volquetas, Camionetas, Camión, Motos → Km-based + SOAT/RTM required
library vehicle_utils;

/// Returns true if the vehicle type is classified as heavy/yellow machinery.
/// These units do NOT have SOAT, Tecnomecánica, or meaningful odometer readings.
bool isMachinery(String? tipo) {
  if (tipo == null || tipo.isEmpty) return false;
  final t = tipo.toLowerCase().trim();
  return t.contains('tractor') ||
      t.contains('maquinaria') ||
      t.contains('buldozer') ||
      t.contains('bulldozer') ||
      t.contains('retro') ||
      t.contains('excavadora') ||
      t.contains('excavator') ||
      t.contains('guadaña') ||
      t.contains('motosierra') ||
      t.contains('planta electrica') ||
      t.contains('planta eléctrica');
}

/// Returns true if the vehicle type requires regulatory road documents
/// (SOAT and Tecnomecánica).
bool requiresRoadDocuments(String? tipo) {
  if (tipo == null || tipo.isEmpty) return false;
  final t = tipo.toLowerCase().trim();
  return t == 'volqueta' ||
      t == 'camioneta' ||
      t == 'camion' ||
      t == 'camión' ||
      t == 'moto';
}

/// Returns true if the primary measurement unit for this vehicle is kilometers.
/// False means the primary unit is hourmeter (hours).
bool usesPrimaryKilometers(String? tipo) {
  return !isMachinery(tipo);
}

/// Returns the primary measurement label for this vehicle type.
String primaryMeasurementLabel(String? tipo) {
  return isMachinery(tipo) ? 'Horómetro (h)' : 'Kilometraje (km)';
}

/// Returns the primary measurement unit suffix for display.
String primaryMeasurementUnit(String? tipo) {
  return isMachinery(tipo) ? 'h' : 'km';
}

/// Returns the default next maintenance interval based on type.
/// Machinery: 250 hours. Road vehicle: 5000 km.
double defaultMaintenanceInterval(String? tipo) {
  return isMachinery(tipo) ? 250.0 : 5000.0;
}
