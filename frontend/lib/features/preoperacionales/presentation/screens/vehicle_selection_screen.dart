import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/semanur_scaffold.dart';
import 'package:frontend/core/utils/debounce_util.dart';
import 'package:frontend/features/fleet/data/models/vehicle_model.dart';
import 'package:frontend/features/fleet/presentation/providers/fleet_provider.dart';
import 'package:frontend/features/preoperacionales/presentation/screens/daily_form_screen.dart';

class VehicleSelectionScreen extends StatefulWidget {
  const VehicleSelectionScreen({super.key});

  @override
  State<VehicleSelectionScreen> createState() =>
      _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  final _debouncer = Debouncer(milliseconds: 400);
  String _searchQuery = '';
  String? _filterType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FleetProvider>().fetchVehiculos();
    });
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  List<Vehiculo> get _filteredVehicles {
    final provider = context.read<FleetProvider>();
    var vehicles = provider.vehiculos;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      vehicles = vehicles.where((v) {
        return v.placa.toLowerCase().contains(query) ||
            v.tipo.toLowerCase().contains(query) ||
            v.marca.toLowerCase().contains(query) ||
            v.modelo.toLowerCase().contains(query);
      }).toList();
    }

    if (_filterType != null && _filterType != 'todos') {
      vehicles =
          vehicles.where((v) => v.tipo.toLowerCase() == _filterType!.toLowerCase()).toList();
    }

    return vehicles;
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
      body: Column(
        children: [
          // Search + Filter bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surfaceDark,
            child: Column(
              children: [
                // Search bar
                Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      _debouncer.run(() {
                        setState(() {
                          _searchQuery = value;
                        });
                      });
                    },
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Buscar placa, tipo, marca...',
                      hintStyle: const TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.textGray,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryYellow),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter dropdown
                _buildTypeFilter(fleetProvider),
              ],
            ),
          ),

          // Vehicle list
          Expanded(
            child: fleetProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVehicles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: AppTheme.textGray,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No se encontraron vehículos',
                              style: GoogleFonts.roboto(
                                color: AppTheme.textGray,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredVehicles.length,
                        itemBuilder: (context, index) {
                          final vehicle = _filteredVehicles[index];
                          return _buildVehicleCard(vehicle);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter(FleetProvider provider) {
    final uniqueTypes = provider.vehiculos
        .map((v) => v.tipo.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
    uniqueTypes.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceDark2, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Row(
            children: [
              const Icon(
                Icons.filter_list_rounded,
                color: AppTheme.primaryYellow,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Filtrar por tipo...',
                style: GoogleFonts.roboto(
                  color: AppTheme.textGray,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppTheme.primaryYellow,
            size: 20,
          ),
          dropdownColor: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(color: Colors.white),
          value: _filterType ?? 'todos',
          items: [
            const DropdownMenuItem<String>(
              value: 'todos',
              child: Text('Todos los tipos'),
            ),
            ...uniqueTypes.map((type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(_capitalize(type)),
              );
            }),
          ],
          onChanged: (val) {
            setState(() {
              _filterType = val == 'todos' ? null : val;
            });
          },
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return '';
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  Widget _buildVehicleCard(Vehiculo vehicle) {
    final icon = _getIconForType(vehicle.tipo);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceDark2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
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
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryYellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppTheme.primaryYellow, size: 24),
                ),
                const SizedBox(width: 14),
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
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_capitalize(vehicle.tipo)} — ${vehicle.marca} ${vehicle.modelo}',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: AppTheme.textGray,
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
        ),
      ),
    );
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
