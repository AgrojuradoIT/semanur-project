import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/semanur_scaffold.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart';

// Import Screens (to navigate if needed)
import 'package:frontend/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:frontend/features/workshop/presentation/screens/work_order_list_screen.dart';
import 'package:frontend/features/fleet/presentation/screens/vehicle_list_screen.dart';
import 'package:frontend/features/inventory/presentation/screens/loan_list_screen.dart';
import 'package:frontend/features/auth/presentation/screens/employee_list_screen.dart';
import 'package:frontend/features/scheduler/presentation/screens/weekly_calendar_screen.dart';

class HomeWebDashboard extends StatefulWidget {
  const HomeWebDashboard({super.key});

  @override
  State<HomeWebDashboard> createState() => _HomeWebDashboardState();
}

class _HomeWebDashboardState extends State<HomeWebDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return SemanurScaffold(
      body: Row(
        children: [
          // SIDEBAR (Fijo a la izquierda)
          _buildSidebar(context),

          // CONTENIDO PRINCIPAL
          Expanded(
            child: Container(
              color: AppTheme.backgroundDark,
              child: Column(
                children: [
                  _buildHeader(context, authProvider),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1400),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48.0,
                              vertical: 40.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildWelcomeBanner(authProvider),
                                const SizedBox(height: 48),
                                _buildWebMetricsRow(context),
                                const SizedBox(height: 48),
                                _buildModulesGridWeb(context),
                                const SizedBox(height: 48),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 280,
      color: AppTheme.surfaceDark,
      child: Column(
        children: [
          const SizedBox(height: 30),
          // Logo e Identidad Visual
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/logo.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.oswald(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                  children: const [
                    TextSpan(text: 'SEMANUR\n'),
                    TextSpan(
                      text: 'WEB PORTAL',
                      style: TextStyle(
                        color: AppTheme.primaryYellow,
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Divider(color: AppTheme.surfaceDark2, thickness: 2),

          // NavegaciÃ³n
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              children: [
                _buildSidebarItem(
                  context,
                  0,
                  Icons.dashboard_rounded,
                  'Dashboard',
                  () {},
                ),
                _buildSidebarItem(
                  context,
                  1,
                  Icons.construction,
                  'Ã“rdenes de Trabajo',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WorkOrderListScreen(),
                      ),
                    );
                  },
                ),
                _buildSidebarItem(
                  context,
                  2,
                  Icons.inventory_2,
                  'Inventario',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InventoryScreen(),
                      ),
                    );
                  },
                ),
                _buildSidebarItem(
                  context,
                  3,
                  Icons.local_shipping,
                  'Flota',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VehicleListScreen(),
                      ),
                    );
                  },
                ),
                _buildSidebarItem(
                  context,
                  4,
                  Icons.handyman,
                  'PrÃ©stamos Herr.',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoanListScreen()),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 8),
                  child: Text(
                    'ADMINISTRACIÃ“N',
                    style: TextStyle(
                      color: AppTheme.textGray,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                _buildSidebarItem(context, 6, Icons.people, 'Empleados', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EmployeeListScreen(),
                    ),
                  );
                }),
                _buildSidebarItem(
                  context,
                  7,
                  Icons.calendar_month,
                  'ProgramaciÃ³n',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WeeklyCalendarScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Bottom Settings / Logout
          Container(
            padding: const EdgeInsets.all(20),
            child: _buildSidebarItem(
              context,
              99,
              Icons.logout,
              'Cerrar SesiÃ³n',
              () {
                context.read<AuthProvider>().logout();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    int index,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    bool isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryYellow.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppTheme.primaryYellow : AppTheme.textGray,
          size: 22,
        ),
        title: Text(
          title,
          style: GoogleFonts.roboto(
            color: isSelected ? Colors.white : AppTheme.textGray,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: () {
          if (index != 99) {
            // 99 es para logout/acciones directas
            setState(() {
              _selectedIndex = index;
            });
          }
          onTap();
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          bottom: BorderSide(color: AppTheme.surfaceDark2, width: 1),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: [
          Text(
            'Panel General / Resumen',
            style: GoogleFonts.oswald(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.surfaceDark2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Sincronizado',
                      style: TextStyle(fontSize: 12, color: AppTheme.textGray),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Consumer<NotificationProvider>(
                builder: (context, provider, _) {
                  return Stack(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_none),
                      ),
                      if (provider.unreadCount > 0)
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 20),
              CircleAvatar(
                backgroundColor: AppTheme.primaryYellow.withValues(alpha: 0.2),
                child: const Icon(Icons.person, color: AppTheme.primaryYellow),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth.user?.name ?? 'Usuario',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    auth.user?.role ?? 'Administrador',
                    style: const TextStyle(
                      color: AppTheme.textGray,
                      fontSize: 11,
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

  Widget _buildWelcomeBanner(AuthProvider auth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.primaryYellow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryYellow.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Â¡Bienvenido de nuevo, ${auth.user?.name.split(" ").first ?? "Administrador"}!',
                style: GoogleFonts.oswald(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'AquÃ­ tienes un resumen de la operaciÃ³n de Semanur para hoy.',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: AppTheme.primaryYellow),
                SizedBox(width: 8),
                Text(
                  'NUEVA ORDEN',
                  style: TextStyle(
                    color: AppTheme.primaryYellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebMetricsRow(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, inventory, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return Column(
                children: [
                  _buildMetricCard(
                    'Ã“rdenes Activas',
                    '12',
                    Icons.build_circle,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildMetricCard(
                    'Nivel Gasolina',
                    '65%',
                    Icons.local_gas_station,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildMetricCard(
                    'Nivel ACPM',
                    '28%',
                    Icons.oil_barrel,
                    Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildMetricCard(
                    'Alertas Stock',
                    '5',
                    Icons.warning_amber,
                    Colors.red,
                  ),
                ],
              );
            } else if (constraints.maxWidth < 900) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Ã“rdenes Activas',
                          '12',
                          Icons.build_circle,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildMetricCard(
                          'Nivel Gasolina',
                          '65%',
                          Icons.local_gas_station,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Nivel ACPM',
                          '28%',
                          Icons.oil_barrel,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildMetricCard(
                          'Alertas Stock',
                          '5',
                          Icons.warning_amber,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Ã“rdenes Activas',
                    '12',
                    Icons.build_circle,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildMetricCard(
                    'Nivel Gasolina',
                    '65%',
                    Icons.local_gas_station,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildMetricCard(
                    'Nivel ACPM',
                    '28%',
                    Icons.oil_barrel,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildMetricCard(
                    'Alertas Stock',
                    '5',
                    Icons.warning_amber,
                    Colors.red,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceDark2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textGray,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.oswald(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModulesGridWeb(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACCESO RÃPIDO A MÃ“DULOS',
          style: GoogleFonts.oswald(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            int columns = 3;
            if (constraints.maxWidth < 600) {
              columns = 1;
            } else if (constraints.maxWidth < 1000) {
              columns = 2;
            }

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: constraints.maxWidth < 600 ? 3.0 : 2.5,
              children: [
                _HoverableQuickAccessCard(
                  context: context,
                  title: 'Taller & Ã“rdenes',
                  icon: Icons.construction,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WorkOrderListScreen(),
                      ),
                    );
                  },
                ),
                _HoverableQuickAccessCard(
                  context: context,
                  title: 'Inventario',
                  icon: Icons.inventory_2,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InventoryScreen(),
                      ),
                    );
                  },
                ),
                _HoverableQuickAccessCard(
                  context: context,
                  title: 'Flota (VehÃ­culos)',
                  icon: Icons.local_shipping,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VehicleListScreen(),
                      ),
                    );
                  },
                ),
                _HoverableQuickAccessCard(
                  context: context,
                  title: 'PrÃ©stamo de \nHerramientas',
                  icon: Icons.handyman,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoanListScreen()),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HoverableQuickAccessCard extends StatefulWidget {
  final BuildContext context;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _HoverableQuickAccessCard({
    required this.context,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_HoverableQuickAccessCard> createState() =>
      _HoverableQuickAccessCardState();
}

class _HoverableQuickAccessCardState extends State<_HoverableQuickAccessCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          transform: Matrix4.identity()..scaleByDouble(_isHovering ? 1.02 : 1.0, _isHovering ? 1.02 : 1.0, 1.0, 1.0),
          decoration: BoxDecoration(
            color: _isHovering
                ? AppTheme.surfaceDark2
                : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovering
                  ? AppTheme.primaryYellow.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.05),
            ),
            boxShadow: [
              if (_isHovering)
                BoxShadow(
                  color: AppTheme.primaryYellow.withValues(alpha: 0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(_isHovering ? 12 : 8),
                decoration: BoxDecoration(
                  color: _isHovering
                      ? AppTheme.primaryYellow.withValues(alpha: 0.1)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: AppTheme.primaryYellow,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.title,
                  style: GoogleFonts.oswald(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: _isHovering ? AppTheme.primaryYellow : AppTheme.textGray,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


