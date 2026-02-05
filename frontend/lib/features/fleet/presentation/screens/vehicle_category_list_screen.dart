import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/features/fleet/presentation/providers/fleet_provider.dart';
import 'package:frontend/features/fleet/presentation/screens/vehicle_resume_screen.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/fleet/data/models/vehicle_model.dart';

class VehicleCategoryListScreen extends StatelessWidget {
  final String category; // 'Tractores', 'Volquetas', etc.
  final String filterType; // 'tractor', 'volqueta', etc.

  const VehicleCategoryListScreen({
    super.key,
    required this.category,
    required this.filterType,
  });

  @override
  Widget build(BuildContext context) {
    // Usamos watch para escuchar cambios
    final provider = context.watch<FleetProvider>();
    final vehicles = provider.vehiculos
        .where((v) => v.tipo.toLowerCase() == filterType.toLowerCase())
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        title: Text(
          category.toUpperCase(),
          style: GoogleFonts.oswald(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: vehicles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.no_transfer,
                    size: 64,
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay vehículos en esta categoría',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return _buildVehicleCard(context, vehicle);
              },
            ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, Vehiculo vehicle) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VehicleResumeScreen(
              vehiculoId: vehicle.id,
              placa: vehicle.placa,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppTheme.surfaceDark2),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.backgroundDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIconForType(vehicle.tipo),
                color: AppTheme.primaryYellow,
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.placa.toUpperCase(),
                    style: GoogleFonts.oswald(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${vehicle.marca} ${vehicle.modelo}',
                    style: const TextStyle(
                      color: AppTheme.textGray,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textGray,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'tractor':
        return Icons.agriculture;
      case 'volqueta':
        return Icons.local_shipping;
      case 'camioneta':
        return Icons.directions_car;
      case 'moto':
        return Icons.two_wheeler;
      case 'maquinaria':
        return Icons.construction;
      default:
        return Icons.directions_bus;
    }
  }
}
