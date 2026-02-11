import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/features/fleet/presentation/screens/checklist_form_screen.dart';
import 'package:frontend/features/fleet/presentation/screens/checklist_detail_screen.dart';
import 'package:frontend/features/fleet/presentation/providers/fleet_provider.dart';
import 'package:frontend/features/fleet/presentation/providers/checklist_provider.dart';
import 'package:frontend/features/fleet/data/models/checklist_model.dart';

class ChecklistDashboardScreen extends StatefulWidget {
  const ChecklistDashboardScreen({super.key});

  @override
  State<ChecklistDashboardScreen> createState() =>
      _ChecklistDashboardScreenState();
}

class _ChecklistDashboardScreenState extends State<ChecklistDashboardScreen>
    with SingleTickerProviderStateMixin {
  // Theme Colors
  static const Color primaryColor = Color(0xFFF2DF0D);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFFBAB79C);

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChecklistProvider>().fetchChecklists();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showVehicleSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardDark,
        title: Text(
          'Seleccionar Vehículo',
          style: GoogleFonts.oswald(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar placa...',
                  hintStyle: const TextStyle(color: textSecondary),
                  prefixIcon: const Icon(Icons.search, color: textSecondary),
                  filled: true,
                  fillColor: backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (val) =>
                    context.read<FleetProvider>().searchVehiculos(val),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Consumer<FleetProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ListView.builder(
                      itemCount: provider.vehiculos.length,
                      itemBuilder: (context, index) {
                        final vehicle = provider.vehiculos[index];
                        return ListTile(
                          leading: Icon(
                            Icons.directions_car,
                            color: primaryColor,
                          ),
                          title: Text(
                            vehicle.placa,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${vehicle.marca} ${vehicle.modelo}',
                            style: const TextStyle(color: textSecondary),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ChecklistFormScreen(vehiculo: vehicle),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDark,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildSliverAppBar(),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildChecklistList('all'),
              _buildChecklistList('pending'),
              _buildChecklistList('completed'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVehicleSelectionDialog(context),
        backgroundColor: primaryColor,
        foregroundColor: backgroundDark,
        label: const Text(
          'NUEVO CHECKLIST',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add_circle),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: backgroundDark,
      floating: true,
      pinned: true,
      expandedHeight: 200,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Column(
          children: [
            const SizedBox(height: 50), // Spacer for leading
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Checklists Pre-operacionales',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar por placa (ej. XYZ-123)',
                  hintStyle: const TextStyle(color: textSecondary),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2C),
                  prefixIcon: const Icon(Icons.search, color: textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Container(
          height: 50,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorSize: TabBarIndicatorSize.label,
            indicator: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(50),
            ),
            labelColor: backgroundDark,
            unselectedLabelColor: Colors.white,
            dividerColor: Colors.transparent,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Todos'),
              Tab(text: 'Pendientes'),
              Tab(text: 'Completados'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistList(String filter) {
    return Consumer<ChecklistProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error: ${provider.error}',
                  style: const TextStyle(color: textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchChecklists(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        // Filtrar checklists según el filtro
        List<ChecklistPreoperacional> filteredChecklists = provider.checklists;

        if (filter == 'pending') {
          filteredChecklists = provider.checklists
              .where((c) => c.estado.toLowerCase() != 'aprobado')
              .toList();
        } else if (filter == 'completed') {
          filteredChecklists = provider.checklists
              .where((c) => c.estado.toLowerCase() == 'aprobado')
              .toList();
        }

        if (filteredChecklists.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => provider.fetchChecklists(),
            child: ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_turned_in_outlined,
                        color: primaryColor.withValues(alpha: 0.5),
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay checklists para mostrar',
                        style: TextStyle(color: textSecondary, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchChecklists(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: filteredChecklists.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final checklist = filteredChecklists[index];
              return _buildChecklistCard(checklist);
            },
          ),
        );
      },
    );
  }

  Widget _buildChecklistCard(ChecklistPreoperacional checklist) {
    Color statusColor;
    Color iconBgColor;
    IconData iconData;
    String statusText = checklist.estado;

    // Mapear estado a colores
    if (checklist.estado.toLowerCase() == 'aprobado') {
      statusColor = Colors.green;
      iconBgColor = Colors.green.withValues(alpha: 0.2);
      iconData = Icons.check_circle;
    } else if (checklist.estado.toLowerCase() == 'rechazado') {
      statusColor = Colors.red;
      iconBgColor = Colors.red.withValues(alpha: 0.2);
      iconData = Icons.error;
    } else {
      statusColor = Colors.amber;
      iconBgColor = Colors.amber.withValues(alpha: 0.2);
      iconData = Icons.description;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(iconData, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checklist.vehiculoPlaca ?? 'N/A',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          checklist.fecha.toString().substring(0, 16),
                          style: const TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_vert, color: primaryColor),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: statusColor,
                    child: Text(
                      (checklist.usuarioNombre ?? 'U')[0],
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    checklist.usuarioNombre ?? 'Usuario desconocido',
                    style: const TextStyle(color: textSecondary, fontSize: 12),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChecklistDetailScreen(checklist: checklist),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'Ver detalle',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward,
                      color: primaryColor,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
