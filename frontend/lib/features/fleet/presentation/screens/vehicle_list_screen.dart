import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/features/fleet/presentation/providers/fleet_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/fleet/presentation/screens/vehicle_category_list_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // Fondo decorativo
          Positioned(
            top: -100,
            right: -100,
            child: Icon(
              Icons.engineering,
              size: 300,
              color: AppTheme.primaryYellow.withValues(alpha: 0.03),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(child: _buildBody(fleetProvider)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      color: AppTheme.surfaceDark,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FLOTA DE VEHÍCULOS',
                        style: GoogleFonts.oswald(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'SEMANUR ZOMAC S.A.S.',
                        style: GoogleFonts.roboto(
                          fontSize: 10,
                          color: AppTheme.textGray,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryYellow, width: 2),
                  image: const DecorationImage(
                    image: CachedNetworkImageProvider(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuA7ZGiX11ZluyucCbCQSmImd7kM5havTRh4F_k1p-qFbTlt5x2Ts_9Q83vpoOnSncqkszslaVyjPpp3V5TdD5I1BYLtru7U1h0LMTrFnPQwRU7sNcKRgAt74Ix_HteaBqZnRqvMputW76aNsr60ZJlZP0M9rsTbiFrL_RUh3bsGhSIPLT_6QwAhZuFZohGPRYJe_u9lt9-YZwlEN_AGeAVt9sbbdrrlW1SIeOThtywAq6FxLO0A-B0L0xE6u2ESzrsi4F1sjAav7Ms',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Buscador
          Container(
            height: 45,
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: (value) =>
                  context.read<FleetProvider>().searchVehiculos(value),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar placa, tipo o estado...',
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
        ],
      ),
    );
  }

  Widget _buildBody(FleetProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => provider.fetchVehiculos(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    // Calcular estadísticas
    final int totalActivos = provider.vehiculos.length;
    final int enAlerta = provider.alertsCount;

    return RefreshIndicator(
      onRefresh: () => provider.fetchVehiculos(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Resumen Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Activos',
                  totalActivos.toString(),
                  '+3 este mes',
                  Icons.inventory_2,
                  AppTheme.primaryYellow,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildSummaryCard(
                  'Alertas Hoy',
                  enAlerta.toString(),
                  enAlerta > 0 ? 'Requieren acción' : 'Todo operativo',
                  Icons.warning_amber_rounded,
                  enAlerta > 0 ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CATEGORÍAS',
                style: GoogleFonts.oswald(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const Text(
                'Ver todo',
                style: TextStyle(
                  color: AppTheme.primaryYellow,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Cuadrícula de Categorías
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.0,
            children: [
              _buildCategoryCard(
                'Tractores',
                provider.vehiculos
                    .where((v) => v.tipo.toLowerCase() == 'tractor')
                    .length,
                Icons.agriculture,
                () => _navigateToCategory(context, 'Tractores', 'tractor'),
              ),
              _buildCategoryCard(
                'Volquetas',
                provider.vehiculos
                    .where((v) => v.tipo.toLowerCase() == 'volqueta')
                    .length,
                Icons.local_shipping,
                () => _navigateToCategory(context, 'Volquetas', 'volqueta'),
              ),
              _buildCategoryCard(
                'Camionetas',
                provider.vehiculos
                    .where((v) => v.tipo.toLowerCase() == 'camioneta')
                    .length,
                Icons.directions_car,
                () => _navigateToCategory(context, 'Camionetas', 'camioneta'),
              ),
              _buildCategoryCard(
                'Motos',
                provider.vehiculos
                    .where((v) => v.tipo.toLowerCase() == 'moto')
                    .length,
                Icons.two_wheeler,
                () => _navigateToCategory(context, 'Motos', 'moto'),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildWideCategoryCard(
            'Maquinaria Amarilla',
            provider.vehiculos
                .where((v) => v.tipo.toLowerCase() == 'maquinaria')
                .length,
            'Excavadoras, Retroexcavadoras...',
            Icons.construction,
            () => _navigateToCategory(
              context,
              'Maquinaria Amarilla',
              'maquinaria',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    String trend,
    IconData icon,
    Color color,
  ) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceDark2),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textGray,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.oswald(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      if (trend.contains('+'))
                        const Icon(
                          Icons.trending_up,
                          color: Colors.green,
                          size: 12,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        trend,
                        style: TextStyle(
                          color: trend.contains('+')
                              ? Colors.green
                              : AppTheme.textGray,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    String title,
    int count,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceDark2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surfaceDark, Colors.black.withValues(alpha: 0.3)],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundDark,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: AppTheme.primaryYellow, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.oswald(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$count Unidades',
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideCategoryCard(
    String title,
    int count,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceDark2),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppTheme.surfaceDark, Colors.black.withValues(alpha: 0.3)],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundDark,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppTheme.primaryYellow, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.oswald(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppTheme.textGray,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      count.toString(),
                      style: GoogleFonts.oswald(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Unidades',
                      style: TextStyle(color: AppTheme.textGray, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Funcionalidad de agregar vehículos próximamente'),
          ),
        );
      },
      backgroundColor: AppTheme.primaryYellow,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.add, size: 30),
    );
  }

  void _navigateToCategory(BuildContext context, String category, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            VehicleCategoryListScreen(category: category, filterType: type),
      ),
    );
  }
}
