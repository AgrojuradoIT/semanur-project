import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:frontend/features/workshop/presentation/screens/work_order_list_screen.dart';
import 'package:frontend/features/fleet/presentation/screens/vehicle_list_screen.dart';
import 'package:frontend/features/inventory/presentation/screens/loan_list_screen.dart';
import 'package:frontend/features/analytics/presentation/screens/analytics_dashboard_screen.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/fleet/presentation/screens/checklist_list_screen.dart';
import 'package:frontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:frontend/features/inventory/presentation/screens/scanner_screen.dart';
import 'package:frontend/features/home/presentation/widgets/sync_status_widget.dart';

// import 'package:frontend/core/widgets/sync_status_indicator.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:frontend/features/workshop/presentation/providers/workshop_provider.dart';
import 'package:frontend/features/fleet/presentation/providers/fleet_provider.dart';
import 'package:frontend/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:frontend/core/providers/sync_provider.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performInitialSync();
    });
  }

  Future<void> _performInitialSync() async {
    final syncProvider = context.read<SyncProvider>();
    if (syncProvider.isInitialSyncCompleted) return;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      syncProvider.setInitialSyncStatus(false, error: 'Sin conexión al inicio');
      return;
    }

    if (!mounted) return;

    await _fetchData(syncProvider);
  }

  Future<void> _fetchData(SyncProvider syncProvider) async {
    final fleetProvider = context.read<FleetProvider>();
    final inventoryProvider = context.read<InventoryProvider>();
    final workshopProvider = context.read<WorkshopProvider>();

    try {
      // Descargar datos clave
      await Future.wait([
        fleetProvider.fetchVehiculos(),
        inventoryProvider.fetchProductos(),
        workshopProvider.fetchOrdenes(),
      ]);

      if (mounted) {
        syncProvider.setInitialSyncStatus(true);
      }
    } catch (e) {
      if (mounted) {
        syncProvider.setInitialSyncStatus(false, error: e.toString());
      }
    }
  }

  Future<void> _onRefresh() async {
    final syncProvider = context.read<SyncProvider>();
    // Reset status to show syncing state if desired, or just fetch
    await _fetchData(syncProvider);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // Fondo con efecto blur (simulado con opacidad bajas)
          _buildBackgroundDecor(),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, authProvider),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: AppTheme.primaryYellow,
                    backgroundColor: AppTheme.surfaceDark,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildDailySummary(context),
                        const SizedBox(height: 30),
                        _buildModulesGrid(context),
                        const SizedBox(height: 30),
                        _buildQuickReport(context),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScannerScreen()),
          );
        },
        backgroundColor: AppTheme.primaryYellow,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner, color: Colors.black, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBackgroundDecor() {
    return Positioned(
      top: -100,
      right: -100,
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          color: AppTheme.primaryYellow.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryYellow.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/logo.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.oswald(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                      children: const [
                        TextSpan(text: 'SEMANUR '),
                        TextSpan(
                          text: 'HUB',
                          style: TextStyle(color: AppTheme.primaryYellow),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'GESTIÓN DE FLOTA',
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textGray,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              // const SyncStatusIndicator(), // Moved to Daily Summary
              const SizedBox(width: 8),
              Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sin notificaciones nuevas'),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppTheme.textGray,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.surfaceDark,
                      shape: const CircleBorder(),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.surfaceDark,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailySummary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RESUMEN DIARIO',
              style: GoogleFonts.oswald(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SyncStatusWidget(),
          ],
        ),
        const SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSummaryCard(
                title: 'NIVEL COMBUSTIBLE',
                subtitle: 'Promedio Flota',
                icon: Icons.local_gas_station_rounded,
                value: '78%',
                progress: 0.78,
                warning: '2 Vehículos Bajos',
              ),
              const SizedBox(width: 15),
              _buildActivityCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required double progress,
    required String warning,
  }) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.surfaceDark2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.primaryYellow, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.oswald(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.surfaceDark2,
            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryYellow),
            borderRadius: BorderRadius.circular(10),
            minHeight: 6,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.red, size: 14),
              const SizedBox(width: 5),
              Text(
                warning,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.surfaceDark2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'ACTIVIDADES HOY',
                style: GoogleFonts.oswald(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildMiniActivity('Mant. Preventivo', '08:30 AM', Colors.green),
          const SizedBox(height: 8),
          _buildMiniActivity(
            'Inspección #402',
            '10:15 AM',
            AppTheme.primaryYellow,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniActivity(String text, String time, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          Text(
            time,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildModulesGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MÓDULOS OPERATIVOS',
          style: GoogleFonts.oswald(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 15),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.1,
          children: [
            _buildIndustrialButton(
              context,
              'Órdenes de Trabajo',
              Icons.construction_outlined,
              '3 Pendientes',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WorkOrderListScreen()),
              ),
            ),
            _buildIndustrialButton(
              context,
              'Inventario',
              Icons.inventory_2_outlined,
              '12 Items Bajos',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InventoryScreen()),
              ),
            ),
            _buildIndustrialButton(
              context,
              'Vehículos',
              Icons.local_shipping_outlined,
              '18 Activos',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VehicleListScreen()),
              ),
            ),
            _buildIndustrialButton(
              context,
              'Préstamos',
              Icons.handyman_outlined,
              '5 En Uso',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoanListScreen()),
              ),
            ),
            _buildIndustrialButton(
              context,
              'Analítica',
              Icons.analytics_outlined,
              'Reportes y Costos',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AnalyticsDashboardScreen(),
                ),
              ),
            ),
            _buildIndustrialButton(
              context,
              'Checklists',
              Icons.playlist_add_check,
              'Historial & Alertas',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChecklistListScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIndustrialButton(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(15),
          border: const Border(
            bottom: BorderSide(color: Colors.transparent, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.oswald(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: AppTheme.textGray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReport(BuildContext context) {
    return GestureDetector(
      onTap: () => _showQuickReportModal(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryYellow,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryYellow.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REPORTE RÁPIDO',
                  style: GoogleFonts.oswald(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Text(
                  'Registrar incidente o combustible',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add, color: AppTheme.primaryYellow),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickReportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark2,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'SELECCIONA UNA ACCIÓN RÁPIDA',
              style: GoogleFonts.oswald(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 25),
            _buildQuickActionItem(
              context,
              'REGISTRAR PREOPERACIONAL',
              'Realizar inspección de vehículo',
              Icons.playlist_add_check_circle,
              Colors.blue,
              () {
                Navigator.pop(context);
                // Por defecto enviamos a la lista, si el usuario requiere ir directo a crear podemos cambiarlo
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VehicleListScreen(),
                  ), // Mejor ir a lista para seleccionar vehiculo
                );
              },
            ),
            _buildQuickActionItem(
              context,
              'REGISTRAR COMBUSTIBLE',
              'Ingresar nuevo tanqueo',
              Icons.local_gas_station,
              AppTheme.primaryYellow,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VehicleListScreen(),
                  ), // Flujo: Seleccionar vehiculo -> Tanquear
                );
              },
            ),
            _buildQuickActionItem(
              context,
              'REPORTAR NOVEDAD',
              'Informar falla o incidente',
              Icons.warning_amber_rounded,
              Colors.red,
              () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Módulo de reporte de novedades próximamente',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundDark,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppTheme.surfaceDark2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.oswald(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
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

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: AppTheme.surfaceDark2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(Icons.dashboard_rounded, 'Inicio', true),
          _buildNavItem(Icons.search_outlined, 'Buscar', false),
          const SizedBox(
            width: 40,
          ), // Espacio para el FAB central si se implementa
          _buildNavItem(Icons.history_outlined, 'Historial', false),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: _buildNavItem(Icons.person_outlined, 'Perfil', false),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? AppTheme.primaryYellow : AppTheme.textGray,
          size: 26,
        ),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppTheme.textGray,
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
