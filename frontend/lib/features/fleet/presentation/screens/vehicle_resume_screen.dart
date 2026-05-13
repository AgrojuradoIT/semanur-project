import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/semanur_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/fleet/presentation/providers/fleet_provider.dart';
import 'package:frontend/features/auth/presentation/providers/employee_provider.dart';
import 'package:frontend/features/auth/data/models/empleado_model.dart';
import 'package:frontend/features/fleet/data/models/vehicle_model.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'fuel_history_screen.dart';
import 'hour_meter_history_screen.dart';
import 'checklist_form_screen.dart';

class VehicleResumeScreen extends StatefulWidget {
  final int vehiculoId;
  final String placa;

  const VehicleResumeScreen({
    super.key,
    required this.vehiculoId,
    required this.placa,
  });

  @override
  State<VehicleResumeScreen> createState() => _VehicleResumeScreenState();
}

class _VehicleResumeScreenState extends State<VehicleResumeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Vehiculo? _vehiculo;
  bool _isLoading = true;
  bool _isMachinery = false;

  @override
  void initState() {
    super.initState();
    // Inicializar con un valor por defecto para evitar LateInitializationError
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      context.read<EmployeeProvider>().loadEmployees();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final vehiculo = await context.read<FleetProvider>().fetchVehiculoDetalle(
      widget.vehiculoId,
    );
    if (mounted) {
      setState(() {
        _vehiculo = vehiculo;
        _isMachinery = _checkIfMachinery(vehiculo?.tipo);

        // Re-inicializar solo si el largo cambia
        final newLength = _isMachinery ? 5 : 4;
        if (_tabController.length != newLength) {
          final oldController = _tabController;
          _tabController = TabController(length: newLength, vsync: this);
          // Diferir la eliminación para evitar errores en el frame actual
          WidgetsBinding.instance.addPostFrameCallback((_) {
            oldController.dispose();
          });
        }

        _isLoading = false;
      });
    }
  }

  bool _checkIfMachinery(String? tipo) {
    if (tipo == null) return false;
    final t = tipo.toLowerCase();
    return t.contains('tractor') ||
        t.contains('maquinaria') ||
        t.contains('pesada');
  }

  @override
  Widget build(BuildContext context) {
    return SemanurScaffold(
      appBar: AppBar(
        title: Text('HV: ${widget.placa}'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.edit_calendar,
              color: AppTheme.primaryYellow,
            ),
            onPressed: () => _showEditDialog(),
          ),
          IconButton(
            icon: const Icon(
              Icons.assignment_turned_in,
              color: Colors.greenAccent,
            ),
            tooltip: 'Realizar Pre-operacional',
            onPressed: () {
              if (_vehiculo == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChecklistFormScreen(vehiculo: _vehiculo!),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Resumen', icon: Icon(Icons.info_outline)),
            const Tab(text: 'Taller', icon: Icon(Icons.build_circle_outlined)),
            const Tab(text: 'Repuestos', icon: Icon(Icons.settings_outlined)),
            if (_isMachinery)
              const Tab(text: 'Horómetro', icon: Icon(Icons.timer_outlined)),
            const Tab(
              text: 'Combustible',
              icon: Icon(Icons.local_gas_station_outlined),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vehiculo == null
          ? const Center(child: Text('Error al cargar la Hoja de Vida'))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildWorkshopTab(),
                _buildPartsTab(),
                if (_isMachinery)
                  HourMeterHistoryScreen(
                    vehiculoId: widget.vehiculoId,
                    placa: widget.placa,
                  ),
                FuelHistoryScreen(
                  vehiculoId: widget.vehiculoId,
                  placa: widget.placa,
                  showNavMenu: false, // No mostrar menú en hoja de vida
                ),
              ],
            ),
    );
  }

  void _showEditDialog() {
    if (_vehiculo == null) return;

    final kmController = TextEditingController(
      text: _vehiculo!.kilometrajeProximoMantenimiento?.toString() ?? '',
    );
    final hoursController = TextEditingController(
      text: _vehiculo!.horometroProximoMantenimiento?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogCntx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          'ACTUALIZAR METAS',
          style: GoogleFonts.oswald(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSectionTitle('Mantenimiento Preventivo'),
              const SizedBox(height: 10),
              _buildNumberField('Próx. Mantenimiento (Km)', kmController),
              if (_isMachinery) ...[
                const SizedBox(height: 15),
                _buildNumberField(
                  'Próx. Mantenimiento (Horas)',
                  hoursController,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCntx),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = <String, dynamic>{};
              if (kmController.text.isNotEmpty) {
                data['kilometraje_proximo_mantenimiento'] = kmController.text;
              }
              if (hoursController.text.isNotEmpty) {
                data['horometro_proximo_mantenimiento'] = hoursController.text;
              }

              Navigator.pop(dialogCntx); // Cerrar diálogo primero

              if (data.isNotEmpty) {
                final success = await context
                    .read<FleetProvider>()
                    .updateVehicle(widget.vehiculoId, data);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Metas actualizadas correctamente'
                            : 'Error al actualizar metas',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryYellow,
              foregroundColor: Colors.black,
            ),
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textGray),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.surfaceDark2),
        ),
      ),
    );
  }


  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textGray,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVehicleHeader(),
          const SizedBox(height: 20),
          _buildQuickStats(),
          const SizedBox(height: 20),
          _buildPersonalSection(),
          const SizedBox(height: 20),
          _buildMaintenanceSection(),
          const SizedBox(height: 20),
          _buildDocumentationSection(),
        ],
      ),
    );
  }

  Widget _buildVehicleHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryYellow.withValues(alpha: 0.2),
            AppTheme.surfaceDark2,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryYellow.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _isMachinery ? Icons.construction : Icons.directions_car,
                  color: AppTheme.primaryYellow,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _vehiculo!.placa,
                      style: GoogleFonts.oswald(
                        color: AppTheme.primaryYellow,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_vehiculo!.marca} ${_vehiculo!.modelo}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark2,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _vehiculo!.tipo.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primaryYellow,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  Icons.speed_outlined,
                  'Kilometraje',
                  '${_vehiculo!.kilometrajeActual.toStringAsFixed(0)} km',
                  Colors.blue,
                ),
              ),
              if (_isMachinery) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    Icons.timer_outlined,
                    'Horómetro',
                    '${_vehiculo!.horometroActual.toStringAsFixed(0)} h',
                    Colors.orange,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.oswald(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textGray,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final totalOrdenes = _vehiculo?.ordenesTrabajo?.length ?? 0;
    final totalRepuestos = _calculateTotalParts();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceDark2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ESTADÍSTICAS RÁPIDAS',
            style: TextStyle(
              color: AppTheme.textGray,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickStatCard(
                  Icons.assignment_outlined,
                  'Órdenes',
                  totalOrdenes.toString(),
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStatCard(
                  Icons.inventory_2_outlined,
                  'Repuestos',
                  totalRepuestos.toString(),
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStatCard(
                  Icons.history_outlined,
                  'Combustible',
                  '-',
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.oswald(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textGray,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceDark2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PERSONAL ASIGNADO',
            style: TextStyle(
              color: AppTheme.textGray,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildPersonalCard(
            'Operador / Conductor',
            _vehiculo?.operadorAsignado?.nombreCompleto,
            Icons.person_outline,
            Colors.blue,
            () =>
                _showAssignmentDialog('operador', _vehiculo?.operadorAsignado),
          ),
          const SizedBox(height: 10),
          _buildPersonalCard(
            'Mecánico Responsable',
            _vehiculo?.mecanicoAsignado?.nombreCompleto,
            Icons.engineering_outlined,
            Colors.orange,
            () =>
                _showAssignmentDialog('mecanico', _vehiculo?.mecanicoAsignado),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalCard(
    String role,
    String? name,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role,
                    style: const TextStyle(
                      color: AppTheme.textGray,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name ?? 'Sin asignar',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit,
              color: color,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceDark2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MANTENIMIENTO PREVENTIVO',
            style: TextStyle(
              color: AppTheme.textGray,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildMaintenanceIndicator(
            'Kilometraje',
            _vehiculo?.kilometrajeActual ?? 0,
            _vehiculo?.kilometrajeProximoMantenimiento,
            'Km',
            Icons.speed_outlined,
            Colors.blue,
          ),
          if (_isMachinery) ...[
            const SizedBox(height: 10),
            _buildMaintenanceIndicator(
              'Horómetro',
              _vehiculo?.horometroActual ?? 0,
              _vehiculo?.horometroProximoMantenimiento,
              'Horas',
              Icons.timer_outlined,
              Colors.orange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMaintenanceIndicator(
    String type,
    double current,
    double? target,
    String unit,
    IconData icon,
    Color color,
  ) {
    if (target == null || target == 0) {
      return _buildMaintenanceAlert(
        type,
        'Meta no definida',
        Colors.grey,
        Icons.help_outline,
      );
    }

    final diff = target - current;
    final percentage = ((current / target) * 100).clamp(0, 100);

    Color statusColor;
    IconData statusIcon;

    if (diff <= 0) {
      statusColor = Colors.red;
      statusIcon = Icons.warning;
    } else if (diff <= (unit == 'Km' ? 500 : 50)) {
      statusColor = Colors.orange;
      statusIcon = Icons.access_time;
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      style: const TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$current / $target $unit',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(statusIcon, color: statusColor, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: statusColor.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentage.toStringAsFixed(0)}% completado',
                style: const TextStyle(
                  color: AppTheme.textGray,
                  fontSize: 9,
                ),
              ),
              Text(
                diff <= 0
                    ? 'Vencido por ${diff.abs().toStringAsFixed(0)} $unit'
                    : 'Faltan ${diff.toStringAsFixed(0)} $unit',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceAlert(
    String type,
    String message,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceDark2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DOCUMENTACIÓN REGULATORIA',
            style: TextStyle(
              color: AppTheme.textGray,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildDocumentCard('SOAT', _vehiculo?.fechaVencimientoSoat),
          const SizedBox(height: 10),
          _buildDocumentCard(
            'Tecnomecánica',
            _vehiculo?.fechaVencimientoTecnomecanica,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(String title, DateTime? expirationDate) {
    if (expirationDate == null) {
      return _buildDocumentItem(
        title,
        'No registrada',
        Colors.grey,
        Icons.help_outline,
      );
    }

    final daysLeft = expirationDate.difference(DateTime.now()).inDays;
    Color color;
    String status;
    IconData icon;

    if (daysLeft < 0) {
      color = Colors.red;
      status = 'Vencido hace ${daysLeft.abs()} días';
      icon = Icons.warning;
    } else if (daysLeft <= 30) {
      color = Colors.orange;
      status = 'Vence en $daysLeft días';
      icon = Icons.access_time;
    } else {
      color = Colors.green;
      status = 'Vigente - ${DateFormat('dd/MM/yyyy').format(expirationDate)}';
      icon = Icons.check_circle_outline;
    }

    return _buildDocumentItem(title, status, color, icon);
  }

  Widget _buildDocumentItem(
    String title,
    String status,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
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

  Widget _buildWorkshopTab() {
    final ordenes = _vehiculo?.ordenesTrabajo ?? [];
    if (ordenes.isEmpty) {
      return const Center(child: Text('No hay historial de taller'));
    }

    return ListView.builder(
      itemCount: ordenes.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final ot = ordenes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text('OT #${ot.id} - ${ot.descripcion}'),
            subtitle: Text(ot.fechaInicioString.split(' ')[0]), // Solo la fecha
            trailing: _buildStatusChip(ot.estado),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String estado) {
    Color color = Colors.grey;
    if (estado == 'Completada') color = Colors.green;
    if (estado == 'En Progreso') color = Colors.blue;
    if (estado == 'Pendiente') color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPartsTab() {
    final allMovements = <dynamic>[];

    // Movimientos directos
    if (_vehiculo?.movimientosDirectos != null) {
      allMovements.addAll(_vehiculo!.movimientosDirectos!);
    }

    // Movimientos de OTs
    _vehiculo?.ordenesTrabajo?.forEach((ot) {
      if (ot.movimientosInventario != null) {
        allMovements.addAll(ot.movimientosInventario!);
      }
    });

    // Filtrar movimientos de combustible
    final partsMovements = allMovements.where((m) {
      final motivo = (m.motivo ?? '').toLowerCase();
      final categoriaNombre = (m.producto?.categoria?.nombre ?? '').toLowerCase();
      final categoriaTipo = (m.producto?.categoria?.tipo ?? '').toLowerCase();
      final productoNombre = (m.producto?.nombre ?? '').toLowerCase();

      // Excluir si es combustible
      if (motivo.contains('combustible')) return false;
      if (categoriaNombre.contains('combustible')) return false;
      if (categoriaTipo.contains('combustible')) return false;
      if (productoNombre.contains('combustible')) return false;
      if (productoNombre.contains('acpm')) return false;
      if (productoNombre.contains('gasolina')) return false;

      return true;
    }).toList();

    if (partsMovements.isEmpty) {
      return const Center(child: Text('No hay repuestos registrados'));
    }

    return ListView.builder(
      itemCount: partsMovements.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final m = partsMovements[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.settings_suggest, color: Colors.blueGrey),
            title: Text(m.producto?.nombre ?? 'Repuesto'),
            subtitle: Text(
              '${m.motivo} • ${DateFormat('dd/MM/yyyy').format(m.createdAt)}',
            ),
            trailing: Text(
              '-${m.cantidad}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }

  int _calculateTotalParts() {
    int total = _vehiculo?.movimientosDirectos?.length ?? 0;
    _vehiculo?.ordenesTrabajo?.forEach((ot) {
      total += ot.movimientosInventario?.length ?? 0;
    });
    return total;
  }

  void _showAssignmentDialog(String type, Empleado? currentAssignee) {
    if (_vehiculo == null) return;

    final employeeProvider = context.read<EmployeeProvider>();
    if (employeeProvider.employees.isEmpty) {
      employeeProvider.loadEmployees();
    }

    // Buscar objeto coincidente en la lista para el Dropdown
    Empleado? selectedEmployee;
    try {
      if (currentAssignee != null) {
        selectedEmployee = employeeProvider.employees.firstWhere(
          (e) => e.id == currentAssignee.id,
        );
      }
    } catch (_) {}

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              title: Text(
                'ASIGNAR ${type.toUpperCase()}',
                style: GoogleFonts.oswald(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (employeeProvider.isLoading)
                      const LinearProgressIndicator()
                    else
                      DropdownButtonFormField<Empleado>(
                        isExpanded: true,
                        dropdownColor: AppTheme.surfaceDark,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Seleccionar Empleado',
                          labelStyle: TextStyle(color: AppTheme.textGray),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.surfaceDark2,
                            ),
                          ),
                        ),
                        key: ValueKey(selectedEmployee),
                        initialValue: selectedEmployee,
                        items: employeeProvider.employees.map((e) {
                          return DropdownMenuItem(
                            value: e,
                            child: Text(e.nombreCompleto),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => selectedEmployee = val);
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'CANCELAR',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedEmployee == null) return;

                    Navigator.pop(dialogContext);

                    final data = <String, dynamic>{
                      type == 'operador'
                              ? 'operador_asignado_id'
                              : 'mecanico_asignado_id':
                          selectedEmployee!.id,
                    };

                    final success = await context
                        .read<FleetProvider>()
                        .updateVehicle(widget.vehiculoId, data);

                    if (context.mounted) {
                      if (success) {
                        _loadData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Asignación actualizada'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error al actualizar'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('GUARDAR'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
