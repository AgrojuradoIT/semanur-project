import 'package:flutter/material.dart';
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
    return Scaffold(
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
                ),
              ],
            ),
    );
  }

  void _showEditDialog() {
    if (_vehiculo == null) return;

    final soatController = TextEditingController(
      text: _vehiculo!.fechaVencimientoSoat != null
          ? DateFormat('yyyy-MM-dd').format(_vehiculo!.fechaVencimientoSoat!)
          : '',
    );
    final tecnoController = TextEditingController(
      text: _vehiculo!.fechaVencimientoTecnomecanica != null
          ? DateFormat(
              'yyyy-MM-dd',
            ).format(_vehiculo!.fechaVencimientoTecnomecanica!)
          : '',
    );
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
          'ACTUALIZAR METAS Y FECHAS',
          style: GoogleFonts.oswald(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSectionTitle('Documentación'),
              const SizedBox(height: 10),
              _buildDatePicker(dialogCntx, 'Vencimiento SOAT', soatController),
              const SizedBox(height: 15),
              _buildDatePicker(
                dialogCntx,
                'Vencimiento Tecnomecánica',
                tecnoController,
              ),
              const SizedBox(height: 20),
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
              if (soatController.text.isNotEmpty) {
                data['fecha_vencimiento_soat'] = soatController.text;
              }
              if (tecnoController.text.isNotEmpty) {
                data['fecha_vencimiento_tecnomecanica'] = tecnoController.text;
              }
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
                            ? 'Fechas actualizadas correctamente'
                            : 'Error al actualizar fechas',
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

  Widget _buildDatePicker(
    BuildContext context,
    String label,
    TextEditingController controller,
  ) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textGray),
        suffixIcon: const Icon(
          Icons.calendar_today,
          color: AppTheme.primaryYellow,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.surfaceDark2),
        ),
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppTheme.primaryYellow,
                  onPrimary: Colors.black,
                  surface: AppTheme.surfaceDark,
                  onSurface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          controller.text = DateFormat('yyyy-MM-dd').format(date);
        }
      },
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 24),
          const Text(
            'INDICADORES CLAVE',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildKpiCard(
                'Órdenes',
                '${_vehiculo?.ordenesTrabajo?.length ?? 0}',
                Icons.assignment,
                Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildKpiCard(
                'Repuestos',
                '${_calculateTotalParts()}',
                Icons.inventory_2,
                Colors.orange,
              ),
            ],
          ),

          // ASIGNACIONES DE PERSONAL
          const SizedBox(height: 24),
          _buildSectionTitle('PERSONAL ASIGNADO'),
          const SizedBox(height: 12),
          _buildAssignmentCard(
            'Operador / Conductor',
            _vehiculo?.operadorAsignado?.nombreCompleto,
            Icons.person,
            () =>
                _showAssignmentDialog('operador', _vehiculo?.operadorAsignado),
          ),
          const SizedBox(height: 12),
          _buildAssignmentCard(
            'Mecánico Responsable',
            _vehiculo?.mecanicoAsignado?.nombreCompleto,
            Icons.engineering,
            () =>
                _showAssignmentDialog('mecanico', _vehiculo?.mecanicoAsignado),
          ),

          // Alertas de Mantenimiento
          const SizedBox(height: 24),
          _buildSectionTitle('MANTENIMIENTO PREVENTIVO'),
          const SizedBox(height: 12),
          _buildMaintenanceCard(
            'Por Kilometraje',
            _vehiculo?.kilometrajeActual ?? 0,
            _vehiculo?.kilometrajeProximoMantenimiento,
            'Km',
          ),
          if (_isMachinery) ...[
            const SizedBox(height: 12),
            _buildMaintenanceCard(
              'Por Horas (Horómetro)',
              _vehiculo?.horometroActual ?? 0,
              _vehiculo?.horometroProximoMantenimiento,
              'Horas',
            ),
          ],

          // Alertas de Documentación
          const SizedBox(height: 24),
          _buildSectionTitle('DOCUMENTACIÓN REGULATORIA'),
          const SizedBox(height: 12),
          _buildExpirationCard('SOAT', _vehiculo?.fechaVencimientoSoat),
          const SizedBox(height: 12),
          _buildExpirationCard(
            'Tecnomecánica',
            _vehiculo?.fechaVencimientoTecnomecanica,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow('Placa', _vehiculo!.placa, isTitle: true),
            const Divider(),
            _buildInfoRow('Tipo', _vehiculo!.tipo),
            _buildInfoRow('Marca', _vehiculo!.marca),
            _buildInfoRow('Modelo', _vehiculo!.modelo),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTitle = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTitle ? FontWeight.bold : FontWeight.normal,
              fontSize: isTitle ? 18 : 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        fontSize: 12,
      ),
    );
  }

  Widget _buildExpirationCard(String title, DateTime? expirationDate) {
    if (expirationDate == null) {
      return _buildAlertCard(
        title,
        'No registrada',
        Colors.grey.shade800,
        Colors.grey,
        Icons.help_outline,
      );
    }

    final daysLeft = expirationDate.difference(DateTime.now()).inDays;
    Color color;
    IconData icon;
    String status;

    if (daysLeft < 0) {
      color = Colors.red;
      icon = Icons.warning;
      status = 'VENCIDO hace ${daysLeft.abs()} días';
    } else if (daysLeft <= 30) {
      color = Colors.orange;
      icon = Icons.access_time;
      status = 'Vence en $daysLeft días';
    } else {
      color = Colors.green;
      icon = Icons.check_circle_outline;
      status =
          'Vigente (Vence: ${DateFormat('dd/MM/yyyy').format(expirationDate)})';
    }

    return _buildAlertCard(
      title,
      status,
      color.withValues(alpha: 0.1),
      color,
      icon,
    );
  }

  Widget _buildMaintenanceCard(
    String title,
    double current,
    double? target,
    String unit,
  ) {
    if (target == null || target == 0) {
      return _buildAlertCard(
        title,
        'Meta no definida',
        Colors.grey.shade800,
        Colors.grey,
        Icons.settings_suggest,
      );
    }

    final diff = target - current;
    Color color;
    IconData icon;
    String status;

    if (diff <= 0) {
      color = Colors.red;
      icon = Icons.warning;
      status =
          'REQ. MANTENIMIENTO (Pasado por ${diff.abs().toStringAsFixed(0)} $unit)';
    } else if (diff <= (unit == 'Km' ? 500 : 50)) {
      color = Colors.orange;
      icon = Icons.access_time;
      status = 'Próximo (Faltan ${diff.toStringAsFixed(0)} $unit)';
    } else {
      color = Colors.green;
      icon = Icons.check_circle_outline;
      status = 'Operativo (Faltan ${diff.toStringAsFixed(0)} $unit)';
    }

    return _buildAlertCard(
      title,
      status,
      color.withValues(alpha: 0.1),
      color,
      icon,
    );
  }

  Widget _buildAlertCard(
    String title,
    String status,
    Color bgColor,
    Color accentColor,
    IconData icon,
  ) {
    bool isCritical = accentColor == Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCritical ? Colors.red.withValues(alpha: 0.15) : bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: isCritical ? 0.8 : 0.5),
          width: isCritical ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: isCritical ? 32 : 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.oswald(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isCritical)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ALERTA',
                          style: GoogleFonts.oswald(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  status,
                  style: TextStyle(
                    color: isCritical ? Colors.white : accentColor,
                    fontWeight: isCritical ? FontWeight.bold : FontWeight.w600,
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

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ],
        ),
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
            subtitle: Text(DateFormat('dd/MM/yyyy').format(ot.fechaInicio)),
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

    if (allMovements.isEmpty) {
      return const Center(child: Text('No hay repuestos registrados'));
    }

    return ListView.builder(
      itemCount: allMovements.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final m = allMovements[index];
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

  Widget _buildAssignmentCard(
    String title,
    String? name,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      color: AppTheme.surfaceDark,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.surfaceDark2),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryYellow.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryYellow, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        subtitle: Text(
          name ?? 'Sin asignar',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: Colors.blueAccent),
          onPressed: onTap,
        ),
      ),
    );
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
