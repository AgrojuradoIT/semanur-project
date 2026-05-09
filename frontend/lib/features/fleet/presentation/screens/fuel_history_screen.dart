import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/semanur_scaffold.dart';
import 'package:provider/provider.dart';
import '../providers/fuel_provider.dart';
import '../../data/models/fuel_record_model.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'add_fuel_screen.dart';

class FuelHistoryScreen extends StatefulWidget {
  final int vehiculoId;
  final String placa;
  final bool showNavMenu;

  const FuelHistoryScreen({
    super.key,
    required this.vehiculoId,
    required this.placa,
    this.showNavMenu = true,
  });

  @override
  State<FuelHistoryScreen> createState() => _FuelHistoryScreenState();
}

class _FuelHistoryScreenState extends State<FuelHistoryScreen> {
  String _tipoFiltro = 'todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FuelProvider>().fetchRegistros(
        vehiculoId: widget.vehiculoId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SemanurScaffold(
      showBottomNav: widget.showNavMenu,
      currentNav: SemanurNavItem.fuel,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(''),
        toolbarHeight: 32,
      ),
      body: Consumer<FuelProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.registros.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.registros.isEmpty) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          if (provider.registros.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_gas_station_outlined,
                    size: 80,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay registros de combustible',
                    style: GoogleFonts.oswald(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'para este vehículo',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          final registrosFiltrados = _tipoFiltro == 'todos'
              ? provider.registros
              : provider.registros
                  .where(
                    (r) =>
                        r.tipoCombustible.toLowerCase() == _tipoFiltro,
                  )
                  .toList();

          final double totalGalones = registrosFiltrados.fold(
            0.0,
            (sum, r) => sum + r.cantidadGalones,
          );

          if (registrosFiltrados.isEmpty) {
            return Column(
              children: [
                _buildFilterRow(),
                const SizedBox(height: 8),
                _buildSummaryCard(totalGalones, registrosFiltrados.length),
                const Expanded(
                  child: Center(
                    child: Text('No hay registros para este filtro'),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              _buildFilterRow(),
              const SizedBox(height: 8),
              _buildSummaryCard(totalGalones, registrosFiltrados.length),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: registrosFiltrados.length,
                  itemBuilder: (context, index) {
                    final RegistroCombustible reg =
                        registrosFiltrados[index];
                    final String tipoLower =
                        reg.tipoCombustible.toLowerCase();
                    final bool isAcpm = tipoLower == 'acpm';

                    return _buildFuelCard(reg, isAcpm);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddFuelScreen(
                vehiculoId: widget.vehiculoId,
                placa: widget.placa,
              ),
            ),
          );
        },
        backgroundColor: AppTheme.primaryYellow,
        foregroundColor: Colors.black,
        label: const Text(
          'REGISTRAR',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFuelCard(RegistroCombustible reg, bool isAcpm) {
    final Color accentColor = isAcpm ? Colors.orange : AppTheme.primaryYellow;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetailDialog(reg, isAcpm),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.local_gas_station,
                                  color: accentColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reg.tipoCombustible.toUpperCase(),
                                      style: GoogleFonts.oswald(
                                        color: accentColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('dd/MM/yyyy • HH:mm')
                                          .format(reg.fecha),
                                      style: const TextStyle(
                                        color: AppTheme.textGray,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _buildBadge(
                          '${reg.cantidadGalones.toStringAsFixed(1)} GAL',
                          Colors.green,
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: AppTheme.textGray,
                            size: 20,
                          ),
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'detail',
                              child: Text('Ver detalle'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Eliminar'),
                            ),
                          ],
                          onSelected: (val) {
                            if (val == 'delete') {
                              _confirmDelete(reg);
                            } else if (val == 'detail') {
                              _showDetailDialog(reg, isAcpm);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: AppTheme.surfaceDark2),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (reg.horometroActual != null) ...[
                      _buildInfoChip(
                        Icons.timer_outlined,
                        '${reg.horometroActual!.toStringAsFixed(0)}h',
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (reg.kilometrajeActual != null) ...[
                      _buildInfoChip(
                        Icons.speed_outlined,
                        '${reg.kilometrajeActual!.toStringAsFixed(0)}km',
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (reg.estacionServicio != null &&
                        reg.estacionServicio!.isNotEmpty) ...[
                      Expanded(
                        child: _buildInfoChip(
                          Icons.location_on_outlined,
                          reg.estacionServicio!,
                          isLocation: true,
                        ),
                      ),
                    ],
                  ],
                ),
                if (reg.notas != null && reg.notas!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.note_outlined,
                          color: AppTheme.textGray,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reg.notas!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String value, {
    bool isLocation = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark2,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppTheme.primaryYellow,
            size: isLocation ? 14 : 16,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: isLocation ? TextOverflow.ellipsis : TextOverflow.clip,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double totalGalones, int totalRegistros) {
    final galones = NumberFormat('#,##0.##', 'es_CO');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceDark,
            AppTheme.surfaceDark2,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryYellow.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryYellow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'TOTAL GALONES',
              galones.format(totalGalones),
              Icons.water_drop,
              AppTheme.primaryYellow,
            ),
          ),
          const VerticalDivider(
            color: AppTheme.surfaceDark,
            width: 24,
          ),
          Expanded(
            child: _buildSummaryItem(
              'REGISTROS',
              totalRegistros.toString(),
              Icons.receipt_long,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
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
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        children: [
          const Text(
            'Filtrar:',
            style: TextStyle(
              color: AppTheme.textGray,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todos', 'todos'),
                  const SizedBox(width: 4),
                  _buildFilterChip('Gasolina', 'gasolina'),
                  const SizedBox(width: 4),
                  _buildFilterChip('ACPM', 'acpm'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final bool selected = _tipoFiltro == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
      selected: selected,
      onSelected: (_) => setState(() => _tipoFiltro = value),
      selectedColor: AppTheme.primaryYellow,
      backgroundColor: AppTheme.surfaceDark2,
      labelStyle: TextStyle(
        color: selected ? Colors.black : Colors.white,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  void _showDetailDialog(RegistroCombustible reg, bool isAcpm) {
    final Color accentColor = isAcpm ? Colors.orange : AppTheme.primaryYellow;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: accentColor.withValues(alpha: 0.3),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.local_gas_station,
                color: accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DETALLE DEL REGISTRO',
                    style: GoogleFonts.oswald(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy • HH:mm').format(reg.fecha),
                    style: const TextStyle(
                      color: AppTheme.textGray,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                Icons.water_drop,
                'Cantidad',
                '${reg.cantidadGalones.toStringAsFixed(2)} galones',
                accentColor,
              ),
              const SizedBox(height: 12),
              if (reg.horometroActual != null)
                _buildDetailRow(
                  Icons.timer_outlined,
                  'Horómetro',
                  '${reg.horometroActual!.toStringAsFixed(0)} horas',
                  accentColor,
                ),
              if (reg.kilometrajeActual != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.speed_outlined,
                  'Kilometraje',
                  '${reg.kilometrajeActual!.toStringAsFixed(0)} km',
                  accentColor,
                ),
              ],
              if (reg.estacionServicio != null &&
                  reg.estacionServicio!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.location_on_outlined,
                  'Estación de Servicio',
                  reg.estacionServicio!,
                  accentColor,
                ),
              ],
              if (reg.usuarioNombre != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.person_outline,
                  'Usuario',
                  reg.usuarioNombre!,
                  accentColor,
                ),
              ],
              if (reg.notas != null && reg.notas!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'NOTAS',
                  style: TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    reg.notas!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'CERRAR',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDelete(reg);
            },
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color accentColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: accentColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textGray,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDelete(RegistroCombustible reg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade400),
            const SizedBox(width: 12),
            const Text(
              'Eliminar Registro',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar el registro del ${DateFormat('dd/MM/yyyy').format(reg.fecha)} (${reg.cantidadGalones} gal)?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'CANCELAR',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<FuelProvider>().deleteRegistro(
                    reg.id,
                    vehiculoId: widget.vehiculoId,
                  );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Registro eliminado'
                          : 'Error al eliminar',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
  }
}
