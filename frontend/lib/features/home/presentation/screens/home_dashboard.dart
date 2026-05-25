import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:frontend/features/workshop/presentation/screens/work_order_list_screen.dart';
import 'package:frontend/features/fleet/presentation/screens/vehicle_list_screen.dart';
import 'package:frontend/features/fleet/presentation/screens/add_fuel_screen.dart';
import 'package:frontend/features/inventory/presentation/screens/loan_list_screen.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/semanur_scaffold.dart';

import 'package:frontend/features/inventory/presentation/screens/scanner_screen.dart';
import 'package:frontend/features/home/presentation/widgets/sync_status_widget.dart';
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:frontend/features/notifications/presentation/screens/notification_list_screen.dart';
import 'package:frontend/features/auth/presentation/screens/employee_list_screen.dart';

// import 'package:frontend/core/widgets/sync_status_indicator.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:frontend/features/workshop/presentation/providers/workshop_provider.dart';
import 'package:frontend/features/fleet/presentation/providers/fleet_provider.dart';
import 'package:frontend/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:frontend/features/inventory/data/models/product_model.dart';
import 'package:frontend/core/providers/sync_provider.dart';
import 'package:frontend/core/utils/fuel_utils.dart';
import 'package:frontend/features/scheduler/presentation/screens/weekly_calendar_screen.dart';
import 'package:frontend/features/scheduler/presentation/screens/incident_report_screen.dart';
import 'package:frontend/features/preoperacionales/presentation/screens/vehicle_selection_screen.dart';

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
    if (connectivity.every((r) => r == ConnectivityResult.none)) {
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
      // Descargar datos clave - InventoryProvider se llama una sola vez aquí
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

    return SemanurScaffold(
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
      showCenterGap: true,
      floatingActionButton: GestureDetector(
        onTap: () => _showQuickReportModal(context),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryYellow,
            border: Border.all(color: const Color(0xFF0A0A0A), width: 6),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryYellow.withValues(alpha: 0.2),
                blurRadius: 15,
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.black, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
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
              Consumer<NotificationProvider>(
                builder: (context, provider, _) {
                  return Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationListScreen(),
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
                      if (provider.unreadCount > 0)
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
                  );
                },
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
              Consumer<InventoryProvider>(
                builder: (context, inventory, _) {
                  // Buscar productos de combustible por nombre.
                  final productos = inventory.productos;

                  final fuels = resolveFuelProducts(productos);
                  final gasolina = fuels.gasolina;
                  final acpm = fuels.acpm;

                  double calculateFuelPercent(Producto? p) {
                    if (p == null) return 0.0;
                    final stock = p.stockActual;
                    final max = p.capacidadMaxima ?? 0;
                    if (kDebugMode) {
                      print(
                        'FUEL_DEBUG: ${p.nombre} | stock=$stock | max=$max | alerta=${p.alertaStockMinimo}',
                      );
                    }
                    if (max > 0) {
                      return (stock / max).clamp(0.0, 1.0);
                    }
                    final min = p.alertaStockMinimo > 0 ? p.alertaStockMinimo : 1.0;
                    final denominator = min * 3 > stock ? min * 3 : (stock > 0 ? stock : 1.0);
                    if (kDebugMode) {
                      print(
                        'FUEL_DEBUG: ${p.nombre} usando fallback min=$min, denom=$denominator',
                      );
                    }
                    return (stock / denominator).clamp(0.0, 1.0);
                  }

                  final double pctGasolina = calculateFuelPercent(gasolina);
                  final double pctAcpm = calculateFuelPercent(acpm);

                  String formatValue(double value) =>
                      '${value.toStringAsFixed(1)} GAL';
                  String formatPct(double pct) =>
                      '${(pct * 100).clamp(0, 100).toStringAsFixed(0)}% Capacidad';

                  final bool gasolinaLow = gasolina != null &&
                      gasolina.stockActual <= gasolina.alertaStockMinimo;
                  final bool acpmLow = acpm != null &&
                      acpm.stockActual <= acpm.alertaStockMinimo;

                  return Row(
                    children: [
                      _buildSummaryCard(
                        title: 'GASOLINA',
                        subtitle: gasolina?.capacidadMaxima != null && gasolina!.capacidadMaxima! > 0
                            ? 'Capacidad ${gasolina.capacidadMaxima!.toStringAsFixed(0)} gal'
                            : 'Nivel de Tanque',
                        icon: Icons.local_gas_station_rounded,
                        value: gasolina == null && inventory.isLoading
                            ? '...'
                            : formatValue(gasolina?.stockActual ?? 0),
                        progress: pctGasolina,
                        warning: gasolina == null
                            ? 'Sin producto Gasolina'
                            : gasolinaLow
                                ? 'Stock bajo'
                                : formatPct(pctGasolina),
                        isDanger: gasolinaLow,
                      ),
                      const SizedBox(width: 15),
                      _buildSummaryCard(
                        title: 'ACPM / DIESEL',
                        subtitle: acpm?.capacidadMaxima != null && acpm!.capacidadMaxima! > 0
                            ? 'Capacidad ${acpm.capacidadMaxima!.toStringAsFixed(0)} gal'
                            : 'Nivel de Tanque',
                        icon: Icons.local_gas_station,
                        value: acpm == null && inventory.isLoading
                            ? '...'
                            : formatValue(acpm?.stockActual ?? 0),
                        progress: pctAcpm,
                        warning: acpm == null
                            ? 'Sin producto ACPM'
                            : acpmLow
                                ? 'Stock bajo'
                                : formatPct(pctAcpm),
                        isDanger: acpmLow,
                      ),
                    ],
                  );
                },
              ),
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
    bool isDanger = false,
  }) {
    final Color statusColor = isDanger || progress < 0.2 ? Colors.red : Colors.green;

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
            valueColor: AlwaysStoppedAnimation(statusColor),
            borderRadius: BorderRadius.circular(10),
            minHeight: 6,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                statusColor == Colors.green
                    ? Icons.check_circle_outline
                    : Icons.warning_rounded,
                color: statusColor,
                size: 14,
              ),
              const SizedBox(width: 5),
              Text(
                warning,
                style: TextStyle(
                  color: statusColor,
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

  Widget _buildModulesGrid(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.user;

    final modules = <_ModuleEntry>[];

    if (user == null || user.canAccessModule('taller')) {
      modules.add(_ModuleEntry(
        'Órdenes de Trabajo',
        Icons.construction_outlined,
        '3 Pendientes',
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkOrderListScreen())),
      ));
    }
    if (user == null || user.canAccessModule('inventario')) {
      modules.add(_ModuleEntry(
        'Inventario',
        Icons.inventory_2_outlined,
        '12 Items Bajos',
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen())),
      ));
    }
    if (user == null || user.canAccessModule('combustible')) {
      modules.add(_ModuleEntry(
        'Combustible',
        Icons.local_gas_station,
        'Registrar Tanqueo',
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFuelScreen())),
      ));
    }
    if (user == null || user.canAccessModule('flota')) {
      modules.add(_ModuleEntry(
        'Vehículos',
        Icons.local_shipping_outlined,
        '18 Activos',
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleListScreen())),
      ));
      modules.add(_ModuleEntry(
        'Inspecciones',
        Icons.assignment_turned_in,
        'Preoperacional diario',
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleSelectionScreen())),
      ));
    }
    if (user == null || user.canAccessModule('prestamos')) {
      modules.add(_ModuleEntry(
        'Préstamos',
        Icons.handyman_outlined,
        '5 En Uso',
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoanListScreen())),
      ));
    }
    if (user == null || user.canAccessModule('personal')) {
      modules.add(_ModuleEntry(
        'Empleados',
        Icons.people_alt_outlined,
        'Gestión de Personal',
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeListScreen())),
      ));
      modules.add(_ModuleEntry(
        'Programación',
        Icons.calendar_month_outlined,
        'Actividades & Novedades',
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeeklyCalendarScreen())),
      ));
    }

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
          children: modules.map((m) => _buildIndustrialButton(
            context,
            m.title,
            m.icon,
            m.subtitle,
            m.onTap,
          )).toList(),
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
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Watermark Icon
            Positioned(
              right: -15,
              bottom: -15,
              child: Opacity(
                opacity: 0.05,
                child: Icon(icon, size: 100, color: Colors.white),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryYellow.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: AppTheme.primaryYellow, size: 24),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.oswald(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
              'REPORTAR NOVEDAD',
              'Informar falla o incidente',
              Icons.warning_amber_rounded,
              Colors.red,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const IncidentReportScreen(),
                  ),
                );
              },
            ),
            _buildQuickActionItem(
              context,
              'ESCANEAR CODIGO',
              'Lectura rapida de codigo',
              Icons.qr_code_scanner,
              AppTheme.primaryYellow,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScannerScreen()),
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

}







class _ModuleEntry {
  final String title;
  final IconData icon;
  final String subtitle;
  final VoidCallback onTap;

  _ModuleEntry(this.title, this.icon, this.subtitle, this.onTap);
}
