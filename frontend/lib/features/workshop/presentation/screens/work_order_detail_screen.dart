import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/features/workshop/data/models/work_order_model.dart';
import 'package:frontend/features/workshop/presentation/providers/workshop_provider.dart';
import 'package:frontend/features/workshop/presentation/providers/session_provider.dart';
import 'package:frontend/features/workshop/data/models/session_model.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/inventory/presentation/screens/add_movement_screen.dart';
import 'package:intl/intl.dart';

class WorkOrderDetailScreen extends StatefulWidget {
  final OrdenTrabajo orden;

  const WorkOrderDetailScreen({super.key, required this.orden});

  @override
  State<WorkOrderDetailScreen> createState() => _WorkOrderDetailScreenState();
}

class _WorkOrderDetailScreenState extends State<WorkOrderDetailScreen> {
  Timer? _timer;
  Duration _currentDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkshopProvider>().fetchOrdenDetalle(widget.orden.id);
      context.read<SessionProvider>().fetchActiveSession().then((_) {
        _startTimerIfNeeded();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimerIfNeeded() {
    final activeSession = context.read<SessionProvider>().activeSession;
    if (activeSession != null &&
        activeSession.ordenTrabajoId == widget.orden.id) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _currentDuration = activeSession.duration;
        });
      });
    } else {
      _timer?.cancel();
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(d.inHours);
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final workshopProvider = context.watch<WorkshopProvider>();
    final sessionProvider = context.watch<SessionProvider>();

    // Usar la orden del provider si existe para tener los datos actualizados (sesiones)
    final orden = workshopProvider.ordenes.firstWhere(
      (o) => o.id == widget.orden.id,
      orElse: () => widget.orden,
    );

    final colorPrioridad = _getPrioridadColor(orden.prioridad);

    final activeSession = sessionProvider.activeSession;
    final bool isSessionHere =
        activeSession != null && activeSession.ordenTrabajoId == orden.id;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        title: Text(
          'DETALLE DE ORDEN #${orden.id}',
          style: GoogleFonts.oswald(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBanner(context, orden),
            if (isSessionHere) _buildActiveSessionBanner(activeSession),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('INFORMACIÓN DEL VEHÍCULO'),
                  _buildInfoCard([
                    _buildInfoRow(
                      'PLACA',
                      orden.vehiculo?.placa ?? 'N/A',
                      isPrimary: true,
                    ),
                    _buildInfoRow('MARCA', orden.vehiculo?.marca ?? 'N/A'),
                    _buildInfoRow('MODELO', orden.vehiculo?.modelo ?? 'N/A'),
                    _buildInfoRow('TIPO', orden.vehiculo?.tipo ?? 'N/A'),
                  ]),
                  const SizedBox(height: 25),
                  _buildSectionTitle('OPERARIO / MECÁNICO'),
                  _buildInfoCard([
                    _buildInfoRow(
                      'ASIGNADO',
                      orden.mecanico?.name ?? 'Sin asignar',
                      isPrimary: true,
                      valueColor: AppTheme.primaryYellow,
                    ),
                  ]),
                  const SizedBox(height: 25),
                  _buildSectionTitle('DETALLES DEL TRABAJO'),
                  _buildInfoCard([
                    _buildInfoRow(
                      'PRIORIDAD',
                      orden.prioridad.toUpperCase(),
                      valueColor: colorPrioridad,
                    ),
                    _buildInfoRow(
                      'FECHA INICIO',
                      DateFormat('dd/MM/yyyy HH:mm').format(orden.fechaInicio),
                    ),
                    const Divider(color: AppTheme.surfaceDark2, height: 30),
                    Text(
                      'DESCRIPCIÓN:',
                      style: GoogleFonts.oswald(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textGray,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.orden.descripcion,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 25),
                  _buildSectionTitle('SESIONES DE TRABAJO'),
                  _buildSessionsHistory(orden),
                  const SizedBox(height: 25),
                  _buildSectionTitle('REPUESTOS Y MATERIALES'),
                  _buildPartsSection(context, orden),
                  const SizedBox(height: 30),
                  _buildActionButtons(
                    context,
                    workshopProvider,
                    sessionProvider,
                    orden,
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSessionBanner(SessionTrabajo session) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      color: Colors.green.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.timer, color: Colors.green, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TIEMPO TRABAJADO EN SESIÓN ACTUAL',
                  style: TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatDuration(_currentDuration),
                  style: GoogleFonts.oswald(
                    color: Colors.green,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _stopSession(session.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('DETENER', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsHistory(OrdenTrabajo orden) {
    final sesiones = orden.sesiones ?? [];
    if (sesiones.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Text(
            'No hay registros de sesiones de trabajo aún.',
            style: TextStyle(color: AppTheme.textGray, fontSize: 13),
          ),
        ),
      );
    }

    // Ordenar sesiones por fecha de inicio descendente
    final sortedSesiones = List<SessionTrabajo>.from(sesiones)
      ..sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));

    return _buildInfoCard([
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedSesiones.length,
        separatorBuilder: (context, index) =>
            const Divider(color: AppTheme.surfaceDark2, height: 20),
        itemBuilder: (context, index) {
          final s = sortedSesiones[index];
          final endStr = s.fechaFin != null
              ? DateFormat('HH:mm').format(s.fechaFin!)
              : 'En curso';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
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
                          Text(
                            s.user?.name.toUpperCase() ?? 'MECÁNICO',
                            style: GoogleFonts.oswald(
                              color: AppTheme.primaryYellow,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${DateFormat('dd/MM/yyyy').format(s.fechaInicio)} | ${DateFormat('HH:mm').format(s.fechaInicio)} - $endStr',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatDuration(s.duration),
                      style: GoogleFonts.oswald(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (s.notas != null && s.notas!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'NOTAS: ${s.notas}',
                        style: const TextStyle(
                          color: AppTheme.textGray,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    ]);
  }

  Widget _buildStatusBanner(BuildContext context, OrdenTrabajo orden) {
    final color = _getEstadoColor(orden.estado);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          bottom: BorderSide(color: color.withValues(alpha: 0.3), width: 2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.pending_actions, color: color, size: 30),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ESTADO ACTUAL',
                style: GoogleFonts.oswald(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textGray,
                  letterSpacing: 1,
                ),
              ),
              Text(
                orden.estado.toUpperCase(),
                style: GoogleFonts.oswald(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.oswald(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryYellow,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.surfaceDark2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isPrimary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textGray,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.oswald(
              color: valueColor ?? Colors.white,
              fontSize: isPrimary ? 16 : 14,
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WorkshopProvider workshopProvider,
    SessionProvider sessionProvider,
    OrdenTrabajo orden,
  ) {
    final String currentStatus = orden.estado.toLowerCase();
    final bool isSessionActiveHere =
        sessionProvider.activeSession?.ordenTrabajoId == orden.id;

    if (currentStatus == 'cerrada' || currentStatus == 'completada') {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (!isSessionActiveHere)
          _buildActionButton(
            'INICIAR SESIÓN DE TRABAJO',
            Icons.play_arrow,
            Colors.green,
            () => _startSession(),
            sessionProvider.isLoading,
          ),
        if (isSessionActiveHere)
          _buildActionButton(
            'DETENER SESIÓN ACTUAL',
            Icons.stop,
            Colors.red,
            () => _stopSession(sessionProvider.activeSession!.id),
            sessionProvider.isLoading,
          ),
        const SizedBox(height: 15),
        if (currentStatus != 'cerrada')
          _buildActionButton(
            'COMPLETAR Y CERRAR ORDEN',
            Icons.check_circle,
            AppTheme.primaryYellow,
            () => _updateStatus(context, orden, 'Cerrada'),
            workshopProvider.isLoading,
            textColor: Colors.black,
          ),
      ],
    );
  }

  Widget _buildPartsSection(BuildContext context, OrdenTrabajo orden) {
    final movimientos = orden.movimientosInventario ?? [];

    if (movimientos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: AppTheme.surfaceDark2,
            style: BorderStyle.none,
          ),
        ),
        child: Column(
          children: [
            const Text(
              'No hay repuestos registrados para esta orden.',
              style: TextStyle(color: AppTheme.textGray, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            _buildAddPartButton(context, orden),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildInfoCard([
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: movimientos.length,
            separatorBuilder: (context, index) =>
                const Divider(color: AppTheme.surfaceDark2, height: 20),
            itemBuilder: (context, index) {
              final m = movimientos[index];
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: AppTheme.primaryYellow,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.producto?.nombre.toUpperCase() ?? 'REPUESTO',
                          style: GoogleFonts.oswald(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'CANTIDAD: ${m.cantidad} ${m.producto?.unidadMedida ?? 'UNID'}',
                          style: const TextStyle(
                            color: AppTheme.textGray,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ]),
        const SizedBox(height: 15),
        _buildAddPartButton(context, orden),
      ],
    );
  }

  Widget _buildAddPartButton(BuildContext context, OrdenTrabajo orden) {
    final status = orden.estado.toLowerCase();
    if (status == 'cerrada' || status == 'completada') {
      return const SizedBox.shrink();
    }
    return _buildMiniButton(
      'ENTREGAR REPUESTO',
      Icons.add_circle_outline,
      () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddMovementScreen(initialOT: orden),
          ),
        );
        if (context.mounted) {
          context.read<WorkshopProvider>().fetchOrdenDetalle(orden.id);
        }
      },
    );
  }

  Widget _buildMiniButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark2,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppTheme.textGray),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
    bool isLoading, {
    Color textColor = Colors.white,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          style: GoogleFonts.oswald(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
          shadowColor: color.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Future<void> _startSession() async {
    final workshopProvider = context.read<WorkshopProvider>();
    final sessionProvider = context.read<SessionProvider>();

    final success = await sessionProvider.startSession(widget.orden.id);
    if (!mounted) return;

    if (success) {
      _startTimerIfNeeded();
      // Refrescar OT para traer sesiones vinculadas (historial)
      final updatedOrden = await workshopProvider.fetchOrdenDetalle(
        widget.orden.id,
      );
      if (!mounted) return;

      if (updatedOrden != null && updatedOrden.estado != 'En Progreso') {
        _updateStatus(context, updatedOrden, 'En Progreso', closeDetail: false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sessionProvider.error ?? 'Error al iniciar sesión'),
        ),
      );
    }
  }

  Future<void> _stopSession(int sessionId) async {
    final TextEditingController notesController = TextEditingController();

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          'FINALIZAR SESIÓN',
          style: GoogleFonts.oswald(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Deseas agregar notas sobre el trabajo realizado?',
              style: TextStyle(color: AppTheme.textGray, fontSize: 13),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: notesController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ej: Se cambió el aceite y filtros...',
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                filled: true,
                fillColor: AppTheme.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryYellow,
              foregroundColor: Colors.black,
            ),
            child: const Text(
              'FINALIZAR',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final sessionProvider = context.read<SessionProvider>();
    final success = await sessionProvider.stopSession(
      sessionId,
      notas: notesController.text,
    );
    if (!mounted) return;

    if (success) {
      _timer?.cancel();
      context.read<WorkshopProvider>().fetchOrdenDetalle(widget.orden.id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sesión finalizada')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sessionProvider.error ?? 'Error al detener sesión'),
        ),
      );
    }
  }

  void _updateStatus(
    BuildContext context,
    OrdenTrabajo orden,
    String nuevoEstado, {
    bool closeDetail = true,
  }) async {
    final provider = context.read<WorkshopProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await provider.actualizarEstado(orden.id, nuevoEstado);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'ORDEN #${orden.id} ACTUALIZADA A $nuevoEstado',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _getEstadoColor(nuevoEstado),
      ),
    );
    if (closeDetail) navigator.pop();
  }

  Color _getPrioridadColor(String prioridad) {
    switch (prioridad.toLowerCase()) {
      case 'alta':
        return Colors.red;
      case 'media':
        return AppTheme.primaryYellow;
      case 'baja':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'abierta':
      case 'pendiente':
        return Colors.blue;
      case 'en progreso':
        return Colors.orange;
      case 'cerrada':
      case 'completada':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
