import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/semanur_scaffold.dart';
import 'package:frontend/features/fleet/data/models/vehicle_model.dart';
import 'package:frontend/features/fleet/presentation/providers/fleet_provider.dart';
import 'package:frontend/features/preoperacionales/presentation/screens/daily_form_screen.dart';
import 'package:frontend/core/widgets/semanur_autocomplete.dart';

class VehicleSelectionScreen extends StatefulWidget {
  const VehicleSelectionScreen({super.key});

  @override
  State<VehicleSelectionScreen> createState() =>
      _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  Vehiculo? _selectedVehicle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FleetProvider>().fetchVehiculos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fleetProvider = context.watch<FleetProvider>();

    return SemanurScaffold(
      showBottomNav: false,
      appBar: AppBar(
        title: Text(
          'SELECCIONAR VEHÍCULO',
          style: GoogleFonts.oswald(letterSpacing: 1),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: fleetProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Autocomplete search bar section
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: AppTheme.surfaceDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BUSCAR VEHÍCULO',
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppTheme.primaryYellow,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SemanurAutocomplete<Vehiculo>(
                          key: ValueKey(_selectedVehicle?.id ?? 'none'),
                          options: fleetProvider.vehiculos,
                          initialValue: _selectedVehicle,
                          hint: 'Escribe placa, marca, modelo o tipo...',
                          displayStringForOption: (v) =>
                              '${v.placa.toUpperCase()} - ${v.marca} ${v.modelo}',
                          filterFn: (v, filter) =>
                              v.placa.toLowerCase().contains(filter) ||
                              v.marca.toLowerCase().contains(filter) ||
                              v.modelo.toLowerCase().contains(filter) ||
                              v.tipo.toLowerCase().contains(filter),
                          onSelected: (v) => setState(() => _selectedVehicle = v),
                        ),
                      ],
                    ),
                  ),

                  // Dynamic body section based on selection
                  Expanded(
                    child: _selectedVehicle == null
                        ? _buildOnboardingView()
                        : _buildSelectedVehicleView(_selectedVehicle!),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOnboardingView() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.surfaceDark2, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryYellow.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.assignment_turned_in_outlined,
                    color: AppTheme.primaryYellow,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Inspección Diaria',
                  style: GoogleFonts.oswald(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Selecciona un vehículo usando el buscador de arriba para iniciar la lista de chequeo preoperacional.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    color: AppTheme.textGray,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedVehicleView(Vehiculo vehicle) {
    final icon = _getIconForType(vehicle.tipo);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.surfaceDark2, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Vehicle Header
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryYellow.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(icon, color: AppTheme.primaryYellow, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.placa.toUpperCase(),
                            style: GoogleFonts.oswald(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundDark,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _capitalize(vehicle.tipo),
                              style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryYellow,
                                  letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(
                  color: AppTheme.surfaceDark2,
                  height: 1,
                  thickness: 1,
                ),
                const SizedBox(height: 24),

                // Vehicle properties
                _buildDetailRow('Marca:', vehicle.marca),
                const SizedBox(height: 12),
                _buildDetailRow('Modelo:', vehicle.modelo),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Horómetro actual:',
                  '${vehicle.horometroActual.toStringAsFixed(1)} hrs',
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Kilometraje actual:',
                  '${vehicle.kilometrajeActual.toStringAsFixed(1)} km',
                ),

                const SizedBox(height: 32),

                // Confirmation Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      foregroundColor: Colors.black,
                      elevation: 4,
                      shadowColor: AppTheme.primaryYellow.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                      Icons.play_arrow_rounded,
                      size: 24,
                      color: Colors.black,
                    ),
                    label: Text(
                      'INICIAR INSPECCIÓN DIARIA',
                      style: GoogleFonts.oswald(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.black,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DailyFormScreen(
                            vehiculoId: vehicle.id,
                            templateTipoVehiculo: vehicle.tipo,
                            vehiculoPlaca: vehicle.placa,
                            vehiculoTipo: vehicle.tipo,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Change selection button
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedVehicle = null;
                    });
                  },
                  child: Text(
                    'Cambiar vehículo',
                    style: GoogleFonts.roboto(
                      color: AppTheme.textGray,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            color: AppTheme.textGray,
            fontSize: 13,
          ),
        ),
        Text(
          value.toUpperCase(),
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return '';
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  IconData _getIconForType(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'tractor':
      case 'tractor aereo':
      case 'tractor aéreo':
        return Icons.agriculture;
      case 'volqueta':
        return Icons.local_shipping;
      case 'camioneta':
        return Icons.directions_car;
      case 'moto':
        return Icons.two_wheeler;
      case 'maquinaria':
        return Icons.construction;
      case 'planta electrica':
      case 'planta eléctrica':
        return Icons.power;
      case 'guadaña':
        return Icons.grass;
      case 'motosierra':
        return Icons.handyman;
      default:
        return Icons.local_shipping_outlined;
    }
  }
}
