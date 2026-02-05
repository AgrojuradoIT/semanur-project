import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/features/workshop/data/models/work_order_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:frontend/features/workshop/presentation/providers/workshop_provider.dart';
import 'package:frontend/features/workshop/presentation/screens/work_order_detail_screen.dart';
import 'package:frontend/features/workshop/presentation/screens/add_work_order_screen.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class WorkOrderListScreen extends StatefulWidget {
  const WorkOrderListScreen({super.key});

  @override
  State<WorkOrderListScreen> createState() => _WorkOrderListScreenState();
}

class _WorkOrderListScreenState extends State<WorkOrderListScreen> {
  String _selectedFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkshopProvider>().fetchOrdenes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final workshopProvider = context.watch<WorkshopProvider>();

    final ordenesFiltradas = workshopProvider.ordenes.where((o) {
      if (_selectedFilter == 'Todos') {
        return true;
      }
      if (_selectedFilter == 'Pendientes') {
        return o.estado.toLowerCase() == 'abierta' ||
            o.estado.toLowerCase() == 'pendiente';
      }
      if (_selectedFilter == 'En Progreso') {
        return o.estado.toLowerCase() == 'en progreso';
      }
      if (_selectedFilter == 'Completados') {
        return o.estado.toLowerCase() == 'cerrada' ||
            o.estado.toLowerCase() == 'completada';
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // Fondo decorativo
          Positioned(
            top: -100,
            right: -100,
            child: Icon(
              Icons.settings,
              size: 300,
              color: Colors.white.withValues(alpha: 0.03),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, workshopProvider),
                Expanded(child: _buildBody(workshopProvider, ordenesFiltradas)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildHeader(BuildContext context, WorkshopProvider provider) {
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
                        'ÓRDENES DE TRABAJO',
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
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuAsi1x-O2AuhuvC7OzTjNUEtbKlKtzgQhTU8QMPvZyiEUsoZ3UaAU-H8zkcQ0nsrDIHf-RXn4eBbuADVkVjnuCoTd9xFojNNSX__ylWfDFCrtjwINbm-eI-0Y4hn5f4BtCmlRmdGJQotU3ma6W-0ZD8gmYa6g3v_IOROUXoVF-8zOVJzx4HRTlTUxCcWc2o37RptKko0tX3Zlx6QgHodaWyQSltYKSgVNloRv-xpqBXHUlmARnv-okoIg06TlmwJuoHHnPybQnsx9E',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Buscador
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (value) => provider.searchOrdenes(value),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Buscar vehículo u orden...',
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
                        borderSide: const BorderSide(
                          color: AppTheme.primaryYellow,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.tune, color: AppTheme.primaryYellow),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Todos', _selectedFilter == 'Todos'),
                _buildFilterChip('Pendientes', _selectedFilter == 'Pendientes'),
                _buildFilterChip(
                  'En Progreso',
                  _selectedFilter == 'En Progreso',
                ),
                _buildFilterChip(
                  'Completados',
                  _selectedFilter == 'Completados',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryYellow : AppTheme.surfaceDark2,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: AppTheme.surfaceDark2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddWorkOrderScreen()),
        );
      },
      backgroundColor: AppTheme.primaryYellow,
      foregroundColor: Colors.black,
      icon: const Icon(Icons.add),
      label: Text(
        'NUEVA ORDEN',
        style: GoogleFonts.oswald(fontWeight: FontWeight.bold),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildBody(WorkshopProvider provider, List<OrdenTrabajo> ordenes) {
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
                onPressed: () => provider.fetchOrdenes(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.ordenes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay órdenes asignadas',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => provider.fetchOrdenes(),
              child: const Text('Refrescar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchOrdenes(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ordenes.length,
        itemBuilder: (context, index) {
          final orden = ordenes[index];
          final colorPrioridad = _getPrioridadColor(orden.prioridad);
          final String initial =
              orden.vehiculo?.marca != null && orden.vehiculo!.marca.isNotEmpty
              ? orden.vehiculo!.marca.substring(0, 1).toUpperCase()
              : 'V';

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkOrderDetailScreen(orden: orden),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceDark2),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Indicador lateral de prioridad
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 5,
                    child: Container(color: colorPrioridad),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorPrioridad.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    orden.prioridad.toUpperCase(),
                                    style: TextStyle(
                                      color: colorPrioridad,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '#OT-${orden.id}',
                                  style: const TextStyle(
                                    color: AppTheme.textGray,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getEstadoColor(
                                  orden.estado,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  if (orden.estado.toLowerCase() ==
                                      'en progreso')
                                    Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primaryYellow,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  Text(
                                    orden.estado,
                                    style: TextStyle(
                                      color: _getEstadoColor(orden.estado),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${orden.vehiculo?.marca ?? 'Vehículo'} ${orden.vehiculo?.modelo ?? ''}',
                          style: GoogleFonts.oswald(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'PLACA: ${orden.vehiculo?.placa ?? 'N/A'}',
                          style: const TextStyle(
                            color: AppTheme.textGray,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Divider(color: AppTheme.surfaceDark2, height: 1),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.surfaceDark2,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      initial,
                                      style: GoogleFonts.oswald(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      orden.mecanicoAsignadoId != null
                                          ? 'Mecánico #${orden.mecanicoAsignadoId}'
                                          : 'Sin asignar',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Mecánico Jefe', // Placeholder as per design
                                      style: TextStyle(
                                        color: AppTheme.textGray,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'ENTREGA ESTIMADA',
                                  style: TextStyle(
                                    color: AppTheme.textGray,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  DateFormat('HH:mm a').format(
                                    orden.fechaInicio.add(
                                      const Duration(hours: 4),
                                    ),
                                  ), // Simulando entrega
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
        },
      ),
    );
  }

  Color _getPrioridadColor(String prioridad) {
    switch (prioridad.toLowerCase()) {
      case 'alta':
        return Colors.red;
      case 'media':
        return Colors.orange;
      case 'baja':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'abierta':
        return Colors.blue;
      case 'en progreso':
        return Colors.orange;
      case 'cerrada':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
